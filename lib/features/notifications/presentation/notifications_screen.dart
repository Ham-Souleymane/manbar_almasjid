import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import '../../../core/l10n/app_localizations.dart';
import '../../forum/presentation/imam_group_chat_screen.dart';
import '../../registration/data/registration_repository.dart';
import '../../posts/presentation/post_detail_screen.dart';
import '../data/notification_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Tab filter definition
// ─────────────────────────────────────────────────────────────────────────────
enum _NotifTab {
  all('الكل'),
  forum('الملتقى'),
  posts('المنشورات'),
  questions('الأسئلة');

  const _NotifTab(this.label);
  final String label;
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _NotifTab.values.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _markAsRead(String imamId, NotificationModel notification) async {
    if (notification.read) return;
    await FirebaseFirestore.instance
        .collection('imams')
        .doc(imamId)
        .collection('notifications')
        .doc(notification.id)
        .update({'read': true});
  }

  Future<void> _deleteNotification(String imamId, String notifId) async {
    await FirebaseFirestore.instance
        .collection('imams')
        .doc(imamId)
        .collection('notifications')
        .doc(notifId)
        .delete();
  }

  Future<void> _markAllAsRead(String imamId) async {
    final query = await FirebaseFirestore.instance
        .collection('imams')
        .doc(imamId)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();

    if (query.docs.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in query.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  /// Filters notifications by current tab.
  List<NotificationModel> _filter(
      List<NotificationModel> all, _NotifTab tab) {
    switch (tab) {
      case _NotifTab.all:
        return all;
      case _NotifTab.forum:
        return all
            .where((n) => NotifType.forumTypes.contains(n.type))
            .toList();
      case _NotifTab.posts:
        return all
            .where((n) =>
                n.type == NotifType.comment ||
                (n.postId != null && n.postId!.isNotEmpty))
            .toList();
      case _NotifTab.questions:
        return all
            .where((n) =>
                n.type == NotifType.question ||
                (n.questionId != null && n.questionId!.isNotEmpty))
            .toList();
    }
  }

  // ── Notification appearance helpers ────────────────────────────────────────

  IconData _iconFor(String type) {
    switch (type) {
      case NotifType.forumMention:
        return Icons.alternate_email_rounded;
      case NotifType.forumReply:
        return Icons.reply_rounded;
      case NotifType.forumJoin:
        return Icons.group_add_rounded;
      case NotifType.forumMessage:
        return Icons.forum_rounded;
      case NotifType.question:
        return Icons.question_answer_rounded;
      case NotifType.comment:
        return Icons.comment_rounded;
      case NotifType.verification:
        return Icons.verified_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case NotifType.forumMention:
        return const Color(0xFFD97706); // amber
      case NotifType.forumReply:
        return const Color(0xFF7C3AED); // violet
      case NotifType.forumJoin:
        return const Color(0xFF059669); // green
      case NotifType.forumMessage:
        return const Color(0xFF0F766E); // teal
      case NotifType.question:
        return const Color(0xFF2563EB); // blue
      case NotifType.comment:
        return const Color(0xFF0F766E);
      case NotifType.verification:
        return const Color(0xFF10B981);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String _labelFor(String type) {
    switch (type) {
      case NotifType.forumMention:
        return 'ذكر';
      case NotifType.forumReply:
        return 'رد';
      case NotifType.forumJoin:
        return 'انضمام';
      case NotifType.forumMessage:
        return 'ملتقى';
      case NotifType.question:
        return 'سؤال';
      case NotifType.comment:
        return 'تعليق';
      case NotifType.verification:
        return 'تحقق';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final imamAsync = ref.watch(currentImamProvider);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: Text(
          l10n.notificationsTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF111827),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        elevation: 0,
        centerTitle: true,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Color(0xFF111827),
                  size: 20,
                ),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        actions: [
          imamAsync.when(
            data: (imam) {
              if (imam == null) return const SizedBox();
              return TextButton(
                onPressed: () => _markAllAsRead(imam.id),
                child: Text(
                  l10n.markAllRead,
                  style: const TextStyle(
                    color: Color(0xFF0F766E),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0F766E),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF0F766E),
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          tabs: _NotifTab.values
              .map((t) => Tab(text: t.label))
              .toList(),
        ),
      ),
      body: imamAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF0F766E)),
        ),
        error: (error, _) => Center(
          child: Text('${l10n.error}: $error'),
        ),
        data: (imam) {
          if (imam == null) {
            return Center(child: Text(l10n.loginFirstForNotifications));
          }

          final notificationsStream = FirebaseFirestore.instance
              .collection('imams')
              .doc(imam.id)
              .collection('notifications')
              .orderBy('timestamp', descending: true)
              .snapshots()
              .map((snap) => snap.docs
                  .map((doc) => NotificationModel.fromFirestore(doc))
                  .toList());

          return StreamBuilder<List<NotificationModel>>(
            stream: notificationsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF0F766E)),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('${l10n.error}: ${snapshot.error}'),
                );
              }

              final all = snapshot.data ?? [];

              return TabBarView(
                controller: _tabController,
                children: _NotifTab.values.map((tab) {
                  final filtered = _filter(all, tab);
                  if (filtered.isEmpty) {
                    return _EmptyNotifications(tab: tab);
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final notification = filtered[index];
                      return _NotificationCard(
                        notification: notification,
                        imamId: imam.id,
                        onTap: () => _handleTap(context, imam.id, notification),
                        onDismissed: () =>
                            _deleteNotification(imam.id, notification.id),
                        iconData: _iconFor(notification.type),
                        iconColor: _colorFor(notification.type),
                        typeLabel: _labelFor(notification.type),
                      );
                    },
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleTap(BuildContext context, String imamId, NotificationModel notification) async {
    await _markAsRead(imamId, notification);
    if (!context.mounted) return;

    if (notification.groupId != null && notification.groupId!.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ImamGroupChatScreen(groupId: notification.groupId!),
        ),
      );
      return;
    }
    if (notification.postId != null && notification.postId!.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PostDetailScreen(postId: notification.postId!),
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification Card with Dismissible
// ─────────────────────────────────────────────────────────────────────────────
class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.imamId,
    required this.onTap,
    required this.onDismissed,
    required this.iconData,
    required this.iconColor,
    required this.typeLabel,
  });

  final NotificationModel notification;
  final String imamId;
  final VoidCallback onTap;
  final VoidCallback onDismissed;
  final IconData iconData;
  final Color iconColor;
  final String typeLabel;

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final formattedTime = intl.DateFormat('yyyy/MM/dd hh:mm a', languageCode)
        .format(notification.timestamp);
    final isUnread = !notification.read;

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 26),
      ),
      confirmDismiss: (_) async {
        onDismissed();
        return true;
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isUnread ? const Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isUnread
              ? Border.all(color: const Color(0xFFBBF7D0))
              : Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon bubble
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(iconData, color: iconColor, size: 22),
                      ),
                      if (isUnread)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE11D48),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Type badge
                            if (typeLabel.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: iconColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  typeLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: iconColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isUnread
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: const Color(0xFF1F2937),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          notification.body,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: const Color(0xFF4B5563),
                            height: 1.4,
                            fontWeight:
                                isUnread ? FontWeight.w500 : FontWeight.normal,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          formattedTime,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state per tab
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications({required this.tab});

  final _NotifTab tab;

  @override
  Widget build(BuildContext context) {
    final (icon, message) = switch (tab) {
      _NotifTab.forum => (
          Icons.forum_outlined,
          'لا توجد إشعارات من الملتقى'
        ),
      _NotifTab.posts => (
          Icons.article_outlined,
          'لا توجد إشعارات منشورات'
        ),
      _NotifTab.questions => (
          Icons.quiz_outlined,
          'لا توجد إشعارات أسئلة'
        ),
      _NotifTab.all => (
          Icons.notifications_off_outlined,
          'لا توجد إشعارات بعد'
        ),
    };

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ستظهر هنا عند ورود إشعارات جديدة',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
