import 'package:cloud_firestore/cloud_firestore.dart';

/// Notification type constants
class NotifType {
  static const comment = 'comment';
  static const verification = 'verification';
  static const question = 'question';
  static const forumMessage = 'forum_message';
  static const forumMention = 'forum_mention';
  static const forumReply = 'forum_reply';
  static const forumJoin = 'forum_join';

  /// All forum-related notification types
  static const forumTypes = [forumMessage, forumMention, forumReply, forumJoin];
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final String type; // see NotifType constants
  final String? postId;
  final String? groupId;
  final String? questionId;
  final bool read;
  final String? senderName;
  final String? senderPhoto;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    this.postId,
    this.groupId,
    this.questionId,
    required this.read,
    this.senderName,
    this.senderPhoto,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return NotificationModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: data['type'] as String? ?? 'general',
      postId: data['postId'] as String?,
      groupId: data['groupId'] as String?,
      questionId: data['questionId'] as String?,
      read: data['read'] as bool? ?? false,
      senderName: data['senderName'] as String?,
      senderPhoto: data['senderPhoto'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'body': body,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type,
      if (postId != null) 'postId': postId,
      if (groupId != null) 'groupId': groupId,
      if (questionId != null) 'questionId': questionId,
      'read': read,
      if (senderName != null) 'senderName': senderName,
      if (senderPhoto != null) 'senderPhoto': senderPhoto,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? timestamp,
    String? type,
    String? postId,
    String? groupId,
    String? questionId,
    bool? read,
    String? senderName,
    String? senderPhoto,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      postId: postId ?? this.postId,
      groupId: groupId ?? this.groupId,
      questionId: questionId ?? this.questionId,
      read: read ?? this.read,
      senderName: senderName ?? this.senderName,
      senderPhoto: senderPhoto ?? this.senderPhoto,
    );
  }
}
