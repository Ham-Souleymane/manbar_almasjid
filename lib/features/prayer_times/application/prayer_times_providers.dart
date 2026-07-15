import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'prayer_times_notifier.dart';

export 'prayer_times_notifier.dart';

// ── Family provider keyed by PrayerTimesKey ──────────────────

final prayerTimesNotifierProvider = NotifierProvider.autoDispose
    .family<PrayerTimesNotifier, PrayerTimesState, PrayerTimesKey>(
  PrayerTimesNotifier.new,
);
