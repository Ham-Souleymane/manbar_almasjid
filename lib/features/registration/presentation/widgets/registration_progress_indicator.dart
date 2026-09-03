import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

class RegistrationProgressIndicator extends StatelessWidget {
  const RegistrationProgressIndicator({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
    this.stepTitle,
  });

  final int currentStep;
  final int totalSteps;
  final String? stepTitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: List.generate(totalSteps, (index) {
            final step = index + 1;
            final isActive = step <= currentStep;

            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 4,
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.emerald : AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  if (index < totalSteps - 1) const SizedBox(width: 8),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (stepTitle != null)
              Text(
                stepTitle!,
                style: GoogleFonts.tajawal(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.emeraldDark,
                ),
              )
            else
              const SizedBox.shrink(),
            Text(
              'الخطوة $currentStep من $totalSteps',
              style: GoogleFonts.tajawal(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.grey500,
              ),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ],
    );
  }
}
