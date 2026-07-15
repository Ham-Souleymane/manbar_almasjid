import 'package:flutter/material.dart';

import '../../../core/l10n/app_localizations.dart';

/// Bottom sheet for selecting the Aladhan calculation method.
class CalculationMethodSheet extends StatelessWidget {
  const CalculationMethodSheet({
    super.key,
    required this.currentMethodId,
    required this.onSelected,
  });

  final int currentMethodId;
  final void Function(int methodId, String methodName) onSelected;

  static const List<({int id, String nameAr, String nameEn})> methods = [
    (id: 1, nameAr: 'جامعة العلوم الإسلامية – كراتشي', nameEn: 'University of Islamic Sciences, Karachi'),
    (id: 2, nameAr: 'الجمعية الإسلامية لأمريكا الشمالية (ISNA)', nameEn: 'Islamic Society of North America'),
    (id: 3, nameAr: 'رابطة العالم الإسلامي', nameEn: 'Muslim World League'),
    (id: 4, nameAr: 'أم القرى – مكة المكرمة', nameEn: 'Umm al-Qura, Makkah'),
    (id: 5, nameAr: 'الهيئة المصرية العامة للمساحة', nameEn: 'Egyptian General Authority'),
    (id: 7, nameAr: 'معهد الجيوفيزياء – جامعة طهران', nameEn: 'Institute of Geophysics, Tehran'),
    (id: 8, nameAr: 'منطقة الخليج', nameEn: 'Gulf Region'),
    (id: 9, nameAr: 'الكويت', nameEn: 'Kuwait'),
    (id: 10, nameAr: 'قطر', nameEn: 'Qatar'),
    (id: 11, nameAr: 'مجلس أوغاما إسلام سنغافورة', nameEn: 'Majlis Ugama Islam Singapura'),
    (id: 12, nameAr: 'الاتحاد الإسلامي الفرنسي', nameEn: 'Union Organisation Islamique de France'),
    (id: 13, nameAr: 'رئاسة الشؤون الدينية التركية', nameEn: 'Diyanet İşleri Başkanlığı'),
    (id: 14, nameAr: 'الإدارة الروحية لمسلمي روسيا', nameEn: 'Spiritual Administration of Muslims of Russia'),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.calculate_rounded, color: Color(0xFF0F766E)),
                const SizedBox(width: 10),
                Text(
                  l10n.calculationMethod,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),

          // Method list
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: methods.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 20, endIndent: 20, color: Color(0xFFF3F4F6)),
              itemBuilder: (context, index) {
                final m = methods[index];
                final isSelected = m.id == currentMethodId;
                return ListTile(
                  onTap: () {
                    onSelected(m.id, m.nameAr);
                    Navigator.of(context).pop();
                  },
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 4),
                  title: Text(
                    isEnglish ? m.nameEn : m.nameAr,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? const Color(0xFF0F766E)
                          : const Color(0xFF374151),
                    ),
                  ),
                  subtitle: Text(
                    isEnglish ? m.nameAr : m.nameEn,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black45),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF0F766E), size: 22)
                      : null,
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Shows the sheet and returns the selected method id or null.
  static Future<void> show({
    required BuildContext context,
    required int currentMethodId,
    required void Function(int methodId, String methodName) onSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CalculationMethodSheet(
        currentMethodId: currentMethodId,
        onSelected: onSelected,
      ),
    );
  }
}
