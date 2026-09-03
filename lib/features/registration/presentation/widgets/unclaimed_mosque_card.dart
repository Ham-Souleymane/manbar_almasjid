import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/mosque_model.dart';

class UnclaimedMosqueCard extends StatelessWidget {
  const UnclaimedMosqueCard({
    super.key,
    required this.mosque,
    required this.isSelected,
    required this.onSelect,
    this.distanceMeters,
  });

  final MosqueModel mosque;
  final bool isSelected;
  final VoidCallback onSelect;
  final double? distanceMeters;

  String? _formatDistance(BuildContext context, double meters) {
    final l10n = context.l10n;
    if (meters >= 1000) {
      final km = (meters / 1000).toStringAsFixed(1);
      return l10n.distanceKm(km);
    } else {
      return l10n.distanceMeters(meters.toStringAsFixed(0));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final distanceStr = distanceMeters != null
        ? _formatDistance(context, distanceMeters!)
        : null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.emerald : AppColors.grey300,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.emerald.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onSelect,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mosque Photo or Icon
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.emeraldPale,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: (mosque.photo != null && mosque.photo!.isNotEmpty)
                            ? Image.network(
                                mosque.photo!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.mosque_rounded,
                                  color: AppColors.emerald,
                                  size: 28,
                                ),
                              )
                            : const Icon(
                                Icons.mosque_rounded,
                                color: AppColors.emerald,
                                size: 28,
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Mosque Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  mosque.name,
                                  style: GoogleFonts.tajawal(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.emeraldDark,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.emerald,
                                  size: 22,
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: AppColors.grey500,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  mosque.city.isNotEmpty
                                      ? '${mosque.city} - ${mosque.address}'
                                      : mosque.address,
                                  style: GoogleFonts.tajawal(
                                    fontSize: 13,
                                    color: AppColors.grey700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.grey300),
                const SizedBox(height: 10),
                // Footer: Distance / AddedBy / Select Action
                Row(
                  children: [
                    if (distanceStr != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          color: AppColors.cream,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.near_me_outlined,
                              size: 12,
                              color: AppColors.emerald,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              distanceStr,
                              style: GoogleFonts.tajawal(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.emeraldDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (mosque.addedBy != null && mosque.addedBy!.isNotEmpty)
                      Expanded(
                        child: Text(
                          '${l10n.addedByWorshipper} (${mosque.addedBy})',
                          style: GoogleFonts.tajawal(
                            fontSize: 11,
                            color: AppColors.grey500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    else
                      Expanded(
                        child: Text(
                          l10n.addedByWorshipper,
                          style: GoogleFonts.tajawal(
                            fontSize: 11,
                            color: AppColors.grey500,
                          ),
                        ),
                      ),
                    ElevatedButton(
                      onPressed: onSelect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected
                            ? AppColors.emerald
                            : AppColors.emeraldPale,
                        foregroundColor: isSelected
                            ? Colors.white
                            : AppColors.emeraldDark,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        minimumSize: const Size(0, 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        isSelected ? l10n.confirmClaim : l10n.claimMosque,
                        style: GoogleFonts.tajawal(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
