import 'package:flutter/material.dart';

/// A single prayer row: icon + Arabic name | time | [optional "معدّل يدوياً" chip] | pencil
class PrayerRowTile extends StatelessWidget {
  const PrayerRowTile({
    super.key,
    required this.prayerName,
    required this.time,
    required this.icon,
    required this.color,
    this.isOverridden = false,
    this.canEdit = true,
    this.onEdit,
  });

  final String prayerName;
  final String? time;
  final IconData icon;
  final Color color;
  final bool isOverridden;
  final bool canEdit;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: isOverridden
            ? Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.35), width: 1.2)
            : null,
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),

          // Prayer name + optional override badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prayerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                if (isOverridden) ...[
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'معدّل يدوياً',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Time
          Text(
            time ?? '--:--',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: time != null ? const Color(0xFF0F766E) : Colors.black26,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),

          // Edit pencil
          if (canEdit) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onEdit,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6F8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  size: 18,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
