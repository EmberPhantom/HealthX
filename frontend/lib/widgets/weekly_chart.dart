import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/water_provider.dart';
import '../painters/glass_icon_painter.dart';

class WeeklyChart extends StatelessWidget {
  const WeeklyChart({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WaterProvider>();
    final logs = provider.weeklyLogs;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(210),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8EDF8).withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6EA8D0).withAlpha(18),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'This Week',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A2E40),
                ),
              ),
              Text(
                'Daily goal: ${(provider.dailyGoal / 1000).toStringAsFixed(1)}L',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF8AAFC7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Chart row — each day is a column
          // FIX: Each day column has a fixed width so nothing floats or overflows
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(logs.length, (i) {
              final log = logs[i];
              final fill = provider.getGlassFillPercent(i);
              final isToday = i == logs.length - 1;

              return SizedBox(
                width: 36,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Time label — fixed height slot so alignment is consistent
                    SizedBox(
                      height: 16,
                      child: Text(
                        log.time ?? '',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w500,
                          color: isToday
                              ? const Color(0xFF4A9FD4)
                              : const Color(0xFF1A3A5C).withAlpha(140),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Glass icon
                    SizedBox(
                      width: 26,
                      height: 34,
                      child: CustomPaint(
                        painter: GlassIconPainter(fillPercent: fill),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Day label
                    Text(
                      log.day,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 9.5,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                        color: isToday
                            ? const Color(0xFF4A9FD4)
                            : const Color(0xFF1A3A5C),
                      ),
                    ),

                    // Today dot indicator
                    if (isToday) ...[
                      const SizedBox(height: 3),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4A9FD4),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}