import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../application/registration_controller.dart';
import 'widgets/registration_progress_indicator.dart';

class AskFeatureSetupScreen extends ConsumerStatefulWidget {
  const AskFeatureSetupScreen({super.key});

  @override
  ConsumerState<AskFeatureSetupScreen> createState() =>
      _AskFeatureSetupScreenState();
}

class _AskFeatureSetupScreenState extends ConsumerState<AskFeatureSetupScreen> {
  final _bioController = TextEditingController();
  final _responseTimeController = TextEditingController();
  final _customSpecialtyController = TextEditingController();

  bool _acceptingQuestions = true;
  bool _allowPrivateQuestions = true;
  final Set<String> _selectedSpecialties = {
    'الفقه',
    'القرآن والتجويد',
    'العقيدة',
    'الاستشارات الأسرية',
  };

  static const List<String> _defaultSpecialties = [
    'الفقه',
    'العقيدة',
    'التفسير وعلومه',
    'الحديث الشريف',
    'القرآن والتجويد',
    'أصول الفقه',
    'المعاملات المالية',
    'الاستشارات الأسرية',
    'التاريخ والسيرة النبوية',
    'اللغة العربية',
    'الفتاوى العامة',
  ];

  static const List<String> _quickResponsePresets = [
    'خلال 24 ساعة',
    'خلال 24-48 ساعة',
    'يومياً بعد صلاة العصر',
    'يومياً بعد صلاة المغرب',
    'خلال عطلة نهاية الأسبوع',
  ];

