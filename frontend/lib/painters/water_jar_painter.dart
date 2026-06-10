import 'dart:math' as math;
import 'package:flutter/material.dart';

class WaterJarPainter extends CustomPainter {
  final double fillPercent;
  final double wavePhase;

  WaterJarPainter({
    required this.fillPercent,
    required this.wavePhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ─────────────────────────────────────────────────────
    //  ALL PROPORTIONS
    // ─────────────────────────────────────────────────────

    // Neck
    final neckL      = w * 0.37;
    final neckR      = w * 0.63;
    final neckBottom = h * 0.22;

    // Body
    final bodyL      = w * 0.09;
    final bodyR      = w * 0.91;
    final shoulderY  = h * 0.33;
    final bodyBottom = h * 0.96;

    // Rim — wider than neck, clearly visible open top
    final rimL    = w * 0.32;
    final rimR    = w * 0.68;
    final rimTop  = h * 0.02;
    final rimBot  = h * 0.10;   // rim bottom = where neck begins
    final rimH    = rimBot - rimTop;
    final rimW    = rimR - rimL;
    final cx      = rimL + rimW / 2;

    // Wall thickness
    final wall    = rimW * 0.13;
    final holeL   = rimL + wall;
    final holeR   = rimR - wall;
    final holeW   = holeR - holeL;

    // neckTop = rimBot — perfectly flush
    final neckTop = rimBot;

    // ─────────────────────────────────────────────────────
    //  1. SHADOW
    // ─────────────────────────────────────────────────────
    canvas.drawPath(
      _bodyPath(bodyL, bodyR, shoulderY, bodyBottom,
          neckL, neckR, neckTop, neckBottom,
          dx: 3, dy: 5),
      Paint()
        ..color = const Color(0x1A000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // ─────────────────────────────────────────────────────
    //  2. BODY CLIPPED
    // ─────────────────────────────────────────────────────
    final bp = _bodyPath(bodyL, bodyR, shoulderY, bodyBottom,
        neckL, neckR, neckTop, neckBottom);

    canvas.save();
    canvas.clipPath(bp);

    // Glass fill
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h),
      Paint()..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          const Color(0xFFC8E5F4).withAlpha(195),
          const Color(0xFFEDF8FF).withAlpha(228),
          const Color(0xFFC5E3F2).withAlpha(195),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(bodyL, rimTop, bodyR - bodyL, bodyBottom - rimTop)),
    );

    // Water
    if (fillPercent > 0) _drawWater(canvas, bodyL, bodyR, shoulderY, bodyBottom);

    // Left reflection
    final sw = (bodyR - bodyL) * 0.19;
    canvas.drawPath(
      Path()
        ..moveTo(bodyL + 5, shoulderY)
        ..lineTo(bodyL + 5, bodyBottom - 14)
        ..lineTo(bodyL + sw, bodyBottom - 14)
        ..lineTo(bodyL + sw, shoulderY)
        ..close(),
      Paint()..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Colors.white.withAlpha(72), Colors.white.withAlpha(0)],
      ).createShader(Rect.fromLTWH(bodyL, shoulderY, sw, 10)),
    );

    // Neck tint
    canvas.drawRect(Rect.fromLTRB(neckL, neckTop, neckR, neckBottom),
      Paint()..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          const Color(0xFFCDE8F5).withAlpha(140),
          const Color(0xFFEDF8FF).withAlpha(165),
          const Color(0xFFC9E5F3).withAlpha(140),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTRB(neckL, neckTop, neckR, neckBottom)),
    );

    canvas.restore();

    // Body outline
    canvas.drawPath(bp,
      Paint()
        ..color = const Color(0xFF6FB6D8).withAlpha(145)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );

    // ─────────────────────────────────────────────────────
    //  3. OPEN RIM — drawn last, on top
    // ─────────────────────────────────────────────────────
    _drawRim(canvas,
      rimL: rimL, rimR: rimR, rimTop: rimTop, rimBot: rimBot,
      rimW: rimW, rimH: rimH, cx: cx,
      holeL: holeL, holeR: holeR, holeW: holeW, wall: wall,
    );
  }

  // ─────────────────────────────────────────────────────────
  //  OPEN RIM
  //
  //  Think of it as a cylindrical collar:
  //   • Outer shape: rounded-top rect (the outside of the cylinder)
  //   • Inner hole : rounded rect subtracted from it (the opening)
  //   • Top ellipse: drawn over the top edge to give 3-D depth
  // ─────────────────────────────────────────────────────────
  void _drawRim(Canvas canvas, {
    required double rimL, required double rimR,
    required double rimTop, required double rimBot,
    required double rimW, required double rimH,
    required double cx,
    required double holeL, required double holeR,
    required double holeW, required double wall,
  }) {
    // Vertical radius of the top ellipse — generous so it looks 3-D
    final eRy  = rimH * 0.55;
    // Center of ellipse is exactly at rimTop so the oval straddles the top edge
    final eCY  = rimTop + eRy;

    // ── A. Outer rim body (cylinder side wall) ─────────────
    final outerRect = RRect.fromRectAndCorners(
      Rect.fromLTRB(rimL, eCY, rimR, rimBot),
      bottomLeft:  const Radius.circular(8),  // SMOOTH curves
      bottomRight: const Radius.circular(8),  // SMOOTH curves
    );

    // Premium glass cylinder body with sophisticated gradient
    canvas.drawRRect(outerRect,
      Paint()..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          const Color(0xFF4A7FA5).withAlpha(230),
          const Color(0xFFD5ECFF).withAlpha(255),
          const Color(0xFFC0E0FF).withAlpha(250),
          const Color(0xFF3A6F95).withAlpha(225),
        ],
        stops: const [0.0, 0.38, 0.62, 1.0],
      ).createShader(Rect.fromLTRB(rimL, rimTop, rimR, rimBot)),
    );

    // ── A2. SMOOTH LEFT & RIGHT EDGE GLOWS ──────────────────
    // Soft gradient glow on left side for smooth transition
    canvas.drawPath(
      Path()
        ..moveTo(rimL - 2, eCY)
        ..lineTo(rimL - 2, rimBot)
        ..lineTo(rimL + 8, rimBot)
        ..lineTo(rimL + 8, eCY)
        ..close(),
      Paint()..shader = LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: [
          const Color(0xFF4A7FA5).withAlpha(100),
          const Color(0xFF4A7FA5).withAlpha(0),
        ],
      ).createShader(Rect.fromLTRB(rimL - 2, eCY, rimL + 8, rimBot)),
    );

    // Soft gradient glow on right side for smooth transition
    canvas.drawPath(
      Path()
        ..moveTo(rimR + 2, eCY)
        ..lineTo(rimR + 2, rimBot)
        ..lineTo(rimR - 8, rimBot)
        ..lineTo(rimR - 8, eCY)
        ..close(),
      Paint()..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          const Color(0xFF3A6F95).withAlpha(100),
          const Color(0xFF3A6F95).withAlpha(0),
        ],
      ).createShader(Rect.fromLTRB(rimR - 8, eCY, rimR + 2, rimBot)),
    );

    // ── B. Dark hollow — bottle opening interior ───────────
    canvas.drawRect(
      Rect.fromLTRB(holeL, eCY, holeR, rimBot),
      Paint()..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF051828).withAlpha(248),
          const Color(0xFF000000).withAlpha(255),
        ],
      ).createShader(Rect.fromLTRB(holeL, eCY, holeR, rimBot)),
    );

    // ── C. Top ellipse — the mouth of the bottle ───────────
    final outerEllipseRect = Rect.fromCenter(
      center: Offset(cx, eCY),
      width:  rimW,
      height: eRy * 2,
    );

    final innerEllipseRect = Rect.fromCenter(
      center: Offset(cx, eCY),
      width:  holeW,
      height: eRy * 2 * 0.82,
    );

    // 1. Deep dark interior opening
    canvas.drawOval(
      innerEllipseRect,
      Paint()..shader = RadialGradient(
        center: const Alignment(0, -0.2),
        radius: 1.0,
        colors: [
          const Color(0xFF0B2A3F).withAlpha(225),
          const Color(0xFF000000).withAlpha(255),
        ],
      ).createShader(innerEllipseRect),
    );

    // 2. Main rim surface — GLOSSY PROFESSIONAL FINISH
    final annulus = Path.combine(
      PathOperation.difference,
      Path()..addOval(outerEllipseRect),
      Path()..addOval(innerEllipseRect),
    );

    canvas.drawPath(annulus,
      Paint()..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withAlpha(245),
          const Color(0xFFE8F5FF).withAlpha(240),
          const Color(0xFFC5E8F8).withAlpha(220),
        ],
        stops: const [0.0, 0.35, 1.0],
      ).createShader(outerEllipseRect),
    );

    // 3. PRIMARY BRIGHT HIGHLIGHT — strong and visible
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx - rimW * 0.1, eCY - eRy * 0.22),
        width:  rimW * 0.7,
        height: eRy * 1.3,
      ),
      math.pi + 0.08,
      math.pi * 0.62,
      false,
      Paint()
        ..color = Colors.white.withAlpha(255)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round,
    );

    // 4. SECONDARY BRIGHT HIGHLIGHT
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx - rimW * 0.18, eCY - eRy * 0.32),
        width:  rimW * 0.5,
        height: eRy * 0.95,
      ),
      math.pi + 0.15,
      math.pi * 0.58,
      false,
      Paint()
        ..color = Colors.white.withAlpha(200)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );

    // 5. TERTIARY ACCENT HIGHLIGHT
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx - rimW * 0.28, eCY - eRy * 0.4),
        width:  rimW * 0.38,
        height: eRy * 0.75,
      ),
      math.pi + 0.25,
      math.pi * 0.52,
      false,
      Paint()
        ..color = Colors.white.withAlpha(140)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );

    // 6. Sharp inner rim glow with defined edge
    canvas.drawOval(
      innerEllipseRect,
      Paint()
        ..color = const Color(0xFF2B7FA8).withAlpha(145)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // 7. Deep shadow on inner opening
    canvas.drawOval(
      innerEllipseRect,
      Paint()
        ..color = const Color(0xFF000000).withAlpha(100)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );

    // 8. Outer rim beveled edge highlight
    canvas.drawOval(
      outerEllipseRect,
      Paint()
        ..color = const Color(0xFF4DAEE0).withAlpha(160)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // ── D. SMOOTH PROFESSIONAL OUTLINES ──────────────────────
    // Main outer border with SMOOTH curve
    canvas.drawOval(outerEllipseRect,
      Paint()
        ..color = const Color(0xFF1F4A6A).withAlpha(180)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // SMOOTH LEFT SIDE - soft gradient instead of hard line
    canvas.drawPath(
      Path()
        ..moveTo(rimL, eCY)
        ..cubicTo(rimL - 1, eCY + (rimBot - eCY) * 0.3,
            rimL - 1, eCY + (rimBot - eCY) * 0.7,
            rimL, rimBot),
      Paint()
        ..color = const Color(0xFF1F4A6A).withAlpha(140)
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // SMOOTH RIGHT SIDE - soft gradient instead of hard line
    canvas.drawPath(
      Path()
        ..moveTo(rimR, eCY)
        ..cubicTo(rimR + 1, eCY + (rimBot - eCY) * 0.3,
            rimR + 1, eCY + (rimBot - eCY) * 0.7,
            rimR, rimBot),
      Paint()
        ..color = const Color(0xFF1F4A6A).withAlpha(140)
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // Smooth bottom edge with rounded appearance
    canvas.drawArc(
      Rect.fromLTRB(rimL, rimBot - 4, rimR, rimBot + 4),
      0,
      math.pi,
      false,
      Paint()
        ..color = const Color(0xFF0F2A4A).withAlpha(140)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // 9. PREMIUM TOP RIM EDGE DEFINITION
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, eCY - eRy * 0.08),
        width:  rimW * 1.02,
        height: eRy * 1.15,
      ),
      Paint()
        ..color = const Color(0xFF3FA0D0).withAlpha(110)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // ── E. SMOOTH SIDE GLOWS ─────────────────────────────────
    // Left side smooth glow
    canvas.drawPath(
      Path()
        ..moveTo(rimL + 0.5, eCY)
        ..lineTo(rimL + 0.5, rimBot)
        ..lineTo(rimL + 3, rimBot)
        ..lineTo(rimL + 3, eCY)
        ..close(),
      Paint()..shader = LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: [
          const Color(0xFF6BA5D0).withAlpha(60),
          const Color(0xFF6BA5D0).withAlpha(0),
        ],
      ).createShader(Rect.fromLTRB(rimL, eCY, rimL + 3, rimBot)),
    );

    // Right side smooth glow
    canvas.drawPath(
      Path()
        ..moveTo(rimR - 0.5, eCY)
        ..lineTo(rimR - 0.5, rimBot)
        ..lineTo(rimR - 3, rimBot)
        ..lineTo(rimR - 3, eCY)
        ..close(),
      Paint()..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          const Color(0xFF5A95C0).withAlpha(60),
          const Color(0xFF5A95C0).withAlpha(0),
        ],
      ).createShader(Rect.fromLTRB(rimR - 3, eCY, rimR, rimBot)),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  BODY PATH (neck + shoulders + body, open top)
  // ─────────────────────────────────────────────────────────
  Path _bodyPath(
      double bodyL, double bodyR, double shoulderY, double bodyBottom,
      double neckL, double neckR, double neckTop, double neckBottom, {
        double dx = 0, double dy = 0,
      }) {
    final p = Path();
    p.moveTo(bodyL + dx, bodyBottom - 8 + dy);
    p.arcToPoint(Offset(bodyR + dx, bodyBottom - 8 + dy),
        radius: Radius.circular((bodyR - bodyL) * 0.55), clockwise: false);
    p.lineTo(bodyR + dx, shoulderY + dy);
    p.cubicTo(
      bodyR + dx, shoulderY - (shoulderY - neckBottom) * 0.3 + dy,
      neckR + dx, neckBottom + (shoulderY - neckBottom) * 0.3 + dy,
      neckR + dx, neckBottom + dy,
    );
    p.lineTo(neckR + dx, neckTop + dy);
    p.lineTo(neckL + dx, neckTop + dy);
    p.lineTo(neckL + dx, neckBottom + dy);
    p.cubicTo(
      neckL + dx, neckBottom + (shoulderY - neckBottom) * 0.3 + dy,
      bodyL + dx, shoulderY - (shoulderY - neckBottom) * 0.3 + dy,
      bodyL + dx, shoulderY + dy,
    );
    p.lineTo(bodyL + dx, bodyBottom - 8 + dy);
    p.close();
    return p;
  }

  // ─────────────────────────────────────────────────────────
  //  WATER FILL
  // ─────────────────────────────────────────────────────────
  void _drawWater(Canvas canvas, double bodyL, double bodyR,
      double shoulderY, double bodyBottom) {
    final fillableH = bodyBottom - shoulderY;
    final waterTop  = bodyBottom - (fillableH * fillPercent * 0.92);
    const waveH     = 2.5;

    final wp = Path()..moveTo(bodyL, bodyBottom);
    for (double x = bodyL; x <= bodyR; x++) {
      final nx = (x - bodyL) / (bodyR - bodyL);
      wp.lineTo(x,
          waterTop
              + math.sin((nx * 2.8 * math.pi) + wavePhase) * waveH
              + math.sin((nx * 5.5 * math.pi) + wavePhase * 1.4) * (waveH * 0.35));
    }
    wp
      ..lineTo(bodyR, bodyBottom)
      ..arcToPoint(Offset(bodyL, bodyBottom),
          radius: Radius.circular((bodyR - bodyL) * 0.5), clockwise: true)
      ..close();

    canvas.drawPath(wp,
      Paint()..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF9FD8F5).withAlpha(210),
          const Color(0xFF55B8EC).withAlpha(225),
          const Color(0xFF2A9EDE).withAlpha(240),
          const Color(0xFF1880C0).withAlpha(255),
        ],
        stops: const [0.0, 0.3, 0.65, 1.0],
      ).createShader(Rect.fromLTRB(bodyL, waterTop, bodyR, bodyBottom)),
    );

    // Surface shimmer
    final sp = Path()..moveTo(bodyL, waterTop);
    for (double x = bodyL; x <= bodyR; x++) {
      final nx = (x - bodyL) / (bodyR - bodyL);
      sp.lineTo(x,
          waterTop
              + math.sin((nx * 2.8 * math.pi) + wavePhase) * waveH
              + math.sin((nx * 5.5 * math.pi) + wavePhase * 1.4) * (waveH * 0.35));
    }
    canvas.drawPath(sp,
        Paint()
          ..color = Colors.white.withAlpha(60)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke);

    _drawBubbles(canvas, bodyL, bodyR, waterTop, bodyBottom);
  }

  // ─────────────────────────────────────────────────────────
  //  BUBBLES
  // ─────────────────────────────────────────────────────────
  void _drawBubbles(Canvas canvas, double l, double r,
      double waterTop, double bottom) {
    final rng  = math.Random(42);
    final midX = (l + r) / 2;
    final wH   = bottom - waterTop;
    for (int i = 0; i < 10; i++) {
      final bx    = l + 8 + rng.nextDouble() * (r - l - 16);
      final by    = waterTop + 4 + rng.nextDouble() * wH * 0.82;
      final br    = 1.2 + rng.nextDouble() * 4.0;
      final dist  = (bx - midX).abs() / ((r - l) / 2);
      final alpha = (55 * (1 - dist * 0.5)).toInt().clamp(18, 55);
      canvas.drawCircle(Offset(bx, by), br,
          Paint()..color = Colors.white.withAlpha(alpha));
      canvas.drawCircle(Offset(bx, by), br,
          Paint()
            ..color = Colors.white.withAlpha((alpha * 0.6).toInt())
            ..style = PaintingStyle.stroke..strokeWidth = 0.5);
      if (br > 2.5) {
        canvas.drawCircle(Offset(bx - br * 0.3, by - br * 0.3), br * 0.28,
            Paint()..color = Colors.white
                .withAlpha((alpha * 1.2).toInt().clamp(0, 255)));
      }
    }
  }

  @override
  bool shouldRepaint(covariant WaterJarPainter old) =>
      old.fillPercent != fillPercent || old.wavePhase != wavePhase;
}