import 'dart:math' as math;
import 'package:flutter/material.dart';

class BubbleBackgroundPainter extends CustomPainter {
  final double phase;

  BubbleBackgroundPainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(123);

    for (int i = 0; i < 18; i++) {
      final x = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final y = baseY + math.sin(phase + i * 0.7) * 6;
      final r = 2.0 + rng.nextDouble() * 6.0;
      final alpha = (20 + rng.nextInt(30)).clamp(10, 50);

      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color = Colors.white.withAlpha(alpha)
          ..style = PaintingStyle.fill,
      );

      if (r > 3) {
        canvas.drawCircle(
          Offset(x - r * 0.25, y - r * 0.25),
          r * 0.3,
          Paint()
            ..color = Colors.white.withAlpha((alpha * 0.6).toInt())
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant BubbleBackgroundPainter oldDelegate) =>
      oldDelegate.phase != phase;
}