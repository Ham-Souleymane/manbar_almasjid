import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/questions_repository.dart';
import '../../domain/islamic_field.dart';

class OnboardingFieldsSheet extends ConsumerStatefulWidget {
  final String imamId;
  final List<String> initialFields;

  const OnboardingFieldsSheet({
    super.key,
    required this.imamId,
    this.initialFields = const [],
  });

  @override
  ConsumerState<OnboardingFieldsSheet> createState() =>
      _OnboardingFieldsSheetState();
}

class _OnboardingFieldsSheetState extends ConsumerState<OnboardingFieldsSheet> {
  late Set<String> _selectedFields;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedFields = Set.from(widget.initialFields);
  }

  void _toggleField(String id) {
    setState(() {
      if (_selectedFields.contains(id)) {
        _selectedFields.remove(id);
      } else {
        _selectedFields.add(id);
      }
    });
  }

  Future<void> _save() async {
    if (_selectedFields.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار تخصص واحد على الأقل'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref
          .read(questionsRepositoryProvider)
          .updateImamSpecializationFields(
            imamId: widget.imamId,
            fields: _selectedFields.toList(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ التخصصات بنجاح ✅'),
            backgroundColor: Color(0xFF003527),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل الحفظ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'مجالات التخصص العلمي',
            style: GoogleFonts.tajawal(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF003527),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'اختر المجالات التي ترغب في استقبال أسئلة المصلين حولها:',
            style: GoogleFonts.tajawal(
              fontSize: 13,
              color: const Color(0xFF404944),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: IslamicField.values.map((f) {
              final isSelected = _selectedFields.contains(f.id);
              return FilterChip(
                label: Text('${f.icon} ${f.labelAr}'),
                selected: isSelected,
                onSelected: (_) => _toggleField(f.id),
                selectedColor: const Color(0xFF003527),
                checkmarkColor: Colors.white,
                backgroundColor: const Color(0xFFE2E8F8),
                labelStyle: GoogleFonts.tajawal(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF404944),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003527),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'حفظ ومتابعة',
                      style: GoogleFonts.tajawal(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
