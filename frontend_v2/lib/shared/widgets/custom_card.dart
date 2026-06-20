import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final double borderRadius;
  final BorderSide? borderSide;
  final bool clip;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.borderRadius = 16.0,
    this.borderSide,
    this.clip = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardChild = Padding(
      padding: padding ?? const EdgeInsets.all(16.0),
      child: child,
    );

    if (clip) {
      cardChild = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: cardChild,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.cardBackground,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.fromBorderSide(
          borderSide ?? const BorderSide(color: AppColors.border, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: cardChild,
    );
  }
}
