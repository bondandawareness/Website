import 'web_home.dart';
import 'dart:async';
import 'schedule.dart';
import 'spiral_shape.dart';

import 'cinematic_spiral.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

bool timezoneAvailable = true;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  try {
    final name = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(name));
  } catch (_) {
    timezoneAvailable = false;
  }
  try {
    await ReminderService.instance.initialize().timeout(const Duration(seconds: 10));
  } catch (_) {
    // The home stays usable; the bridge reports errors and allows a retry.
  }
  runApp(const StillApp());
}

const soundNames = [
  'Tibetan bowl',
  'Soft gong',
  'Triangle',
  'Temple bell',
  'Wind chimes',
  'Crystal bowl'
];
const soundFiles = [
  'bowl',
  'gong',
  'triangle',
  'temple_bell',
  'chimes',
  'crystal'
];

class ReminderService {
  ReminderService._();
  static final instance = ReminderService._();
  final plugin = FlutterLocalNotificationsPlugin();
  static const int baseId = 4000;
  DateTime? scheduledUntil;
  bool _nativeTimedOut = false;
  bool _initialized = false;
  Future<T> _native<T>(Future<T> Function() operation,
      {Duration timeout = const Duration(seconds: 10)}) async {
    if (_nativeTimedOut) {
      throw StateError(
          'Android did not respond. Close and reopen STILL before retrying.');
    }
    try {
      return await operation().timeout(timeout);
    } on TimeoutException {
      // A timeout does not cancel a platform call. Do not start another batch
      // while an old native request could still finish.
      _nativeTimedOut = true;
      scheduledUntil = null;
      rethrow;
    }
  }

  Future<void> initialize() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false);
    await plugin
        .initialize(const InitializationSettings(android: android, iOS: ios));
    _initialized = true;
  }

  Future<void> requestPermissions() async {
    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await _native(
          () => android.requestNotificationsPermission(),
          timeout: const Duration(seconds: 30));
      if (granted == false)
        throw StateError('Allow notifications in Android settings for STILL.');
    }
    final ios = plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await _native(
          () => ios.requestPermissions(alert: true, sound: true, badge: false),
          timeout: const Duration(seconds: 30));
      if (granted == false)
        throw StateError('Allow notifications in settings for STILL.');
    }
  }

  Future<void> reschedule(
      {required bool enabled,
      required bool sound,
      required bool vibration,
      required int startMinute,
      required int endMinute,
      required int averageMinutes,
      required int rotationDays,
      required int seed,
      int? fixedInstrument}) async {
    final watch = Stopwatch()..start();
    // STILL owns all of its notifications; one call replaces 64 round trips.
    await _native(() => plugin.cancelAll());
    scheduledUntil = null;
    if (!enabled) return;
    if (!timezoneAvailable) throw StateError('Local timezone unavailable');
    final now = tz.TZDateTime.now(tz.local);

    final scheduled = <tz.TZDateTime>[];
    // Finite prototype queue: the screen shows its expiry.
    for (var day = 0; day < 5; day++) {
      final date = tz.TZDateTime(tz.local, now.year, now.month, now.day + day);
      final random = DailyRandom(date, seed);
      var cursor = tz.TZDateTime(tz.local, date.year, date.month, date.day,
          startMinute ~/ 60, startMinute % 60);
      final end = tz.TZDateTime(tz.local, date.year, date.month, date.day,
          endMinute ~/ 60, endMinute % 60);
      while (cursor.isBefore(end)) {
        cursor = cursor.add(Duration(
            minutes: math.max(10, averageMinutes - 10) + random.nextInt(21)));
        if (cursor.isAfter(now) && cursor.isBefore(end)) scheduled.add(cursor);
      }
    }
    // iOS retains only the nearest 64 scheduled notifications.
    for (var i = 0; i < math.min(64, scheduled.length); i++) {
      final instrument = fixedInstrument ?? soundIndexForDay(scheduled[i], 0, rotationDays);
      if (watch.elapsed > const Duration(seconds: 45)) {
        scheduledUntil = null;
        throw TimeoutException('Schedule incomplete. Please retry.');
      }
      await _native(() => plugin.zonedSchedule(
            baseId + i,
            'STILL · ${soundNames[instrument]}',
            'A gentle return to presence. Feel your body. Take one breath.',
            scheduled[i],
            NotificationDetails(
              android: AndroidNotificationDetails(
                'still_final_v4_${sound ? soundFiles[instrument] : 'silent'}_${vibration ? 'vibrate' : 'quiet'}',
                'Presence · ${sound ? soundNames[instrument] : 'Silent'} · ${vibration ? 'vibration' : 'no vibration'}',
                channelDescription: 'Gentle mindful pauses throughout the day',
                importance: Importance.defaultImportance,
                priority: Priority.defaultPriority,
                sound: sound
                    ? RawResourceAndroidNotificationSound(
                        'still_final_${soundFiles[instrument]}')
                    : null,
                playSound: sound,
                enableVibration: vibration,
              ),
              iOS: DarwinNotificationDetails(
                  presentSound: sound, presentAlert: true),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          ));
    }
    if (scheduled.isNotEmpty)
      scheduledUntil = scheduled[math.min(64, scheduled.length) - 1];
  }
}

