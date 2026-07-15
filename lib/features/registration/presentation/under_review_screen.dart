import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_controller.dart';
import '../../../shared/widgets/app_button.dart';
import '../data/registration_repository.dart';
import '../domain/imam_status.dart';

class UnderReviewScreen extends ConsumerWidget {
  const UnderReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imamAsync = ref.watch(currentImamProvider);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: imamAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.emeraldDark),
            ),
            error: (e, _) => Center(child: Text('${l10n.error}: $e')),
            data: (imam) {
              final isBlocked = imam?.status == ImamStatus.blocked;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: isBlocked ? Colors.red.shade50 : AppColors.goldPale,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isBlocked
                            ? Colors.red.withValues(alpha: 0.4)
                            : AppColors.gold.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Icon(
                      isBlocked ? Icons.block_flipped : Icons.hourglass_top_rounded,
                      size: 48,
                      color: isBlocked ? Colors.red.shade700 : AppColors.gold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    isBlocked ? l10n.accountBlocked : l10n.underReview,
                    style: GoogleFonts.tajawal(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: isBlocked ? Colors.red.shade800 : AppColors.emeraldDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isBlocked ? l10n.accountBlockedMessage : l10n.underReviewMessage,
                    style: GoogleFonts.tajawal(
                      fontSize: 15,
                      color: AppColors.grey500,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (imam != null) ...[
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
                            imam.fullName,
                            style: GoogleFonts.tajawal(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.charcoal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            imam.email,
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
                    label: l10n.logout,
                    style: AppButtonStyle.secondary,
                    onPressed: () =>
                        ref.read(authControllerProvider.notifier).signOut(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
