import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'main.dart' show ReminderService;
import 'web_settings.dart';

class WebHome extends StatefulWidget {
  const WebHome({super.key});
  @override
  State<WebHome> createState() => _WebHomeState();
}

class _WebHomeState extends State<WebHome> with WidgetsBindingObserver {
  WebViewController? controller;
  String? error;
  Map<String, dynamic>? pending;
  bool saving = false, hidden = false, ready = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(load());
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      WebSettings settings = WebSettings.defaults();
      final saved = prefs.getString('still.web.settings');
      if (saved != null) settings = WebSettings(jsonDecode(saved));
      var html = await rootBundle.loadString('assets/web/index.html');
      final bridge = await rootBundle.loadString('assets/web/native_bridge.js');
      html = html.replaceFirst('<script src="native_bridge.js"></script>',
          '<script>$bridge</script>');
      html = html.replaceFirst('/*STILL_NATIVE_BOOT*/', '''
    const boot=${jsonEncode(settings.values)};
    for(const [id,value] of Object.entries({reminders:boot.enabled,'home-reminders':boot.enabled,sound:boot.sound,vibrate:boot.vibration,'start-time':boot.start,'end-time':boot.end,rhythm:boot.rhythm,rotation:boot.rotation,instrument:boot.instrument})){
     const element=document.getElementById(id);if(typeof value==='boolean')element.checked=value;else element.value=String(value);
    }
    try{localStorage.setItem('still.instrument',boot.instrument);localStorage.setItem('still.rotation',String(boot.rotation));}catch(_){}
   ''');
      final view = WebViewController();
      await view.setJavaScriptMode(JavaScriptMode.unrestricted);
      await view.setBackgroundColor(const Color(0xFF050706));
      await view.enableZoom(false);
      await view.addJavaScriptChannel('StillNative',
          onMessageReceived: (message) {
        try {
          final data = jsonDecode(message.message) as Map<String, dynamic>;
          WebSettings(Map<String, dynamic>.from(data['settings']));
          if (data['id'] is! int) return;
          pending = data;
          unawaited(drain());
        } catch (_) {
          unawaited(report(0, 'Invalid settings. Please reopen STILL.'));
        }
      });
      await view.setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) => request.url == 'about:blank'
            ? NavigationDecision.navigate
            : NavigationDecision.prevent,
        onPageFinished: (_) {
          ready = true;
          unawaited(view.runJavaScript('window.stillNativeLifecycle($hidden)'));
        },
        onWebResourceError: (failure) {
          if (failure.isForMainFrame == true && mounted)
            setState(() =>
                error = 'Unable to open STILL. Close and reopen the app.');
        },
      ));
      if (!mounted) return;
      setState(() => controller = view);
      await view.loadHtmlString(html);
    } catch (_) {
      if (mounted)
        setState(
            () => error = 'Unable to load STILL. Close and reopen the app.');
    }
  }

  // Serialize schedules and coalesce rapid changes so OFF is applied last.
  Future<void> drain() async {
    if (saving) return;
    saving = true;
    try {
      while (pending != null) {
        final request = pending!;
        pending = null;
        final config =
            WebSettings(Map<String, dynamic>.from(request['settings']));
        final s = config.values;
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('still.web.settings', jsonEncode(s));
          await ReminderService.instance.initialize().timeout(const Duration(seconds: 10));
          if (s['enabled']) await ReminderService.instance.requestPermissions();
          await ReminderService.instance.reschedule(
              enabled: s['enabled'],
              sound: s['sound'],
              vibration: s['vibration'],
              startMinute: config.startMinute,
              endMinute: config.endMinute,
              averageMinutes: s['rhythm'],
              rotationDays: s['rotation'],
              seed: 7182,
              fixedInstrument: config.fixedInstrument);
          final until = ReminderService.instance.scheduledUntil;
          final message = !s['enabled']
              ? 'Reminders are off.'
              : until == null
                  ? 'No reminders in this window. Try a longer time window.'
                  : 'Reminders scheduled until ${until.day}/${until.month} ${until.hour.toString().padLeft(2, '0')}:${until.minute.toString().padLeft(2, '0')}. Reopen STILL before then to renew them.';
          await report(request['id'], message);
        } catch (_) {
          await report(request['id'],
              'Reminders not confirmed. Check Android notification permissions, then tap Renew reminders.');
        }
      }
    } finally {
      saving = false;
    }
  }

  Future<void> report(int id, String message) async {
    if (!mounted || controller == null) return;
    await controller!.runJavaScript(
        'window.stillNativeResult?.($id,${jsonEncode(message)})');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    hidden = state != AppLifecycleState.resumed;
    if (ready)
      unawaited(
          controller!.runJavaScript('window.stillNativeLifecycle($hidden)'));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final handled = ready
            ? await controller!
                .runJavaScriptReturningResult('window.stillNativeBack()')
            : false;
        if (handled != true) await SystemNavigator.pop();
      },
      child: Scaffold(
          body: SafeArea(
              child: error != null
                  ? Center(
                      child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(error!)))
                  : controller == null
                      ? const Center(child: CircularProgressIndicator())
                      : WebViewWidget(controller: controller!))));
}
