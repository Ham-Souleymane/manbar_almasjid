import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';
import '../../../shared/widgets/app_button.dart';
import '../data/registration_repository.dart';

class UnderReviewScreen extends ConsumerWidget {
  const UnderReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imamAsync = ref.watch(currentImamProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.goldPale,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  size: 48,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'قيد المراجعة',
                style: GoogleFonts.tajawal(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.emeraldDark,
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 16),
              Text(
                'تم استلام طلبك بنجاح. سيتم مراجعة بياناتك والموافقة عليها قريباً.',
                style: GoogleFonts.tajawal(
                  fontSize: 15,
                  color: AppColors.grey500,
                  height: 1.6,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
              if (imamAsync.asData?.value != null) ...[
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: [
                      Text(
                        imamAsync.asData!.value!.fullName,
                        style: GoogleFonts.tajawal(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.charcoal,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        imamAsync.asData!.value!.email,
                        style: GoogleFonts.tajawal(
                          fontSize: 13,
                          color: AppColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 48),
              AppButton(
                label: 'تسجيل الخروج',
                style: AppButtonStyle.secondary,
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
