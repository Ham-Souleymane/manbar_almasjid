import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents the document at:
///   mosques/{mosqueId}/prayerTimes/{YYYY-MM-DD}
class PrayerTimesModel {
  const PrayerTimesModel({
    required this.date,
    this.fajr,
    this.dhuhr,
    this.asr,
    this.maghrib,
    this.isha,
    this.jumuaKhutbahTime,
    this.jumuaPrayerTime,
    // Overrides (set when imam manually edits a prayer while useAutoCalculation=true)
    this.fajrOverride,
    this.dhuhrOverride,
    this.asrOverride,
    this.maghribOverride,
    this.ishaOverride,
    required this.useAutoCalculation,
    required this.calculationMethod,
    this.lastEditedBy,
    this.lastEditedAt,
    this.lastFetchedAt,
  });

  final String date; // YYYY-MM-DD

  // API-fetched (or manual when useAutoCalculation=false) values – HH:mm
  final String? fajr;
  final String? dhuhr;
  final String? asr;
  final String? maghrib;
  final String? isha;

  // Always manual (Aladhan doesn't provide Jumu'a times)
  final String? jumuaKhutbahTime;
  final String? jumuaPrayerTime;

  // Per-prayer manual overrides (populated only when imam edits a specific prayer
  // while useAutoCalculation=true).
  final String? fajrOverride;
  final String? dhuhrOverride;
  final String? asrOverride;
  final String? maghribOverride;
  final String? ishaOverride;

  final bool useAutoCalculation;
  final int calculationMethod;

  final String? lastEditedBy;
  final DateTime? lastEditedAt;
  final DateTime? lastFetchedAt;

  // ── Convenience getters ──────────────────────────────────────

  /// The time to *display* for each prayer:
  /// override wins over API value when useAutoCalculation=true.
  String? get displayFajr => fajrOverride ?? fajr;
  String? get displayDhuhr => dhuhrOverride ?? dhuhr;
  String? get displayAsr => asrOverride ?? asr;
  String? get displayMaghrib => maghribOverride ?? maghrib;
  String? get displayIsha => ishaOverride ?? isha;

  bool get hasFajrOverride => fajrOverride != null;
  bool get hasDhuhrOverride => dhuhrOverride != null;
  bool get hasAsrOverride => asrOverride != null;
  bool get hasMaghribOverride => maghribOverride != null;
  bool get hasIshaOverride => ishaOverride != null;

  // ── Factories ────────────────────────────────────────────────

  factory PrayerTimesModel.empty(String date) => PrayerTimesModel(
        date: date,
        useAutoCalculation: true,
        calculationMethod: 4, // Umm al-Qura default
      );

  factory PrayerTimesModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    return PrayerTimesModel(
      date: doc.id,
      fajr: d['fajr'] as String?,
      dhuhr: d['dhuhr'] as String?,
      asr: d['asr'] as String?,
      maghrib: d['maghrib'] as String?,
      isha: d['isha'] as String?,
      jumuaKhutbahTime: d['jumuaKhutbahTime'] as String?,
      jumuaPrayerTime: d['jumuaPrayerTime'] as String?,
      fajrOverride: d['fajrOverride'] as String?,
      dhuhrOverride: d['dhuhrOverride'] as String?,
      asrOverride: d['asrOverride'] as String?,
      maghribOverride: d['maghribOverride'] as String?,
      ishaOverride: d['ishaOverride'] as String?,
      useAutoCalculation: d['useAutoCalculation'] as bool? ?? true,
      calculationMethod: d['calculationMethod'] as int? ?? 4,
      lastEditedBy: d['lastEditedBy'] as String?,
      lastEditedAt: (d['lastEditedAt'] as Timestamp?)?.toDate(),
      lastFetchedAt: (d['lastFetchedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (fajr != null) 'fajr': fajr,
      if (dhuhr != null) 'dhuhr': dhuhr,
      if (asr != null) 'asr': asr,
      if (maghrib != null) 'maghrib': maghrib,
      if (isha != null) 'isha': isha,
      if (jumuaKhutbahTime != null) 'jumuaKhutbahTime': jumuaKhutbahTime,
      if (jumuaPrayerTime != null) 'jumuaPrayerTime': jumuaPrayerTime,
      if (fajrOverride != null) 'fajrOverride': fajrOverride,
      if (dhuhrOverride != null) 'dhuhrOverride': dhuhrOverride,
      if (asrOverride != null) 'asrOverride': asrOverride,
      if (maghribOverride != null) 'maghribOverride': maghribOverride,
      if (ishaOverride != null) 'ishaOverride': ishaOverride,
      'useAutoCalculation': useAutoCalculation,
      'calculationMethod': calculationMethod,
      if (lastEditedBy != null) 'lastEditedBy': lastEditedBy,
      if (lastEditedAt != null)
        'lastEditedAt': Timestamp.fromDate(lastEditedAt!),
      if (lastFetchedAt != null)
        'lastFetchedAt': Timestamp.fromDate(lastFetchedAt!),
    };
  }

  PrayerTimesModel copyWith({
    String? fajr,
    String? dhuhr,
    String? asr,
    String? maghrib,
    String? isha,
    String? jumuaKhutbahTime,
    String? jumuaPrayerTime,
    String? fajrOverride,
    String? dhuhrOverride,
    String? asrOverride,
    String? maghribOverride,
    String? ishaOverride,
    bool? useAutoCalculation,
    int? calculationMethod,
    String? lastEditedBy,
    DateTime? lastEditedAt,
    DateTime? lastFetchedAt,
    // Sentinel to explicitly null override fields
    bool clearFajrOverride = false,
    bool clearDhuhrOverride = false,
    bool clearAsrOverride = false,
    bool clearMaghribOverride = false,
    bool clearIshaOverride = false,
  }) {
    return PrayerTimesModel(
      date: date,
      fajr: fajr ?? this.fajr,
      dhuhr: dhuhr ?? this.dhuhr,
      asr: asr ?? this.asr,
      maghrib: maghrib ?? this.maghrib,
      isha: isha ?? this.isha,
      jumuaKhutbahTime: jumuaKhutbahTime ?? this.jumuaKhutbahTime,
      jumuaPrayerTime: jumuaPrayerTime ?? this.jumuaPrayerTime,
      fajrOverride: clearFajrOverride ? null : (fajrOverride ?? this.fajrOverride),
      dhuhrOverride: clearDhuhrOverride ? null : (dhuhrOverride ?? this.dhuhrOverride),
      asrOverride: clearAsrOverride ? null : (asrOverride ?? this.asrOverride),
      maghribOverride: clearMaghribOverride ? null : (maghribOverride ?? this.maghribOverride),
      ishaOverride: clearIshaOverride ? null : (ishaOverride ?? this.ishaOverride),
      useAutoCalculation: useAutoCalculation ?? this.useAutoCalculation,
      calculationMethod: calculationMethod ?? this.calculationMethod,
      lastEditedBy: lastEditedBy ?? this.lastEditedBy,
      lastEditedAt: lastEditedAt ?? this.lastEditedAt,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
    );
  }
}
