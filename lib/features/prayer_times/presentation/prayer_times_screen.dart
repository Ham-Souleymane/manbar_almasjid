import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/l10n/app_localizations.dart';
import '../../registration/data/registration_repository.dart';
import '../../registration/domain/mosque_model.dart';
import '../application/prayer_times_providers.dart';
import '../data/prayer_times_model.dart';
import '../widgets/calculation_method_sheet.dart';
import '../widgets/jumua_card.dart';
import '../widgets/prayer_row_tile.dart';

// ── Helpers ──────────────────────────────────────────────────

String _todayDate() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

String _formatTimeOfDay(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

TimeOfDay _parseTime(String? hhmm) {
  if (hhmm == null) return TimeOfDay.now();
  final parts = hhmm.split(':');
  return TimeOfDay(
    hour: int.tryParse(parts[0]) ?? 0,
    minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
  );
}

String _formatDate(Locale locale) {
  final now = DateTime.now();
  return DateFormat('EEEE, d MMMM y', locale.languageCode).format(now);
}

String _methodName(int id, Locale locale) {
  try {
    final m = CalculationMethodSheet.methods.firstWhere((item) => item.id == id);
    return locale.languageCode == 'en' ? m.nameEn : m.nameAr;
  } catch (_) {
    return locale.languageCode == 'en' ? 'Not set' : 'غير محدد';
  }
}

// ── Screen ────────────────────────────────────────────────────

class PrayerTimesScreen extends ConsumerStatefulWidget {
  const PrayerTimesScreen({super.key, required this.mosqueId});

  final String mosqueId;

  @override
  ConsumerState<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends ConsumerState<PrayerTimesScreen> {
  late final String _date;
  bool _initTriggered = false;

  @override
  void initState() {
    super.initState();
    _date = _todayDate();
  }

  // ── Build the provider key once we have the mosque ───────────

  PrayerTimesKey _key(MosqueModel mosque) => (
        mosqueId: widget.mosqueId,
        date: _date,
        geopoint: mosque.geopoint,
      );

  PrayerTimesNotifier _notifier(MosqueModel mosque) =>
      ref.read(prayerTimesNotifierProvider(_key(mosque)).notifier);

  PrayerTimesState _ptState(MosqueModel mosque) =>
      ref.watch(prayerTimesNotifierProvider(_key(mosque)));

  // ── Time picker helper ───────────────────────────────────────

  Future<void> _pickTime({
    required BuildContext ctx,
    required String? currentValue,
    required void Function(String hhmm) onPicked,
  }) async {
    final initial = _parseTime(currentValue);
    final picked = await showTimePicker(
      context: ctx,
      initialTime: initial,
    );
    if (picked != null) onPicked(_formatTimeOfDay(picked));
  }

  // ── build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mosqueAsync = ref.watch(currentMosqueProvider);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Color(0xFF111827), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.prayerTimes,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        centerTitle: true,
      ),
      body: mosqueAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${l10n.error}: $e')),
        data: (mosque) {
          if (mosque == null) {
            return Center(
                child: Text(l10n.mosqueDataNotFound));
          }

          // Trigger init exactly once after the first frame
          if (!_initTriggered) {
            _initTriggered = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _notifier(mosque).init(mosque.calculationMethod);
            });
          }

          return _buildBody(context, mosque, l10n);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, MosqueModel mosque, AppLocalizations l10n) {
    final pState = _ptState(mosque);
    final model = pState.model;
    final editorUid = ref.watch(currentImamProvider).asData?.value?.id ?? '';
    final isAuto = model.useAutoCalculation;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          children: [
            _buildHeader(context, mosque),
            const SizedBox(height: 16),

            if (pState.fetchFailed) _buildFetchFailedBanner(l10n),
            if (pState.fetchFailed) const SizedBox(height: 12),

            if (pState.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: Color(0xFF0F766E)),
                ),
              )
            else ...[
              _buildAutoCalcToggle(
                mosque: mosque,
                isAuto: isAuto,
                editorUid: editorUid,
                l10n: l10n,
              ),
              const SizedBox(height: 12),
              _buildMethodRow(context, mosque, l10n),
              const SizedBox(height: 20),
              _buildPrayerRows(context, mosque, model, pState, isAuto, l10n),
              const SizedBox(height: 20),
              _buildJumuaSection(context, mosque, model, pState),
            ],
          ],
        ),

        // Floating save button
        if (!pState.isLoading && pState.hasPendingChanges)
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: _buildSaveButton(mosque, editorUid, pState, l10n),
          ),
      ],
    );
  }

  // ── Sub-widgets ───────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, MosqueModel mosque) {
    final locale = Localizations.localeOf(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D5F59), Color(0xFF0F766E)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time_filled_rounded,
              color: Colors.white70, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mosque.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(locale),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFetchFailedBanner(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Color(0xFFD97706), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.fetchFailedBanner,
              style: const TextStyle(fontSize: 13, color: Color(0xFF92400E)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoCalcToggle({
    required MosqueModel mosque,
    required bool isAuto,
    required String editorUid,
    required AppLocalizations l10n,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F766E).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Color(0xFF0F766E), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.useAutoCalculation,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827)),
                ),
                Text(
                  l10n.autoCalculationSubtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ],
            ),
          ),
          Switch(
            value: isAuto,
            activeTrackColor: const Color(0xFF0F766E),
            onChanged: (v) => _notifier(mosque).toggleAutoCalculation(
              value: v,
              editorUid: editorUid,
              methodId: mosque.calculationMethod,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodRow(BuildContext context, MosqueModel mosque, AppLocalizations l10n) {
    final locale = Localizations.localeOf(context);
    return GestureDetector(
      onTap: () {
        CalculationMethodSheet.show(
          context: context,
          currentMethodId: mosque.calculationMethod,
          onSelected: (id, _) => _notifier(mosque).changeCalculationMethod(
            methodId: id,
            oldMethodId: mosque.calculationMethod,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF9333EA).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.calculate_rounded,
                  color: Color(0xFF9333EA), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.calculationMethod,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _methodName(mosque.calculationMethod, locale),
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.black38),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerRows(
    BuildContext context,
    MosqueModel mosque,
    PrayerTimesModel model,
    PrayerTimesState pState,
    bool isAuto,
    AppLocalizations l10n,
  ) {
    final prayers = [
      (
        name: l10n.fajr,
        icon: Icons.brightness_3_rounded,
        color: const Color(0xFF6366F1),
        display: pState.pendingFajr ?? model.displayFajr,
        isOverridden: model.hasFajrOverride,
        onEdit: (String t) => _notifier(mosque).setPendingFajr(t),
      ),
      (
        name: l10n.dhuhr,
        icon: Icons.wb_sunny_rounded,
        color: const Color(0xFFDB6A26),
        display: pState.pendingDhuhr ?? model.displayDhuhr,
        isOverridden: model.hasDhuhrOverride,
        onEdit: (String t) => _notifier(mosque).setPendingDhuhr(t),
      ),
      (
        name: l10n.asr,
        icon: Icons.wb_cloudy_rounded,
        color: const Color(0xFFF59E0B),
        display: pState.pendingAsr ?? model.displayAsr,
        isOverridden: model.hasAsrOverride,
        onEdit: (String t) => _notifier(mosque).setPendingAsr(t),
      ),
      (
        name: l10n.maghrib,
        icon: Icons.bedtime_rounded,
        color: const Color(0xFFEC4899),
        display: pState.pendingMaghrib ?? model.displayMaghrib,
        isOverridden: model.hasMaghribOverride,
        onEdit: (String t) => _notifier(mosque).setPendingMaghrib(t),
      ),
      (
        name: l10n.isha,
        icon: Icons.nights_stay_rounded,
        color: const Color(0xFF0F766E),
        display: pState.pendingIsha ?? model.displayIsha,
        isOverridden: model.hasIshaOverride,
        onEdit: (String t) => _notifier(mosque).setPendingIsha(t),
      ),
    ];

    return Column(
      children: prayers
          .map(
            (p) => PrayerRowTile(
              prayerName: p.name,
              time: p.display,
              icon: p.icon,
              color: p.color,
              isOverridden: isAuto && p.isOverridden,
              canEdit: true,
              onEdit: () => _pickTime(
                ctx: context,
                currentValue: p.display,
                onPicked: p.onEdit,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildJumuaSection(
    BuildContext context,
    MosqueModel mosque,
    PrayerTimesModel model,
    PrayerTimesState pState,
  ) {
    return JumuaCard(
      khutbahTime: pState.pendingJumuaKhutbah ?? model.jumuaKhutbahTime,
      prayerTime: pState.pendingJumuaPrayer ?? model.jumuaPrayerTime,
      canEdit: true,
      onEditKhutbah: () => _pickTime(
        ctx: context,
        currentValue: pState.pendingJumuaKhutbah ?? model.jumuaKhutbahTime,
        onPicked: _notifier(mosque).setPendingJumuaKhutbah,
      ),
      onEditPrayer: () => _pickTime(
        ctx: context,
        currentValue: pState.pendingJumuaPrayer ?? model.jumuaPrayerTime,
        onPicked: _notifier(mosque).setPendingJumuaPrayer,
      ),
    );
  }

  Widget _buildSaveButton(
    MosqueModel mosque,
    String editorUid,
    PrayerTimesState pState,
    AppLocalizations l10n,
  ) {
    return ElevatedButton.icon(
      onPressed: pState.isSaving
          ? null
          : () => _notifier(mosque).saveManualOverrides(editorUid),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        shadowColor: const Color(0xFF0F766E).withValues(alpha: 0.3),
      ),
      icon: pState.isSaving
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.save_rounded, size: 20),
      label: Text(
        pState.isSaving ? l10n.saving : l10n.saveChanges,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
