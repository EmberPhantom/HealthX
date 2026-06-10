import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'log_meal_sheet.dart';

class MealTypeSheet extends StatelessWidget {
  const MealTypeSheet({super.key});

  static const double _refW = 360;
  static const double _refH = 800;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final ws = screenWidth / _refW;
    final hs = screenHeight / _refH;

    final meals = [
      _MealOption('Breakfast', Icons.wb_twilight_rounded, const Color(0xFFFBC02D)),
      _MealOption('Lunch', Icons.wb_sunny_rounded, const Color(0xFF4CAF50)),
      _MealOption('Dinner', Icons.nightlight_round, const Color(0xFF1E2646)),
      _MealOption('Snack', Icons.apple_rounded, const Color(0xFFFF6B35)),
    ];

    return Stack(
      children: [
        // Scrim
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(color: Colors.black54),
        ),
        // Sheet
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.fromLTRB(
              20 * ws,
              20 * hs,
              20 * ws,
              20 * hs + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 36 * ws,
                  height: 4 * hs,
                  margin: EdgeInsets.only(bottom: 16 * hs),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2 * ws),
                  ),
                ),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10 * hs,
                  crossAxisSpacing: 10 * ws,
                  childAspectRatio: 2.4,
                  children: meals.map((m) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (_) => LogMealSheet(meal: m.label),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14 * ws),
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(m.icon, size: 18 * ws, color: m.color),
                            SizedBox(width: 8 * ws),
                            Text(
                              m.label,
                              style: GoogleFonts.poppins(
                                fontSize: 14 * ws,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF1A1A2E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        // Close button
        Positioned(
          bottom: 28 * hs + MediaQuery.of(context).padding.bottom,
          right: 20 * ws,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 32 * ws,
              height: 32 * ws,
              decoration: BoxDecoration(
                color: const Color(0xFF1E2646),
                borderRadius: BorderRadius.circular(16 * ws),
              ),
              child: Icon(Icons.close, color: Colors.white, size: 14 * ws),
            ),
          ),
        ),
      ],
    );
  }
}

class _MealOption {
  final String label;
  final IconData icon;
  final Color color;
  const _MealOption(this.label, this.icon, this.color);
}