import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum AppButtonStyle { primary, secondary, text }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = AppButtonStyle.primary,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonStyle style;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonWidth = width ?? double.infinity;

    switch (style) {
      case AppButtonStyle.primary:
        return Container(
          width: buttonWidth,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: onPressed != null
                ? const LinearGradient(
                    colors: [AppColors.emerald, AppColors.emeraldMedium],
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                  )
                : null,
            color: onPressed == null ? AppColors.grey300 : null,
            boxShadow: onPressed != null
                ? [
                    BoxShadow(
                      color: AppColors.emerald.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: isLoading ? null : onPressed,
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, color: AppColors.white, size: 20),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            label,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );

      case AppButtonStyle.secondary:
        return SizedBox(
          width: buttonWidth,
          height: 54,
          child: OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.emerald),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(label),
                    ],
                  ),
          ),
        );

      case AppButtonStyle.text:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18),
                      const SizedBox(width: 6),
                    ],
                    Text(label),
                  ],
                ),
        );
    }
  }
}
