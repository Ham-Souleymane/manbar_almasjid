import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../core/l10n/app_localizations.dart';

/// Card for صلاة الجمعة — always manual (Aladhan doesn't provide Jumu'a times).
class JumuaCard extends StatelessWidget {
  const JumuaCard({
    super.key,
    required this.khutbahTime,
    required this.prayerTime,
    required this.canEdit,
    this.onEditKhutbah,
    this.onEditPrayer,
  });

  final String? khutbahTime;
  final String? prayerTime;
  final bool canEdit;
  final VoidCallback? onEditKhutbah;
  final VoidCallback? onEditPrayer;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A5F), Color(0xFF2563EB)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.mosque_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.jumuah,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    l10n.alwaysManual,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 16),

            // Khutbah row
            _JumuaRow(
              label: l10n.jumuahKhutbah,
              time: khutbahTime,
              canEdit: canEdit,
              onEdit: onEditKhutbah,
            ),
            const SizedBox(height: 12),

            // Prayer row
            _JumuaRow(
              label: l10n.jumuahTime,
              time: prayerTime,
              canEdit: canEdit,
              onEdit: onEditPrayer,
            ),
          ],
        ),
      ),
    );
  }
}

class _JumuaRow extends StatelessWidget {
  const _JumuaRow({
    required this.label,
    required this.time,
    required this.canEdit,
    this.onEdit,
  });

  final String label;
  final String? time;
  final bool canEdit;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          time ?? '--:--',
          style: TextStyle(
            color: time != null ? Colors.white : Colors.white38,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (canEdit) ...[
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onEdit,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: Colors.white70,
                size: 16,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
