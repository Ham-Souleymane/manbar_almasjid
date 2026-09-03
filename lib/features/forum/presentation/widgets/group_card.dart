import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../domain/imam_group_model.dart';

class GroupCard extends StatelessWidget {
  const GroupCard({
    super.key,
    required this.group,
    required this.isMember,
    required this.isAdmin,
    required this.onTap,
    required this.onActionPressed,
    this.onEdit,
    this.onDelete,
    this.isLoading = false,
  });

  final ImamGroupModel group;
  final bool isMember;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback onActionPressed;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isLoading;

  IconData _resolveIcon(String iconName) {
    switch (iconName) {
      case 'library_books':
        return Icons.library_books_rounded;
      case 'public':
        return Icons.public_rounded;
      case 'mosque':
        return Icons.mosque_rounded;
      case 'auto_stories':
        return Icons.auto_stories_rounded;
      case 'record_voice_over':
        return Icons.record_voice_over_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'psychology':
        return Icons.psychology_rounded;
      case 'menu_book':
      default:
        return Icons.menu_book_rounded;
    }
  }

  Map<String, Color> _resolveColors(String colorKey) {
    switch (colorKey) {
      case 'amber':
        return {
          'bg': const Color(0xFFFFE0B2),
          'icon': const Color(0xFF623C00),
        };
      case 'teal':
        return {
          'bg': const Color(0xFFD4EFE5),
          'icon': const Color(0xFF2B6954),
        };
      case 'green':
      case 'emerald':
        return {
          'bg': const Color(0xFFC3ECD7),
          'icon': const Color(0xFF064E3B),
        };
      case 'gold':
        return {
          'bg': const Color(0xFFFEF3C7),
          'icon': const Color(0xFF92400E),
        };
      case 'purple':
        return {
          'bg': const Color(0xFFF3E8FF),
          'icon': const Color(0xFF6B21A8),
        };
      default:
        return {
          'bg': const Color(0xFFC3ECD7),
          'icon': const Color(0xFF064E3B),
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = _resolveColors(group.colorKey);
    final iconData = _resolveIcon(group.iconName);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Icon + Count Badge + Admin Options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme['bg'],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    iconData,
                    color: colorScheme['icon'],
                    size: 24,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F3FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.group_rounded,
                            size: 14,
                            color: Color(0xFF003527),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatCount(group.membersCount),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF003527),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded,
                            size: 20, color: Colors.grey),
                        onSelected: (val) {
                          if (val == 'edit') onEdit?.call();
                          if (val == 'delete') onDelete?.call();
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_rounded, size: 18),
                                SizedBox(width: 8),
                                Text('تعديل المجموعة'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded,
                                    size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('حذف المجموعة',
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Title
            Text(
              group.name,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF151C27),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),

            // Description & Last Message Preview
            Expanded(
              child: (group.lastMessageText != null &&
                      group.lastMessageText!.isNotEmpty)
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.description,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF404944),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.chat_bubble_outline_rounded,
                                size: 12, color: Color(0xFF0F766E)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${group.lastMessageSender != null ? "${group.lastMessageSender}: " : ""}${group.lastMessageText}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F766E),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Text(
                      group.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF404944),
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
            const SizedBox(height: 16),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: _buildActionButton(l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(AppLocalizations l10n) {
    if (isLoading) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF003527),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
      );
    }

    if (isMember) {
      return ElevatedButton.icon(
        onPressed: onActionPressed,
        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
        label: Text(
          l10n.openChat,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF003527),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    if (group.isPrivate) {
      return ElevatedButton(
        onPressed: onActionPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFC3ECD7),
          foregroundColor: const Color(0xFF002115),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(
          l10n.requestToJoin,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      );
    }

    return ElevatedButton(
      onPressed: onActionPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF003527),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        l10n.joinGroup,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(count % 1000 == 0 ? 0 : 1)}k';
    }
    return count.toString();
  }
}
