import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../registration/data/registration_repository.dart';
import '../application/forum_providers.dart';
import 'widgets/create_group_dialog.dart';

class GroupInfoScreen extends ConsumerWidget {
  const GroupInfoScreen({
    super.key,
    required this.groupId,
  });

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final groupAsync = ref.watch(singleGroupStreamProvider(groupId));
    final imam = ref.watch(currentImamProvider).asData?.value;
    final currentImamId =
        imam?.id ?? ref.watch(firebaseAuthProvider).currentUser?.uid;
    final isAdmin = ref.watch(isAdminProvider).asData?.value ?? false;

    return groupAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.emerald)),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('تفاصيل المجموعة')),
        body: Center(child: Text('خطأ: $e')),
      ),
      data: (group) {
        if (group == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('تفاصيل المجموعة')),
            body: const Center(child: Text('المجموعة غير موجودة')),
          );
        }

        final isMember =
            currentImamId != null && group.isMember(currentImamId);

        return Scaffold(
          backgroundColor: const Color(0xFFF9F9FF),
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF003527),
            iconTheme: const IconThemeData(color: Color(0xFF003527)),
            elevation: 0,
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
            title: const Text(
              'معلومات الملتقى',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF003527),
              ),
            ),
            actions: [
              if (isAdmin)
                IconButton(
                  tooltip: 'تعديل المجموعة',
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => CreateOrEditGroupDialog(
                        existingGroup: group,
                        adminId: currentImamId ?? 'admin',
                      ),
                    );
                  },
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: Color(0xFFC3ECD7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: Color(0xFF064E3B),
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      group.name,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF151C27),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F3FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${group.category} • ${group.membersCount} عضو',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF003527),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      group.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF404944),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Group Rules Card
              if (group.rules.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F8)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.gavel_rounded,
                              color: Color(0xFF003527), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            l10n.groupRules,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF003527),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...group.rules.asMap().entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${entry.key + 1}. ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF003527),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF404944),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Members List Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.people_alt_rounded,
                                color: Color(0xFF003527), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${l10n.groupMembers} (${group.memberIds.length})',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF003527),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (group.memberIds.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'لا يوجد أعضاء منضمون بعد',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      )
                    else
                      ...group.memberIds.take(20).map((imamId) {
                        return _MemberTile(
                          imamId: imamId,
                          isCurrentImam: imamId == currentImamId,
                        );
                      }),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Leave / Join Button
              if (isMember)
                OutlinedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(l10n.leaveGroup),
                        content: Text(l10n.leaveGroupConfirm),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: Text(l10n.cancel),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                            child: Text(
                              l10n.leaveGroup,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && context.mounted) {
                      await ref
                          .read(forumControllerProvider.notifier)
                          .leaveGroup(
                            groupId: group.id,
                            imamId: currentImamId,
                          );
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    }
                  },
                  icon: const Icon(Icons.exit_to_app_rounded, color: Colors.red),
                  label: Text(
                    l10n.leaveGroup,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.imamId,
    required this.isCurrentImam,
  });

  final String imamId;
  final bool isCurrentImam;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future:
          FirebaseFirestore.instance.collection('imams').doc(imamId).get(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final name = data?['fullName']?.toString() ?? 'إمام';
        final photo = data?['photo']?.toString();

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.emeraldPale,
                backgroundImage:
                    photo != null && photo.isNotEmpty ? NetworkImage(photo) : null,
                child: photo == null || photo.isEmpty
                    ? const Icon(Icons.person, color: AppColors.emeraldDark, size: 18)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isCurrentImam) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.emeraldPale,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'أنت',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.emeraldDark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Text(
                      'إمام وخطيب',
                      style: TextStyle(fontSize: 11, color: Colors.black45),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
