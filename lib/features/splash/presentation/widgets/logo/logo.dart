import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/colors/app_colors.dart';

/// Brand mark with optional **ring rotation** and **glow pulse** (driven by animations).
class SplashLogo extends StatelessWidget {
  const SplashLogo({
    super.key,
    required this.diameter,
    this.ringRotation = 0,
    this.glowPulse = 0.5,
  });

  final double diameter;
  final double ringRotation;
  /// 0–1, breathing on the orange glow.
  final double glowPulse;

  @override
  Widget build(BuildContext context) {
    final d = diameter.clamp(120.0, 280.0);
    return SizedBox(
      width: d,
      height: d,
      child: CustomPaint(
        painter: _SplashLogoPainter(
          ringRotation: ringRotation,
          glowPulse: glowPulse.clamp(0.0, 1.0),
        ),
      ),
    );
  }
}

class _SplashLogoPainter extends CustomPainter {
  _SplashLogoPainter({
    required this.ringRotation,
    required this.glowPulse,
  });

  final double ringRotation;
  final double glowPulse;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final s = size.shortestSide;

    final ringR = s * 0.42;
    final coreR = s * 0.16;

    // Breathing glow radius / opacity
    final pulseT = (math.sin(glowPulse * math.pi * 2) + 1) / 2;
    final burstR = s * (0.24 + 0.04 * pulseT);
    final burstAlphaBoost = 0.75 + 0.2 * pulseT;

    // Luminous burst (radial behind core)
    final burst = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFB74D).withValues(alpha: 0.92 * burstAlphaBoost),
          const Color(0xFFFF8A65).withValues(alpha: 0.65 * burstAlphaBoost),
          const Color(0xFFFFB74D).withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: c, radius: burstR * 1.15));
    canvas.drawCircle(c, burstR, burst);

    // Dark core
    final corePaint = Paint()..color = const Color(0xFF0A3D38);
    canvas.drawCircle(c, coreR, corePaint);

    final innerGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.black.withValues(alpha: 0.0),
          Colors.black.withValues(alpha: 0.32),
        ],
      ).createShader(Rect.fromCircle(center: c, radius: coreR));
    canvas.drawCircle(c, coreR, innerGlow);

    // Pulse / heartbeat (white zigzag)
    final pulsePath = Path();
    final w = coreR * 1.5;
    final h = coreR * 0.55;
    final left = c.dx - w / 2;
    final top = c.dy - h / 2;
    pulsePath.moveTo(left, top + h * 0.5);
    pulsePath.lineTo(left + w * 0.18, top + h * 0.5);
    pulsePath.lineTo(left + w * 0.28, top + h * 0.2);
    pulsePath.lineTo(left + w * 0.42, top + h * 0.8);
    pulsePath.lineTo(left + w * 0.55, top + h * 0.35);
    pulsePath.lineTo(left + w * 0.68, top + h * 0.65);
    pulsePath.lineTo(left + w * 0.82, top + h * 0.45);
    pulsePath.lineTo(left + w, top + h * 0.5);

    final pulsePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.022
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(pulsePath, pulsePaint);

    // Orbit ring + dots (rotate together)
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(ringRotation);
    canvas.translate(-c.dx, -c.dy);

    final ringPaint = Paint()
      ..color = AppColors.primary300.withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.018
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, ringR, ringPaint);

    void dotAtHour(double hour) {
      final angle = -math.pi / 2 + (hour / 12) * 2 * math.pi;
      final p = Offset(
        c.dx + ringR * math.cos(angle),
        c.dy + ringR * math.sin(angle),
      );
      final isTeal = hour <= 3;
      final dotPaint = Paint()
        ..color = isTeal ? AppColors.primary400 : AppColors.tertiary300;
      canvas.drawCircle(p, s * 0.028, dotPaint);
    }

    dotAtHour(2);
    dotAtHour(8);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SplashLogoPainter oldDelegate) {
    return oldDelegate.ringRotation != ringRotation ||
        oldDelegate.glowPulse != glowPulse;
  }
}
