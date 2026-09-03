import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../application/forum_providers.dart';
import '../data/forum_repository.dart';
import '../domain/imam_group_model.dart';
import 'widgets/create_group_dialog.dart';
import 'imam_group_chat_screen.dart';

class AdminManageGroupsScreen extends ConsumerWidget {
  const AdminManageGroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(firebaseAuthProvider).currentUser;
    final groupsAsync = ref.watch(imamGroupsStreamProvider);

    return groupsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.emerald),
      ),
      error: (e, _) => Center(child: Text('خطأ في تحميل المجموعات: $e')),
      data: (groups) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with quick create button
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ملتقيات الأئمة',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF151C27),
                        ),
                      ),
                      Text(
                        '${groups.length} مجموعة',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF707974),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => CreateOrEditGroupDialog(
                          adminId: user?.uid ?? 'admin',
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('إضافة ملتقى'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Seed default groups button (if empty)
              if (groups.isEmpty) ...[
                _EmptyGroupsState(adminId: user?.uid ?? 'admin'),
              ] else
                Expanded(
                  child: ListView.separated(
                    itemCount: groups.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return _AdminGroupTile(
                        group: groups[index],
                        adminId: user?.uid ?? 'admin',
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyGroupsState extends ConsumerStatefulWidget {
  const _EmptyGroupsState({required this.adminId});
  final String adminId;

  @override
  ConsumerState<_EmptyGroupsState> createState() => _EmptyGroupsStateState();
}

class _EmptyGroupsStateState extends ConsumerState<_EmptyGroupsState> {
  bool _isSeeding = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.forum_outlined,
                  size: 56,
                  color: Color(0xFF0F766E),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'لا توجد ملتقيات بعد',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF151C27),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'أنشئ أول مجموعة تخصصية للأئمة أو استخدم الزر أدناه\nلاستيراد المجموعات الافتراضية بنقرة واحدة.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF707974),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 280,
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => CreateOrEditGroupDialog(
                              adminId: widget.adminId,
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text(
                          'إنشاء مجموعة جديدة',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton.icon(
                        onPressed: _isSeeding
                            ? null
                            : () async {
                                setState(() => _isSeeding = true);
                                try {
                                  await ref
                                      .read(forumRepositoryProvider)
                                      .seedDefaultGroupsIfEmpty();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'تم استيراد المجموعات الافتراضية بنجاح'),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() => _isSeeding = false);
                                  }
                                }
                              },
                        icon: _isSeeding
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF0F766E),
                                ),
                              )
                            : const Icon(Icons.download_rounded,
                                size: 20, color: Color(0xFF0F766E)),
                        label: Text(
                          _isSeeding
                              ? 'جاري الاستيراد...'
                              : 'استيراد المجموعات الافتراضية',
                          style: const TextStyle(
                            color: Color(0xFF0F766E),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: Color(0xFF0F766E), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminGroupTile extends ConsumerWidget {
  const _AdminGroupTile({required this.group, required this.adminId});

  final ImamGroupModel group;
  final String adminId;

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
      case 'menu_book':
      default:
        return Icons.menu_book_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFC3ECD7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _resolveIcon(group.iconName),
                color: const Color(0xFF064E3B),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // Info Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    group.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF151C27),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.category_rounded,
                              size: 12, color: Color(0xFF707974)),
                          const SizedBox(width: 3),
                          Text(
                            group.category,
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF707974)),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people_rounded,
                              size: 12, color: Color(0xFF707974)),
                          const SizedBox(width: 3),
                          Text(
                            '${group.membersCount} عضو',
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF707974)),
                          ),
                        ],
                      ),
                      if (group.isPrivate)
                        const Icon(Icons.lock_rounded,
                            size: 12, color: Color(0xFFB7922E)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Open Chat Button
                IconButton(
                  tooltip: 'فتح محادثة المجموعة',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                  icon: const Icon(Icons.chat_bubble_outline_rounded,
                      size: 20, color: AppColors.emerald),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ImamGroupChatScreen(groupId: group.id),
                      ),
                    );
                  },
                ),
                // Edit Button
                IconButton(
                  tooltip: 'تعديل المجموعة',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                  icon: const Icon(Icons.edit_rounded,
                      size: 20, color: Colors.black54),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => CreateOrEditGroupDialog(
                        existingGroup: group,
                        adminId: adminId,
                      ),
                    );
                  },
                ),
                // Delete Button
                IconButton(
                  tooltip: 'حذف المجموعة',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 20, color: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('حذف المجموعة'),
                        content: Text(
                            'هل أنت متأكد من حذف مجموعة "${group.name}"؟\nلا يمكن التراجع عن هذه العملية.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('إلغاء'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                            child: const Text('حذف',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref
                          .read(forumControllerProvider.notifier)
                          .deleteGroup(group.id);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
