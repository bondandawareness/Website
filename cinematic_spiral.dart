import 'dart:math' as math;
import 'package:flutter/material.dart';

double _smooth(double x) {
  x = x.clamp(0.0, 1.0);
  return x * x * (3 - 2 * x);
}

class OpeningSpiralPainter extends CustomPainter {
  const OpeningSpiralPainter(this.seconds, {this.phase = 0});
  final double phase;
  final double seconds;
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || !size.width.isFinite || !size.height.isFinite) return;
    final gather = _smooth((seconds - 3) / 6);
    final reveal = _smooth((seconds - .2) / 2.8);
    final visibility = _smooth((seconds - .4) / 2.6);
    final breath = math.sin(phase * math.pi * 2);
    final radius = math.min(size.width * .34, 145.0) * (1 + .025 * breath);
    final center = Offset(size.width / 2, size.height * .4);
    final halo = Rect.fromCircle(center: center, radius: radius * 1.65);
    canvas.drawRect(
        halo,
        Paint()
          ..shader = RadialGradient(stops: const [
            0,
            .45,
            1
          ], colors: [
            const Color(0xFF87A96F).withValues(alpha: .10 * visibility),
            const Color(0xFF44693F).withValues(alpha: .08 * visibility),
            Colors.transparent,
          ]).createShader(halo));
    // Wide, interwoven currents dissolve as the central spiral gathers.
    final flow =
        _smooth((seconds - .5) / 2.5) * (1 - _smooth((seconds - 6) / 3.2));
    if (flow > 0) {
      for (var strand = 0; strand < 26; strand++) {
        final path = Path();
        final group = strand % 2;
        final spread = (strand ~/ 2 - 6) / 6;
        for (var i = 0; i <= 140; i++) {
          final u = i / 140;
          final theta = u * math.pi * 3.8 + group * math.pi + seconds * .045;
          final r =
              (10 + math.pow(u, 1.7) * size.width * .9) * (1 + spread * .045);
          final x = size.width * (group == 0 ? .28 : .72) + math.cos(theta) * r;
          final y = size.height * (group == 0 ? .3 : .7) +
              math.sin(theta) * r +
              spread * 12;
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        canvas.drawPath(
            path,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strand % 5 == 0 ? 1 : .45
              ..color = (strand % 4 == 0
                      ? const Color(0xFF95B18A)
                      : const Color(0xFFE6DFC7))
                  .withValues(alpha: flow * (strand % 5 == 0 ? .19 : .065)));
      }
    }
    // A tapered ribbon with evenly spaced turns, matching the reference silhouette.
    Offset spine(double u) {
      final angle = -.35 - (1 - u) * math.pi * 4.4 + .018 * breath;
      final r = radius * (.025 + .975 * u) * (1 + .18 * (1 - gather));
      return center + Offset(math.cos(angle) * r, math.sin(angle) * r);
    }

    Path ribbon(double thickness) {
      final left = <Offset>[], right = <Offset>[];
      final start = (1 - reveal).clamp(0.0, 1.0);
      for (var i = 0; i <= 420; i++) {
        final u = start + (1 - start) * i / 420;
        final p = spine(u), tangent = spine(u + .0001) - spine(u - .0001);
        final normal = Offset(-tangent.dy, tangent.dx) / tangent.distance;
        final taper = _smooth(u / .07) * (1 - _smooth((u - .80) / .20));
        final half = radius * .05 * taper * thickness;
        left.add(p + normal * half);
        right.add(p - normal * half);
      }
      return Path()..addPolygon([...left, ...right.reversed], true);
    }

    // Continuous apparent motion with one reversal at the peak, retained on home.
    double rotation(double t) {
      const times = [0.0, 3.0, 5.7, 6.4, 7.6, 9.0, 10.0];
      const speeds = [
        .12,
        2.0,
        20.0,
        -.22,
        -.22,
        -2 * math.pi / 14,
        -2 * math.pi / 14
      ];
      var angle = 0.0;
      for (var i = 0; i < times.length - 1; i++) {
        final d = times[i + 1] - times[i],
            u = ((t - times[i]) / d).clamp(0.0, 1.0);
        angle += d *
            (speeds[i] * u +
                (speeds[i + 1] - speeds[i]) * (u * u * u - .5 * u * u * u * u));
        if (u < 1) break;
      }
      return angle;
    }

    final turn =
        seconds >= 10 ? rotation(10) - phase * math.pi * 2 : rotation(seconds);
    final light = .12 + .88 * _smooth(seconds / 8);
    final trails =
        _smooth((seconds - 5.7) / .7) * (1 - _smooth((seconds - 7.6) / 1.3));
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(turn);
    canvas.translate(-center.dx, -center.dy);
    for (var i = 3; i >= 1; i--) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(-i * .22);
      canvas.translate(-center.dx, -center.dy);
      canvas.drawPath(
          ribbon(1),
          Paint()
            ..color =
                const Color(0xFF60FFAE).withValues(alpha: trails * .025 / i));
      canvas.restore();
    }
    canvas.saveLayer(
        null, Paint()..color = Colors.white.withValues(alpha: light));
    final shape = ribbon(1);
    canvas.drawPath(
        shape,
        Paint()
          ..color = const Color(0xFF00F55B).withValues(alpha: .65 * visibility)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
    canvas.drawPath(
        shape,
        Paint()
          ..color = const Color(0xFF35FF88).withValues(alpha: visibility)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    canvas.drawPath(shape,
        Paint()..color = const Color(0xFFACFFCE).withValues(alpha: visibility));
    canvas.drawPath(
        ribbon(.57),
        Paint()
          ..color = const Color(0xFFEBFFF1).withValues(alpha: .64 * visibility)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1));
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(OpeningSpiralPainter oldDelegate) =>
      oldDelegate.seconds != seconds || oldDelegate.phase != phase;
}

/// The living spiral owns its ticker and stops whenever it cannot be seen.
class LivingSpiral extends StatefulWidget {
  const LivingSpiral({super.key});
  @override
  State<LivingSpiral> createState() => _LivingSpiralState();
}

class _LivingSpiralState extends State<LivingSpiral>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _cycle;
  bool _foreground = true;
  bool _motion = false;
  @override
  void initState() {
    super.initState();
    _foreground = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    _cycle =
        AnimationController(vsync: this, duration: const Duration(seconds: 14));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motion = !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    _sync();
  }

  void _sync() {
    if (_foreground && _motion) {
      if (!_cycle.isAnimating) _cycle.repeat();
    } else {
      _cycle.stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
          child: AnimatedBuilder(
        animation: _cycle,
        builder: (context, _) => CustomPaint(
            painter:
                OpeningSpiralPainter(10, phase: _motion ? _cycle.value : 0)),
      ));
}