class StillApp extends StatelessWidget {
  const StillApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'STILL',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF050706),
            colorScheme: ColorScheme.fromSeed(
                    seedColor: const Color(0xFF52764A),
                    brightness: Brightness.dark)
                .copyWith(
                    primary: const Color(0xFF94B486),
                    onPrimary: Colors.white,
                    surface: const Color(0xFF111710))),
        home: const WebHome(),
      );
}

class StillHome extends StatefulWidget {
  const StillHome(
      {super.key, this.settingsLoader, this.initialSettings = false});
  final bool initialSettings;
  final Future<SharedPreferences> Function()? settingsLoader;
  @override
  State<StillHome> createState() => _StillHomeState();
}

class _StillHomeState extends State<StillHome> {
  AudioPlayer? _player;
  AudioPlayer get player => _player ??= AudioPlayer();
  bool enabled = true, sound = true, vibration = false, pausing = false;
  bool saving = true;
  bool settingsOpen = false;
  String? scheduleError;
  int averageMinutes = 35, rotationDays = 3, seed = 7182;
  int startMinute = 540, endMinute = 1260;
  Timer? pauseTimer;
  @override
  void initState() {
    super.initState();
    settingsOpen = widget.initialSettings;
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      saving = true;
      scheduleError = null;
    });
    try {
      final p = await (widget.settingsLoader ?? SharedPreferences.getInstance)()
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      setState(() {
        enabled = p.getBool('enabled') ?? true;
        sound = p.getBool('sound') ?? true;
        vibration = p.getBool('vibration') ?? false;
        startMinute = p.getInt('startMinute') ?? (p.getInt('start') ?? 9) * 60;
        endMinute = p.getInt('endMinute') ?? (p.getInt('end') ?? 21) * 60;
        averageMinutes = p.getInt('average') ?? 35;
        rotationDays = p.getInt('rotation') ?? 3;
        seed = p.getInt('seed') ?? 7182;
      });
      await ReminderService.instance.requestPermissions();
      await _save();
    } catch (error) {
      if (mounted) setState(() => scheduleError = 'Startup failed: $error');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _save() async {
    if (!mounted) return;
    setState(() {
      saving = true;
      scheduleError = null;
    });
    try {
      final p = await (widget.settingsLoader ?? SharedPreferences.getInstance)()
          .timeout(const Duration(seconds: 8));
      await p.setBool('enabled', enabled).timeout(const Duration(seconds: 8));
      await p.setBool('sound', sound).timeout(const Duration(seconds: 8));
      await p
          .setBool('vibration', vibration)
          .timeout(const Duration(seconds: 8));
      await p
          .setInt('startMinute', startMinute)
          .timeout(const Duration(seconds: 8));
      await p
          .setInt('endMinute', endMinute)
          .timeout(const Duration(seconds: 8));
      await p
          .setInt('average', averageMinutes)
          .timeout(const Duration(seconds: 8));
      await p
          .setInt('rotation', rotationDays)
          .timeout(const Duration(seconds: 8));
      await p.setInt('seed', seed).timeout(const Duration(seconds: 8));
      await ReminderService.instance.reschedule(
          enabled: enabled,
          sound: sound,
          vibration: vibration,
          startMinute: startMinute,
          endMinute: endMinute,
          averageMinutes: averageMinutes,
          rotationDays: rotationDays,
          seed: seed);
    } catch (error) {
      scheduleError = 'Reminders not confirmed: $error';
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _presence() async {
    pauseTimer?.cancel();
    setState(() => pausing = true);
    try {
      if (vibration && (await Vibration.hasVibrator())) {
        await Vibration.vibrate(duration: 250);
      }
      if (!mounted) return;
      if (sound) {
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setVolume(0);
        final index = soundIndexForDay(DateTime.now(), seed, rotationDays);
        await player.play(AssetSource('audio/${soundFiles[index]}.wav'));
        // Smooth fade-in and fade-out for in-app playback only.
        for (var i = 0; i <= 24; i++) {
          if (!mounted || !pausing) break;
          final volume =
              i < 4 ? i / 4 * 0.6 : (i > 19 ? (24 - i) / 5 * 0.6 : 0.6);
          await player.setVolume(volume.clamp(0, 0.6));
          await Future.delayed(const Duration(milliseconds: 500));
        }
        if (mounted) await player.stop();
      } else {
        await Future.delayed(const Duration(seconds: 12));
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Sound could not play. Please try again.')));
    } finally {
      if (mounted) setState(() => pausing = false);
    }
  }

  @override
  void dispose() {
    pauseTimer?.cancel();
    _player?.dispose();
    super.dispose();
  }

  String _time(int minute) =>
      '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';
  String _rhythm(int n) =>
      n < 60 ? '~$n min' : '~${n ~/ 60} ${n == 60 ? 'hour' : 'hours'}';

  Future<void> _pickTime(bool from) async {
    final minute = from ? startMinute : endMinute;
    final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: minute ~/ 60, minute: minute % 60));
    if (picked == null || !mounted) return;
    final value = picked.hour * 60 + picked.minute;
    if ((from && value >= endMinute) || (!from && value <= startMinute)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Until must be later than From.')));
      return;
    }
    setState(() {
      if (from) {
        startMinute = value;
      } else {
        endMinute = value;
      }
    });
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    if (settingsOpen) return _settings(context);
    return Scaffold(
        backgroundColor: const Color(0xFF050706),
        body: SafeArea(
          child: LayoutBuilder(
              builder: (context, constraints) => Stack(children: [
                    const Positioned.fill(child: LivingSpiral()),
                    Positioned(
                        top: constraints.maxHeight * .65,
                        left: 0,
                        right: 0,
                        child: const Column(children: [
                          Text('STILL',
                              style: TextStyle(
                                  fontFamily: 'serif',
                                  fontSize: 30,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 10,
                                  color: Color(0xFFEEEADD))),
                          SizedBox(height: 15),
                          Text('A gentle return\nto presence',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 12,
                                  height: 1.6,
                                  letterSpacing: 2,
                                  color: Color(0xFFB9C2B5))),
                        ])),
                    Positioned(
                        top: 8,
                        right: 12,
                        child: IconButton(
                            tooltip: 'Settings',
                            icon: const Icon(Icons.settings_outlined,
                                color: Color(0xFFBAC3B8)),
                            onPressed: () =>
                                setState(() => settingsOpen = true))),
                    Positioned(
                        top: constraints.maxHeight * .83,
                        left: 0,
                        right: 0,
                        child: Column(children: [
                          Switch(
                              value: enabled,
                              activeTrackColor: const Color(0xFF52764A),
                              activeThumbColor: Colors.white,
                              onChanged: saving
                                  ? null
                                  : (v) {
                                      setState(() => enabled = v);
                                      _save();
                                    }),
                          Text(
                              saving
                                  ? 'Updating reminders…'
                                  : scheduleError != null
                                      ? 'Check reminders in Settings'
                                      : enabled
                                          ? 'Reminders are on'
                                          : 'Reminders are off',
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFFB9C2B5))),
                        ])),
                  ])),
        ));
  }

  Widget _settings(BuildContext context) => Scaffold(
        body: SafeArea(
            child: SingleChildScrollView(
                child: Center(
                    child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(children: [
              const SizedBox(height: 12),
              Row(children: [
                IconButton(
                    tooltip: 'Back to home',
                    icon: const Icon(Icons.arrow_back_ios_new),
                    onPressed: () => setState(() => settingsOpen = false)),
                const Text('Settings',
                    style: TextStyle(fontSize: 22, fontFamily: 'serif'))
              ]),
              const SizedBox(height: 24),
              FilledButton(
                  onPressed: pausing ? null : _presence,
                  child: Text(pausing ? 'Being here…' : 'Pause for presence')),
              const SizedBox(height: 20),
              SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Gentle reminders'),
                  subtitle: Text(
                      '${_time(startMinute)}–${_time(endMinute)} · every ${_rhythm(averageMinutes)}',
                      style: const TextStyle(fontSize: 12)),
                  value: enabled,
                  onChanged: saving
                      ? null
                      : (v) {
                          setState(() => enabled = v);
                          _save();
                        }),
              Row(children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: saving ? null : () => _pickTime(true),
                        child: Text('From  ${_time(startMinute)}'))),
                const SizedBox(width: 12),
                Expanded(
                    child: OutlinedButton(
                        onPressed: saving ? null : () => _pickTime(false),
                        child: Text('Until  ${_time(endMinute)}'))),
              ]),
              Row(children: [
                Expanded(
                    child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title:
                            const Text('Sound', style: TextStyle(fontSize: 14)),
                        value: sound,
                        onChanged: saving
                            ? null
                            : (v) {
                                setState(() => sound = v);
                                _save();
                              })),
                const SizedBox(width: 8),
                Expanded(
                    child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Vibrate',
                            style: TextStyle(fontSize: 14)),
                        value: vibration,
                        onChanged: saving
                            ? null
                            : (v) {
                                setState(() => vibration = v);
                                _save();
                              })),
              ]),
              Row(children: [
                const Expanded(child: Text('Rhythm')),
                DropdownButton<int>(
                    value: averageMinutes,
                    items: [25, 35, 45, 60, 120, 180]
                        .map((n) =>
                            DropdownMenuItem(value: n, child: Text(_rhythm(n))))
                        .toList(),
                    onChanged: saving
                        ? null
                        : (n) {
                            if (n != null) {
                              setState(() => averageMinutes = n);
                              _save();
                            }
                          })
              ]),
              Row(children: [
                const Expanded(child: Text('Change instrument')),
                DropdownButton<int>(
                    value: rotationDays,
                    items: [1, 2, 3, 4, 5]
                        .map((n) => DropdownMenuItem(
                            value: n,
                            child:
                                Text(n == 1 ? 'Every day' : 'Every $n days')))
                        .toList(),
                    onChanged: saving
                        ? null
                        : (n) {
                            if (n != null) {
                              setState(() => rotationDays = n);
                              _save();
                            }
                          })
              ]),
              const SizedBox(height: 12),
              Text(
                  'Today: ${soundNames[soundIndexForDay(DateTime.now(), seed, rotationDays)]}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              if (saving)
                const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Updating reminders…')),
              if (scheduleError != null)
                Text(scheduleError!, textAlign: TextAlign.center),
              if (scheduleError != null)
                TextButton(
                    onPressed: saving ? null : _load,
                    child: const Text('Retry reminders')),
              if (!saving &&
                  enabled &&
                  ReminderService.instance.scheduledUntil != null)
                Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                        'Reopen before ${ReminderService.instance.scheduledUntil!.toLocal().toString().substring(0, 16)} to renew reminders.',
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey))),
              const SizedBox(height: 28),
              const Text('NOTHING TO ACHIEVE. JUST BE HERE.',
                  style: TextStyle(
                      fontSize: 9, letterSpacing: 2, color: Colors.grey)),
              const SizedBox(height: 24),
            ]),
          ),
        )))),
      );
}

class SpiralPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 64, size.height / 64);
    canvas.drawPath(
        stillSpiralPath(), Paint()..color = const Color(0xFF32CE70));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
