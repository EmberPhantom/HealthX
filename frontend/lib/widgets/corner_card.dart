import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class CornerCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String topText;
  final String bottomText;
  final VoidCallback? onTap;

  const CornerCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.topText,
    required this.bottomText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          HapticFeedback.lightImpact();
          onTap!();
        }
      },
      child: Container(
        width: 72,
        height: 66,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(220),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF9DC9E8).withAlpha(80),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6EA8D0).withAlpha(20),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(height: 4),
            Text(
              topText,
              style: GoogleFonts.poppins(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A2E40),
                height: 1.1,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
            Text(
              bottomText,
              style: GoogleFonts.poppins(
                fontSize: 7.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF5B8AAE),
                height: 1.1,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}