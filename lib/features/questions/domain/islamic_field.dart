/// The 8 Islamic academic fields used for the "Ask the Sheikh" feature.
enum IslamicField {
  aqeedah(
    id: 'aqeedah',
    labelAr: 'العقيدة',
    labelEn: 'Aqeedah',
    icon: '📖',
    aliases: ['العقيدة', 'عقيدة', 'توحيد', 'التوحيد', 'aqeedah', 'tawheed'],
  ),
  fiqh(
    id: 'fiqh',
    labelAr: 'الفقه',
    labelEn: 'Fiqh',
    icon: '⚖️',
    aliases: [
      'الفقه',
      'فقه',
      'الفتاوى العامة',
      'فتاوى',
      'فتاوي',
      'fatwa',
      'fiqh',
      'المعاملات المالية',
      'الاستشارات الأسرية',
    ],
  ),
  muamalat(
    id: 'muamalat',
    labelAr: 'المعاملات',
    labelEn: 'Mu\'amalat',
    icon: '🤝',
    aliases: [
      'المعاملات',
      'المعاملات المالية',
      'معاملات',
      'معاملات مالية',
      'muamalat',
      'finance',
    ],
  ),
  history(
    id: 'history',
    labelAr: 'التاريخ و السير',
    labelEn: 'History & Seerah',
    icon: '📜',
    aliases: [
      'السيرة',
      'السيرة النبوية',
      'التاريخ',
      'التاريخ والسيرة',
      'التاريخ والسيرة النبوية',
      'التاريخ و السير',
      'history',
      'seerah',
    ],
  ),
  language(
    id: 'language',
    labelAr: 'اللغة',
    labelEn: 'Arabic Language',
    icon: '✍️',
    aliases: ['اللغة', 'اللغة العربية', 'لغة عربية', 'language', 'arabic'],
  ),
  hadith(
    id: 'hadith',
    labelAr: 'علم الحديث',
    labelEn: 'Hadith Sciences',
    icon: '📚',
    aliases: ['الحديث', 'علم الحديث', 'الحديث الشريف', 'hadith'],
  ),
  usul(
    id: 'usul',
    labelAr: 'أصول الفقه',
    labelEn: 'Usul al-Fiqh',
    icon: '🏛️',
    aliases: ['أصول الفقه', 'اصول الفقه', 'أصول', 'اصول', 'usul', 'usul_al_fiqh'],
  ),
  tafsir(
    id: 'tafsir',
    labelAr: 'التفسير و علومه',
    labelEn: 'Tafsir & Quranic Sciences',
    icon: '🌙',
    aliases: [
      'التفسير',
      'التفسير وعلومه',
      'التفسير و علومه',
      'القرآن والتجويد',
      'القرآن الكريم',
      'القرآن',
      'تفسير',
      'قرآن',
      'tafsir',
      'quran',
    ],
  );

  const IslamicField({
    required this.id,
    required this.labelAr,
    required this.labelEn,
    required this.icon,
    this.aliases = const [],
  });

  final String id;
  final String labelAr;
  final String labelEn;
  final String icon;
  final List<String> aliases;

  String label(bool isArabic) => isArabic ? labelAr : labelEn;

  /// Looks up an [IslamicField] by ID, Arabic label, or known alias.
  static IslamicField? fromId(dynamic id) {
    if (id == null) return null;
    final str = id.toString().trim();
    if (str.isEmpty) return null;
    final clean = str.toLowerCase();

    for (final f in values) {
      if (f.id.toLowerCase() == clean ||
          f.labelAr == str ||
          f.labelEn.toLowerCase() == clean) {
        return f;
      }
      for (final a in f.aliases) {
        if (a.toLowerCase() == clean || a == str) {
          return f;
        }
      }
    }
    return null;
  }

  /// Checks if a given field value matches the selected filter identifier.
  static bool matches(String? fieldVal, String? filterId) {
    if (filterId == null || filterId == 'all' || filterId.isEmpty) return true;
    if (fieldVal == null || fieldVal.trim().isEmpty) return false;

    final fVal = fieldVal.trim();
    if (fVal.toLowerCase() == filterId.trim().toLowerCase()) return true;

    final fieldEnum = fromId(fVal);
    final filterEnum = fromId(filterId);

    if (fieldEnum != null && filterEnum != null) {
      return fieldEnum == filterEnum;
    }
    if (fieldEnum != null) {
      return fieldEnum.id == filterId || fieldEnum.aliases.contains(filterId);
    }
    if (filterEnum != null) {
      return filterEnum.id == fVal || filterEnum.aliases.contains(fVal);
    }
    return false;
  }

  static String labelForId(dynamic id, {bool isArabic = true}) {
    if (id == null) return isArabic ? 'عام' : 'General';
    final str = id.toString().trim();
    if (str.isEmpty) return isArabic ? 'عام' : 'General';

    final field = fromId(str);
    if (field != null) return isArabic ? field.labelAr : field.labelEn;
    return str;
  }

  static List<String> get allIds => values.map((f) => f.id).toList();
}
