import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../registration/data/registration_repository.dart';
import '../application/forum_providers.dart';
import '../domain/imam_group_model.dart';
import 'imam_group_chat_screen.dart';
import 'widgets/create_group_dialog.dart';
import 'widgets/group_card.dart';

class DiscoverGroupsScreen extends ConsumerStatefulWidget {
  const DiscoverGroupsScreen({super.key});

  @override
  ConsumerState<DiscoverGroupsScreen> createState() =>
      _DiscoverGroupsScreenState();
}

class _DiscoverGroupsScreenState extends ConsumerState<DiscoverGroupsScreen> {
  final _searchController = TextEditingController();
  final Set<String> _joiningGroupIds = {};

  static const List<String> _categories = [
    'الكل',
    'الفقه',
    'الحديث الشريف',
    'قضايا معاصرة',
    'إدارة المساجد',
    'القرآن والتجويد',
    'الخطابة والدعوة',
    'العقيدة وأصول الدين',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    ref.read(forumFilterProvider.notifier).setSearch(query);
  }

  void _onCategorySelected(String category) {
    ref.read(forumFilterProvider.notifier).setCategory(category);
  }

  Future<void> _handleGroupAction({
    required ImamGroupModel group,
    required String? currentImamId,
  }) async {
    if (currentImamId == null || currentImamId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تسجيل الدخول كإمام أولاً للانضمام والمحادثة'),
        ),
      );
      return;
    }

    final isMember = group.isMember(currentImamId);

    if (isMember) {
      _openChat(group);
      return;
    }

    // Join group
    setState(() => _joiningGroupIds.add(group.id));
    final imam = ref.read(currentImamProvider).asData?.value;
    final success = await ref
        .read(forumControllerProvider.notifier)
        .joinGroup(
          groupId: group.id,
          imamId: currentImamId,
          imamName: imam?.fullName ?? '',
          groupName: group.name,
        );

    if (mounted) {
      setState(() => _joiningGroupIds.remove(group.id));
      if (success) {
        _openChat(group.copyWith(
          memberIds: [...group.memberIds, currentImamId],
          membersCount: group.membersCount + 1,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر الانضمام للمجموعة، يرجى المحاولة لاحقاً'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _openChat(ImamGroupModel group) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ImamGroupChatScreen(groupId: group.id),
      ),
    );
  }

  void _showCreateOrEditDialog([ImamGroupModel? existingGroup]) {
    final user = ref.read(firebaseAuthProvider).currentUser;
    showDialog(
      context: context,
      builder: (_) => CreateOrEditGroupDialog(
        existingGroup: existingGroup,
        adminId: user?.uid ?? 'admin',
      ),
    );
  }

  void _confirmDeleteGroup(ImamGroupModel group) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المجموعة'),
        content: Text('هل أنت متأكد من رغبتك في حذف مجموعة "${group.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref
                  .read(forumControllerProvider.notifier)
                  .deleteGroup(group.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final groupsAsync = ref.watch(imamGroupsStreamProvider);
    final filterState = ref.watch(forumFilterProvider);
    final isAdmin = ref.watch(isAdminProvider).asData?.value ?? false;
    final imam = ref.watch(currentImamProvider).asData?.value;
    final currentImamId = imam?.id ?? ref.watch(firebaseAuthProvider).currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9FF),
        foregroundColor: const Color(0xFF003527),
        iconTheme: const IconThemeData(color: Color(0xFF003527)),
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Color(0xFF003527),
                  size: 20,
                ),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        title: Text(
          'ملتقى الأئمة والدعاة',
          style: GoogleFonts.tajawal(
            color: const Color(0xFF003527),
            fontWeight: FontWeight.w700,
            fontSize: 19,
          ),
        ),
        centerTitle: true,
        actions: [
          if (isAdmin)
            IconButton(
              tooltip: 'إنشاء مجموعة جديدة (أدمن)',
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFF003527),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 18),
              ),
              onPressed: () => _showCreateOrEditDialog(),
            ),
          // Forum-filtered notification badge
          Consumer(builder: (context, ref, _) {
            final forumUnread = ref.watch(forumUnreadCountProvider).asData?.value ?? 0;
            return IconButton(
              tooltip: l10n.notificationsAlerts,
              icon: Badge(
                isLabelVisible: forumUnread > 0,
                label: Text(
                  forumUnread > 9 ? '9+' : '$forumUnread',
                  style: const TextStyle(fontSize: 10),
                ),
                backgroundColor: const Color(0xFFE11D48),
                child: Icon(
                  forumUnread > 0
                      ? Icons.notifications_rounded
                      : Icons.notifications_none_rounded,
                  color: const Color(0xFF003527),
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                );
              },
            );
          }),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final isMedium = constraints.maxWidth >= 600 && constraints.maxWidth < 900;
          final crossAxisCount = isWide ? 3 : (isMedium ? 2 : 1);
          final childAspectRatio = isWide ? 1.35 : (isMedium ? 1.25 : 1.55);

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(imamGroupsStreamProvider),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Title
                        Text(
                          l10n.discoverGroups,
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF003527),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Subtitle
                        Text(
                          l10n.discoverGroupsSubtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF404944),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Search Bar
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F3FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFDCE2F3)),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            decoration: InputDecoration(
                              hintText: l10n.searchGroups,
                              hintStyle: const TextStyle(
                                color: Color(0xFF707974),
                                fontSize: 14,
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: Color(0xFF707974),
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        _onSearchChanged('');
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Category Pills
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _categories.map((cat) {
                              final isSelected = filterState.category == cat;
                              return Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: ChoiceChip(
                                  label: Text(cat),
                                  selected: isSelected,
                                  onSelected: (_) => _onCategorySelected(cat),
                                  selectedColor: const Color(0xFF003527),
                                  backgroundColor: Colors.white,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF404944),
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                  side: BorderSide(
                                    color: isSelected
                                        ? const Color(0xFF003527)
                                        : const Color(0xFFDCE2F3),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),

                // Groups Grid
                groupsAsync.when(
                  loading: () => const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF003527)),
                    ),
                  ),
                  error: (e, _) => SliverFillRemaining(
                    child: Center(
                      child: Text('حدث خطأ في تحميل المجموعات: $e'),
                    ),
                  ),
                  data: (groups) {
                    if (groups.isEmpty) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.group_off_rounded,
                                size: 64,
                                color: Colors.black26,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.noGroupsFound,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                              if (isAdmin) ...[
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () => _showCreateOrEditDialog(),
                                  icon: const Icon(Icons.add),
                                  label: const Text('إنشاء مجموعة جديدة الآن'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF003527),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: childAspectRatio,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final group = groups[index];
                            final isMember = currentImamId != null &&
                                group.isMember(currentImamId);
                            final isJoining = _joiningGroupIds.contains(group.id);

                            return GroupCard(
                              group: group,
                              isMember: isMember,
                              isAdmin: isAdmin,
                              isLoading: isJoining,
                              onTap: () {
                                if (isMember) {
                                  _openChat(group);
                                } else {
                                  _handleGroupAction(
                                    group: group,
                                    currentImamId: currentImamId,
                                  );
                                }
                              },
                              onActionPressed: () {
                                _handleGroupAction(
                                  group: group,
                                  currentImamId: currentImamId,
                                );
                              },
                              onEdit: () => _showCreateOrEditDialog(group),
                              onDelete: () => _confirmDeleteGroup(group),
                            );
                          },
                          childCount: groups.length,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateOrEditDialog(),
              backgroundColor: const Color(0xFF003527),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة ملتقى جديد'),
            )
          : null,
    );
  }
}
