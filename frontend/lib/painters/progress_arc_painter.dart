import 'dart:math' as math;
import 'package:flutter/material.dart';

class ProgressArcPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;

  ProgressArcPainter({
    required this.progress,
    this.strokeWidth = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth;

    const startAngle = -math.pi * 0.85;
    const sweepTotal = math.pi * 1.7;

    // Background track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      Paint()
        ..color = const Color(0xFFD6E8F5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    final progressSweep = sweepTotal * progress;
    if (progressSweep > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        progressSweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(
            startAngle: startAngle,
            endAngle: startAngle + progressSweep,
            colors: const [
              Color(0xFF5BA3D9),
              Color(0xFF2B6FA8),
              Color(0xFF1A4F7A),
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );

      final endAngle = startAngle + progressSweep;
      final dotX = center.dx + radius * math.cos(endAngle);
      final dotY = center.dy + radius * math.sin(endAngle);
      canvas.drawCircle(
        Offset(dotX, dotY),
        strokeWidth / 2 + 2,
        Paint()..color = const Color(0xFF1A4F7A),
      );
      canvas.drawCircle(
        Offset(dotX, dotY),
        strokeWidth / 2 - 1,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ProgressArcPainter oldDelegate) =>
      oldDelegate.progress != progress;
}