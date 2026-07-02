import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// A modal barrier with an elegant loading spinner.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  final bool isLoading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading) ...[
          // Modal barrier to block interactions
          ModalBarrier(
            dismissible: false,
            color: AppColors.emeraldDark.withValues(alpha: 0.15),
          ),
          // Loading Card
          Center(
            child: Card(
              color: AppColors.surface,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.divider, width: 1),
              ),
              child: const Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.emerald),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'جاري التحميل...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.charcoal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
