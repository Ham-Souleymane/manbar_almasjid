import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/prayer_times_model.dart';
import '../data/prayer_times_repository.dart';

// ── Key type for the family ───────────────────────────────────

typedef PrayerTimesKey = ({
  String mosqueId,
  String date,
  GeoPoint geopoint,
});

// ── State ────────────────────────────────────────────────────

class PrayerTimesState {
  const PrayerTimesState({
    required this.model,
    this.isLoading = false,
    this.isSaving = false,
    this.fetchFailed = false,
    this.errorMessage,
    this.pendingFajr,
    this.pendingDhuhr,
    this.pendingAsr,
    this.pendingMaghrib,
    this.pendingIsha,
    this.pendingJumuaKhutbah,
    this.pendingJumuaPrayer,
  });

  final PrayerTimesModel model;
  final bool isLoading;
  final bool isSaving;
  final bool fetchFailed;
  final String? errorMessage;

  final String? pendingFajr;
  final String? pendingDhuhr;
  final String? pendingAsr;
  final String? pendingMaghrib;
  final String? pendingIsha;
  final String? pendingJumuaKhutbah;
  final String? pendingJumuaPrayer;

  bool get hasPendingChanges =>
      pendingFajr != null ||
      pendingDhuhr != null ||
      pendingAsr != null ||
      pendingMaghrib != null ||
      pendingIsha != null ||
      pendingJumuaKhutbah != null ||
      pendingJumuaPrayer != null;

  PrayerTimesState copyWith({
    PrayerTimesModel? model,
    bool? isLoading,
    bool? isSaving,
    bool? fetchFailed,
    String? errorMessage,
    String? pendingFajr,
    String? pendingDhuhr,
    String? pendingAsr,
    String? pendingMaghrib,
    String? pendingIsha,
    String? pendingJumuaKhutbah,
    String? pendingJumuaPrayer,
    bool clearPending = false,
    bool clearError = false,
  }) {
    return PrayerTimesState(
      model: model ?? this.model,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      fetchFailed: fetchFailed ?? this.fetchFailed,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      pendingFajr: clearPending ? null : (pendingFajr ?? this.pendingFajr),
      pendingDhuhr: clearPending ? null : (pendingDhuhr ?? this.pendingDhuhr),
      pendingAsr: clearPending ? null : (pendingAsr ?? this.pendingAsr),
      pendingMaghrib:
          clearPending ? null : (pendingMaghrib ?? this.pendingMaghrib),
      pendingIsha: clearPending ? null : (pendingIsha ?? this.pendingIsha),
      pendingJumuaKhutbah: clearPending
          ? null
          : (pendingJumuaKhutbah ?? this.pendingJumuaKhutbah),
      pendingJumuaPrayer:
          clearPending ? null : (pendingJumuaPrayer ?? this.pendingJumuaPrayer),
    );
  }
}

// ── Notifier ─────────────────────────────────────────────────

class PrayerTimesNotifier extends Notifier<PrayerTimesState> {
  PrayerTimesNotifier(this.arg);
  
  final PrayerTimesKey arg;
  late final PrayerTimesRepository _repo;

  @override
  PrayerTimesState build() {
    _repo = ref.watch(prayerTimesRepositoryProvider);
    return PrayerTimesState(
      model: PrayerTimesModel.empty(arg.date),
      isLoading: true,
    );
  }

  // ── Initialise (fetch + cache) ────────────────────────────

  Future<void> init(int methodId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repo.fetchAndCache(
      mosqueId: arg.mosqueId,
      date: arg.date,
      geopoint: arg.geopoint,
      methodId: methodId,
    );
    state = state.copyWith(
      model: result.model,
      isLoading: false,
      fetchFailed: result.fetchFailed,
    );
  }

  // ── Local edits ───────────────────────────────────────────

  void setPendingFajr(String v) => state = state.copyWith(pendingFajr: v);
  void setPendingDhuhr(String v) => state = state.copyWith(pendingDhuhr: v);
  void setPendingAsr(String v) => state = state.copyWith(pendingAsr: v);
  void setPendingMaghrib(String v) =>
      state = state.copyWith(pendingMaghrib: v);
  void setPendingIsha(String v) => state = state.copyWith(pendingIsha: v);
  void setPendingJumuaKhutbah(String v) =>
      state = state.copyWith(pendingJumuaKhutbah: v);
  void setPendingJumuaPrayer(String v) =>
      state = state.copyWith(pendingJumuaPrayer: v);

  // ── Toggle auto-calculation ───────────────────────────────

  Future<void> toggleAutoCalculation({
    required bool value,
    required String editorUid,
    required int methodId,
  }) async {
    await _repo.saveUseAutoCalculation(arg.mosqueId, arg.date, value);
    state = state.copyWith(model: state.model.copyWith(useAutoCalculation: value));
    if (value) await init(methodId);
  }

  // ── Save manual overrides ─────────────────────────────────

  Future<void> saveManualOverrides(String editorUid) async {
    state = state.copyWith(isSaving: true);
    final fields = <String, dynamic>{};

    if (state.model.useAutoCalculation) {
      if (state.pendingFajr != null) {
        fields['fajrOverride'] = state.pendingFajr;
      }
      if (state.pendingDhuhr != null) {
        fields['dhuhrOverride'] = state.pendingDhuhr;
      }
      if (state.pendingAsr != null) {
        fields['asrOverride'] = state.pendingAsr;
      }
      if (state.pendingMaghrib != null) {
        fields['maghribOverride'] = state.pendingMaghrib;
      }
      if (state.pendingIsha != null) {
        fields['ishaOverride'] = state.pendingIsha;
      }
    } else {
      if (state.pendingFajr != null) fields['fajr'] = state.pendingFajr;
      if (state.pendingDhuhr != null) fields['dhuhr'] = state.pendingDhuhr;
      if (state.pendingAsr != null) fields['asr'] = state.pendingAsr;
      if (state.pendingMaghrib != null) {
        fields['maghrib'] = state.pendingMaghrib;
      }
      if (state.pendingIsha != null) fields['isha'] = state.pendingIsha;
    }

    if (state.pendingJumuaKhutbah != null) {
      fields['jumuaKhutbahTime'] = state.pendingJumuaKhutbah;
    }
    if (state.pendingJumuaPrayer != null) {
      fields['jumuaPrayerTime'] = state.pendingJumuaPrayer;
    }

    if (fields.isEmpty) {
      state = state.copyWith(isSaving: false);
      return;
    }

    try {
      await _repo.saveManualOverrides(
        mosqueId: arg.mosqueId,
        date: arg.date,
        fields: fields,
        editorUid: editorUid,
      );
      final fresh = await _repo.getPrayerTimes(arg.mosqueId, arg.date);
      state = state.copyWith(
        model: fresh ?? state.model,
        isSaving: false,
        clearPending: true,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'فشل الحفظ: $e',
      );
    }
  }

  // ── Calculation method ────────────────────────────────────

  Future<void> changeCalculationMethod({
    required int methodId,
    required int oldMethodId,
  }) async {
    if (methodId == oldMethodId) return;
    await _repo.saveCalculationMethod(arg.mosqueId, methodId);
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repo.fetchAndCache(
      mosqueId: arg.mosqueId,
      date: arg.date,
      geopoint: arg.geopoint,
      methodId: methodId,
    );
    state = state.copyWith(
      model: result.model.copyWith(calculationMethod: methodId),
      isLoading: false,
      fetchFailed: result.fetchFailed,
    );
  }
}
