import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isFullWidth;
  final bool isOutlined;
  final double height;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isFullWidth = true,
    this.isOutlined = false,
    this.height = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = isOutlined
        ? OutlinedButton.styleFrom(
            foregroundColor: AppColors.secondary,
            side: const BorderSide(color: AppColors.secondary, width: 1),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.secondary,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          );

    final Widget buttonChild = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (icon != null) ...[
          icon!,
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              ),
        ),
      ],
    );

    final VoidCallback? hapticOnPressed = onPressed != null
        ? () {
            HapticFeedback.lightImpact();
            onPressed?.call();
          }
        : null;

    final Widget button = SizedBox(
      height: height,
      width: isFullWidth ? double.infinity : null,
      child: isOutlined
          ? OutlinedButton(onPressed: hapticOnPressed, style: style, child: buttonChild)
          : ElevatedButton(onPressed: hapticOnPressed, style: style, child: buttonChild),
    );

    return button;
  }
}
