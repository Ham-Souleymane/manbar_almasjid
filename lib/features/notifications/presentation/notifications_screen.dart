import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import '../../../core/l10n/app_localizations.dart';
import '../../registration/data/registration_repository.dart';
import '../../posts/presentation/post_detail_screen.dart';
import '../data/notification_model.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _markAsRead(String imamId, NotificationModel notification) async {
    if (notification.read) return;
    await FirebaseFirestore.instance
        .collection('imams')
        .doc(imamId)
        .collection('notifications')
        .doc(notification.id)
        .update({'read': true});
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imamAsync = ref.watch(currentImamProvider);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: Text(
          l10n.notificationsTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0.5,
        centerTitle: true,
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
            return Center(
              child: Text(l10n.loginFirstForNotifications),
            );
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

              final notifications = snapshot.data ?? [];
              if (notifications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 72,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noNotifications,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.notificationsSubtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return _buildNotificationCard(context, imam.id, notification);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    String imamId,
    NotificationModel notification,
  ) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final formattedTime =
        intl.DateFormat('yyyy/MM/dd hh:mm a', languageCode).format(notification.timestamp);
    final isUnread = !notification.read;

    IconData getIcon() {
      switch (notification.type) {
        case 'comment':
          return Icons.comment_rounded;
        case 'verification':
          return Icons.verified_rounded;
        default:
          return Icons.notifications_rounded;
      }
    }

    Color getIconColor() {
      switch (notification.type) {
        case 'comment':
          return const Color(0xFF0F766E);
        case 'verification':
          return const Color(0xFF10B981);
        default:
          return const Color(0xFFF59E0B);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isUnread ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isUnread
            ? Border.all(color: const Color(0xFFBBF7D0), width: 1)
            : Border.all(color: Colors.grey.shade100, width: 1),
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
          onTap: () async {
            await _markAsRead(imamId, notification);
            if (context.mounted && notification.postId != null && notification.postId!.isNotEmpty) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PostDetailScreen(postId: notification.postId!),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: getIconColor().withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    getIcon(),
                    color: getIconColor(),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    isUnread ? FontWeight.bold : FontWeight.w600,
                                color: const Color(0xFF1F2937),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            formattedTime,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black38,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color(0xFF4B5563),
                          height: 1.5,
                          fontWeight:
                              isUnread ? FontWeight.w500 : FontWeight.normal,
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
    );
  }
}
