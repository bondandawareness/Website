import 'cinematic_spiral.dart';
export 'cinematic_spiral.dart' show OpeningSpiralPainter;
import 'package:flutter/material.dart';

/// Played once per app launch, before home requests notification permissions.
class StillOpening extends StatefulWidget {
  const StillOpening({super.key, required this.homeBuilder});
  final WidgetBuilder homeBuilder;
  @override
  State<StillOpening> createState() => _StillOpeningState();
}

class _StillOpeningState extends State<StillOpening>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _animation;
  bool _finished = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animation = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 10000))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _finish();
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _animation.stop();
      _finished = true;
    } else if (!_started && !_finished) {
      _started = true;
      _animation.forward();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _animation.stop();
    } else if (!_finished && !MediaQuery.disableAnimationsOf(context)) {
      _animation.forward();
    }
  }

  void _finish() {
    if (!mounted || _finished) return;
    _animation.stop();
    setState(() => _finished = true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: _animation,
        builder: (context, _) {
          final seconds = _finished ? 10.0 : _animation.value * 10.0;
          final fade = _smooth((seconds - 9.2) / .8);
          return Stack(fit: StackFit.expand, children: [
            if (_finished || seconds >= 9.2)
              KeyedSubtree(
                  key: const ValueKey("home"),
                  child: widget.homeBuilder(context)),
            if (!_finished)
              Opacity(
                  opacity: 1 - fade,
                  child: Scaffold(
                    backgroundColor: const Color(0xFF050706),
                    body: SafeArea(
                        child: LayoutBuilder(builder: (context, constraints) {
                      return Stack(children: [
                        Positioned.fill(
                            child: RepaintBoundary(
                                child: CustomPaint(
                                    painter: OpeningSpiralPainter(seconds)))),
                        Positioned(
                            top: constraints.maxHeight * .65,
                            left: 0,
                            right: 0,
                            child: Opacity(
                                opacity: _smooth((seconds - 7.7) / 1.5),
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
                                ]))),
                        Positioned(
                            bottom: 20,
                            right: 20,
                            child: TextButton(
                                onPressed: _finish,
                                style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFFBAC3B8)),
                                child: const Text('Skip intro'))),
                      ]);
                    })),
                  )),
          ]);
        });
  }
}

double _smooth(double x) {
  x = x.clamp(0.0, 1.0);
  return x * x * (3 - 2 * x);
}
