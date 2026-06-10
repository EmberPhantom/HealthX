import 'package:flutter/material.dart';

class GlassIconPainter extends CustomPainter {
  final double fillPercent;

  GlassIconPainter({required this.fillPercent});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final glassPath = Path()
      ..moveTo(w * 0.15, h * 0.05)
      ..lineTo(w * 0.85, h * 0.05)
      ..lineTo(w * 0.78, h * 0.95)
      ..quadraticBezierTo(w * 0.5, h * 1.02, w * 0.22, h * 0.95)
      ..close();

    canvas.drawPath(
      glassPath,
      Paint()..color = const Color(0xFFE4F0F8),
    );

    if (fillPercent > 0) {
      canvas.save();
      canvas.clipPath(glassPath);
      final waterTop = h * (1.0 - fillPercent * 0.9);
      canvas.drawRect(
        Rect.fromLTRB(0, waterTop, w, h),
        Paint()..color = const Color(0xFF5BADE6),
      );
      canvas.restore();
    }

    canvas.drawPath(
      glassPath,
      Paint()
        ..color = const Color(0xFF90BCD9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(covariant GlassIconPainter oldDelegate) =>
      oldDelegate.fillPercent != fillPercent;
}