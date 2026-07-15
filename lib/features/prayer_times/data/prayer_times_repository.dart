import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/providers/firebase_providers.dart';
import 'prayer_times_model.dart';

/// Result returned by [PrayerTimesRepository.fetchAndCache].
class FetchResult {
  const FetchResult({required this.model, required this.fetchFailed});
  final PrayerTimesModel model;
  /// True when the Aladhan API call failed and we are showing cached data.
  final bool fetchFailed;
}

class PrayerTimesRepository {
  PrayerTimesRepository(this._firestore);

  final FirebaseFirestore _firestore;

  // ── Firestore paths ──────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _prayerTimesCol(String mosqueId) =>
      _firestore
          .collection('mosques')
          .doc(mosqueId)
          .collection('prayerTimes');

  DocumentReference<Map<String, dynamic>> _prayerTimesDoc(
    String mosqueId,
    String date,
  ) =>
      _prayerTimesCol(mosqueId).doc(date);

  // ── Public API ───────────────────────────────────────────────

  /// Streams a single day's document (null if it doesn't exist yet).
  Stream<PrayerTimesModel?> watchPrayerTimes(String mosqueId, String date) {
    return _prayerTimesDoc(mosqueId, date).snapshots().map((snap) {
      if (!snap.exists) return null;
      return PrayerTimesModel.fromFirestore(snap);
    });
  }

  /// Returns the cached Firestore document for [date], or null.
  Future<PrayerTimesModel?> getPrayerTimes(
    String mosqueId,
    String date,
  ) async {
    final snap = await _prayerTimesDoc(mosqueId, date).get();
    if (!snap.exists) return null;
    return PrayerTimesModel.fromFirestore(snap);
  }

  /// Writes [model] to Firestore (merge so we don't blow away other fields).
  Future<void> savePrayerTimes(
    String mosqueId,
    String date,
    PrayerTimesModel model,
  ) async {
    await _prayerTimesDoc(mosqueId, date).set(
      model.toFirestore(),
      SetOptions(merge: true),
    );
  }

  /// Saves only the manual-override + Jumu'a fields plus metadata.
  Future<void> saveManualOverrides({
    required String mosqueId,
    required String date,
    required Map<String, dynamic> fields,
    required String editorUid,
  }) async {
    await _prayerTimesDoc(mosqueId, date).set(
      {
        ...fields,
        'lastEditedBy': editorUid,
        'lastEditedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Updates the mosque document's `calculationMethod` field.
  Future<void> saveCalculationMethod(
    String mosqueId,
    int methodId,
  ) async {
    await _firestore.collection('mosques').doc(mosqueId).update({
      'calculationMethod': methodId,
    });
  }

  /// Updates the mosque document's `useAutoCalculation` field for a given date.
  Future<void> saveUseAutoCalculation(
    String mosqueId,
    String date,
    bool value,
  ) async {
    await _prayerTimesDoc(mosqueId, date).set(
      {'useAutoCalculation': value},
      SetOptions(merge: true),
    );
  }

  // ── Aladhan API ──────────────────────────────────────────────

  static const String _aladhanBase = 'https://api.aladhan.com/v1/timings';

  /// Fetches prayer times from the Aladhan API.
  /// [date] is YYYY-MM-DD.
  /// Returns a map with keys: Fajr, Dhuhr, Asr, Maghrib, Isha (HH:mm).
  Future<Map<String, String>> fetchFromAladhan({
    required double latitude,
    required double longitude,
    required String date, // YYYY-MM-DD
    required int methodId,
  }) async {
    // Aladhan expects DD-MM-YYYY
    final parts = date.split('-');
    final ddMmYyyy = '${parts[2]}-${parts[1]}-${parts[0]}';

    final uri = Uri.parse('$_aladhanBase/$ddMmYyyy').replace(
      queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'method': methodId.toString(),
      },
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Aladhan API error: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['code'] != 200) {
      throw Exception('Aladhan API returned code ${body['code']}');
    }

    final timings = body['data']['timings'] as Map<String, dynamic>;

    // Extract HH:mm (the API can return "05:14 (WIB)" – strip timezone suffix)
    String clean(String raw) => raw.trim().split(' ').first;

    return {
      'fajr': clean(timings['Fajr'] as String),
      'dhuhr': clean(timings['Dhuhr'] as String),
      'asr': clean(timings['Asr'] as String),
      'maghrib': clean(timings['Maghrib'] as String),
      'isha': clean(timings['Isha'] as String),
    };
  }

  // ── Fetch-and-cache ──────────────────────────────────────────

  /// Checks Firestore; if `lastFetchedAt` is today, returns cached data.
  /// Otherwise calls the Aladhan API and merges the results into Firestore.
  /// Manual overrides are preserved — they are never overwritten by the API.
  ///
  /// On any network/API error, returns the cached document with [fetchFailed]=true.
  Future<FetchResult> fetchAndCache({
    required String mosqueId,
    required String date,
    required GeoPoint geopoint,
    required int methodId,
  }) async {
    // 1. Read cached document
    final cached = await getPrayerTimes(mosqueId, date);

    // 2. Decide whether we need a fresh fetch
    final today = DateTime.now();
    final todayDate =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final cachedFetchedAt = cached?.lastFetchedAt;
    final alreadyFetchedToday = cachedFetchedAt != null &&
        _isSameDay(cachedFetchedAt, today) &&
        date == todayDate;

    if (alreadyFetchedToday) {
      return FetchResult(model: cached!, fetchFailed: false);
    }

    // 3. Fetch from API
    try {
      final apiTimes = await fetchFromAladhan(
        latitude: geopoint.latitude,
        longitude: geopoint.longitude,
        date: date,
        methodId: methodId,
      );

      final base = cached ?? PrayerTimesModel.empty(date);

      // Merge: API values go to the plain fields; overrides stay untouched.
      final merged = base.copyWith(
        fajr: apiTimes['fajr'],
        dhuhr: apiTimes['dhuhr'],
        asr: apiTimes['asr'],
        maghrib: apiTimes['maghrib'],
        isha: apiTimes['isha'],
        calculationMethod: methodId,
        lastFetchedAt: DateTime.now(),
      );

      await savePrayerTimes(mosqueId, date, merged);
      return FetchResult(model: merged, fetchFailed: false);
    } catch (_) {
      // Return whatever we have cached (even null → empty model)
      return FetchResult(
        model: cached ?? PrayerTimesModel.empty(date),
        fetchFailed: true,
      );
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Provider ─────────────────────────────────────────────────

final prayerTimesRepositoryProvider =
    Provider<PrayerTimesRepository>((ref) {
  return PrayerTimesRepository(ref.watch(firestoreProvider));
});