  @override
  void initState() {
    super.initState();
    final regState = ref.read(registrationControllerProvider);
    _acceptingQuestions = regState.acceptingQuestions;
    _allowPrivateQuestions = regState.allowPrivateQuestions;
    if (regState.specialties.isNotEmpty) {
      _selectedSpecialties.clear();
      _selectedSpecialties.addAll(regState.specialties);
    }
    if (regState.bio.isNotEmpty) _bioController.text = regState.bio;
    if (regState.responseTime.isNotEmpty) {
      _responseTimeController.text = regState.responseTime;
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    _responseTimeController.dispose();
    _customSpecialtyController.dispose();
    super.dispose();
  }

  void _toggleSpecialty(String specialty) {
    setState(() {
      if (_selectedSpecialties.contains(specialty)) {
        _selectedSpecialties.remove(specialty);
      } else {
        _selectedSpecialties.add(specialty);
      }
    });
  }

  void _addCustomSpecialty() {
    final text = _customSpecialtyController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _selectedSpecialties.add(text);
        _customSpecialtyController.clear();
      });
    }
  }

  Future<void> _submit() async {
    final l10n = context.l10n;

    if (_acceptingQuestions && _selectedSpecialties.isEmpty) {
      context.showSnackBar(l10n.selectAtLeastOneSpecialty, isError: true);
      return;
    }

    ref.read(registrationControllerProvider.notifier).setAskFeatureFields(
          acceptingQuestions: _acceptingQuestions,
          specialties: _selectedSpecialties.toList(),
          bio: _bioController.text.trim(),
          responseTime: _responseTimeController.text.trim(),
          allowPrivateQuestions: _allowPrivateQuestions,
        );

    final success = await ref
        .read(registrationControllerProvider.notifier)
        .submitRegistration();

    if (!mounted) return;
    if (success) {
      // All registration paths set imam status to verified immediately —
      // no admin approval required. Go straight to home.
      context.go(AppRoutes.home);
    } else {
      final error = ref.read(registrationControllerProvider).errorMessage;
      context.showSnackBar(error ?? l10n.anErrorOccurred, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final regState = ref.watch(registrationControllerProvider);

    return LoadingOverlay(
      isLoading: regState.isSubmitting,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          title: Text(l10n.askFeatureSettings),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              final regState = ref.read(registrationControllerProvider);
              if (regState.hasMosque == false) {
                context.go(AppRoutes.registerImam);
              } else {
                context.go(AppRoutes.registerMosque);
              }
            },
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RegistrationProgressIndicator(
                  currentStep: regState.hasMosque == false ? 2 : 3,
                  totalSteps: regState.hasMosque == false ? 2 : 3,
                  stepTitle: l10n.askFeatureSettings,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.askFeatureSettings,
                  style: GoogleFonts.tajawal(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.emeraldDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.askFeatureSetupSubtitle,
                  style: GoogleFonts.tajawal(
                    fontSize: 14,
                    color: AppColors.grey700,
                  ),
                ),
                const SizedBox(height: 24),

                // 1. Questions Availability Switch Card
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  color: Colors.white,
                  elevation: 0.5,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _acceptingQuestions
                                    ? AppColors.emeraldPale
                                    : AppColors.grey100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _acceptingQuestions
                                    ? Icons.question_answer_rounded
                                    : Icons.comments_disabled_outlined,
                                color: _acceptingQuestions
                                    ? AppColors.emerald
                                    : AppColors.grey500,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.acceptingQuestions,
                                    style: GoogleFonts.tajawal(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.charcoal,
                                    ),
                                  ),
                                  Text(
                                    l10n.acceptingQuestionsSubtitle,
                                    style: GoogleFonts.tajawal(
                                      fontSize: 12,
                                      color: AppColors.grey500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _acceptingQuestions,
                              activeThumbColor: AppColors.emerald,
                              onChanged: (val) =>
                                  setState(() => _acceptingQuestions = val),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Specialties / Topics Selection
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  color: Colors.white,
                  elevation: 0.5,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.school_outlined,
                                color: AppColors.emerald, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              l10n.imamSpecialties,
                              style: GoogleFonts.tajawal(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.charcoal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.imamSpecialtiesSubtitle,
                          style: GoogleFonts.tajawal(
                            fontSize: 12,
                            color: AppColors.grey500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _defaultSpecialties.map((spec) {
                            final isSelected =
                                _selectedSpecialties.contains(spec);
                            return FilterChip(
                              label: Text(spec),
                              selected: isSelected,
                              onSelected: (_) => _toggleSpecialty(spec),
                              selectedColor: AppColors.emeraldPale,
                              checkmarkColor: AppColors.emerald,
                              labelStyle: GoogleFonts.tajawal(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.emeraldDark
                                    : AppColors.grey700,
                              ),
                              backgroundColor: AppColors.grey100,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.emerald
                                      : Colors.transparent,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        // Add custom topic
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _customSpecialtyController,
                                decoration: InputDecoration(
                                  hintText: 'إضافة تخصص أو مجال آخر...',
                                  hintStyle: GoogleFonts.tajawal(fontSize: 13),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                        color: AppColors.grey300),
                                  ),
                                ),
                                onSubmitted: (_) => _addCustomSpecialty(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _addCustomSpecialty,
                              icon: const Icon(Icons.add_circle,
                                  color: AppColors.emerald, size: 28),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Bio & Qualifications
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  color: Colors.white,
                  elevation: 0.5,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.badge_outlined,
                                color: AppColors.emerald, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              l10n.imamBio,
                              style: GoogleFonts.tajawal(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.charcoal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _bioController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: l10n.imamBioHint,
                            hintStyle: GoogleFonts.tajawal(
                                fontSize: 13, color: AppColors.grey500),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: AppColors.grey300),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 4. Response Time & Availability
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  color: Colors.white,
                  elevation: 0.5,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded,
                                color: AppColors.emerald, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              l10n.responseTime,
                              style: GoogleFonts.tajawal(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.charcoal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Quick Presets
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _quickResponsePresets.map((preset) {
                            final isSelected =
                                _responseTimeController.text == preset;
                            return ActionChip(
                              label: Text(preset),
                              onPressed: () {
                                setState(() {
                                  _responseTimeController.text = preset;
                                });
                              },
                              backgroundColor: isSelected
                                  ? AppColors.emeraldPale
                                  : AppColors.grey100,
                              labelStyle: GoogleFonts.tajawal(
                                fontSize: 12,
                                color: isSelected
                                    ? AppColors.emeraldDark
                                    : AppColors.grey700,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.emerald
                                      : Colors.transparent,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _responseTimeController,
                          decoration: InputDecoration(
                            hintText: l10n.responseTimeHint,
                            hintStyle: GoogleFonts.tajawal(
                                fontSize: 13, color: AppColors.grey500),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: AppColors.grey300),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 5. Private Consultations Toggle Card
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  color: Colors.white,
                  elevation: 0.5,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _allowPrivateQuestions
                                ? AppColors.goldPale
                                : AppColors.grey100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.lock_outline_rounded,
                            color: _allowPrivateQuestions
                                ? AppColors.gold
                                : AppColors.grey500,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.allowPrivateQuestions,
                                style: GoogleFonts.tajawal(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.charcoal,
                                ),
                              ),
                              Text(
                                l10n.allowPrivateQuestionsSubtitle,
                                style: GoogleFonts.tajawal(
                                  fontSize: 12,
                                  color: AppColors.grey500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _allowPrivateQuestions,
                          activeThumbColor: AppColors.gold,
                          onChanged: (val) =>
                              setState(() => _allowPrivateQuestions = val),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Complete Registration Button
                AppButton(
                  label: l10n.completeRegistration,
                  isLoading: regState.isSubmitting,
                  onPressed: regState.isSubmitting ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
