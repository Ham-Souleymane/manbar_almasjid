import 'package:cloud_firestore/cloud_firestore.dart';

class ForumMessageModel {
  const ForumMessageModel({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    this.senderPhoto,
    this.senderMosqueName = '',
    this.senderRole = 'إمام وخطيب',
    required this.text,
    this.mediaUrl,
    this.mediaType,
    required this.createdAt,
    this.reactions = const {},
    this.replyToMessageId,
    this.replyToText,
    this.replyToSenderName,
    this.isDeleted = false,
  });

  final String id;
  final String groupId;
  final String senderId;
  final String senderName;
  final String? senderPhoto;
  final String senderMosqueName;
  final String senderRole;
  final String text;
  final String? mediaUrl;
  final String? mediaType;
  final DateTime createdAt;
  final Map<String, List<String>> reactions;
  final String? replyToMessageId;
  final String? replyToText;
  final String? replyToSenderName;
  final bool isDeleted;

  factory ForumMessageModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    final rawReactions = data['reactions'];
    final reactionsMap = <String, List<String>>{};
    if (rawReactions is Map) {
      rawReactions.forEach((key, val) {
        if (val is List) {
          reactionsMap[key.toString()] =
              val.map((e) => e.toString()).toList();
        }
      });
    }

    return ForumMessageModel(
      id: doc.id,
      groupId: data['groupId']?.toString() ?? '',
      senderId: data['senderId']?.toString() ?? '',
      senderName: data['senderName']?.toString() ?? 'إمام',
      senderPhoto: data['senderPhoto']?.toString(),
      senderMosqueName: data['senderMosqueName']?.toString() ?? '',
      senderRole: data['senderRole']?.toString() ?? 'إمام وخطيب',
      text: data['text']?.toString() ?? '',
      mediaUrl: data['mediaUrl']?.toString(),
      mediaType: data['mediaType']?.toString(),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reactions: reactionsMap,
      replyToMessageId: data['replyToMessageId']?.toString(),
      replyToText: data['replyToText']?.toString(),
      replyToSenderName: data['replyToSenderName']?.toString(),
      isDeleted: data['isDeleted'] == true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'senderId': senderId,
      'senderName': senderName,
      if (senderPhoto != null) 'senderPhoto': senderPhoto,
      'senderMosqueName': senderMosqueName,
      'senderRole': senderRole,
      'text': text,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      if (mediaType != null) 'mediaType': mediaType,
      'createdAt': Timestamp.fromDate(createdAt),
      'reactions': reactions,
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      if (replyToText != null) 'replyToText': replyToText,
      if (replyToSenderName != null) 'replyToSenderName': replyToSenderName,
      'isDeleted': isDeleted,
    };
  }

  ForumMessageModel copyWith({
    String? id,
    String? groupId,
    String? senderId,
    String? senderName,
    String? senderPhoto,
    String? senderMosqueName,
    String? senderRole,
    String? text,
    String? mediaUrl,
    String? mediaType,
    DateTime? createdAt,
    Map<String, List<String>>? reactions,
    String? replyToMessageId,
    String? replyToText,
    String? replyToSenderName,
    bool? isDeleted,
  }) {
    return ForumMessageModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhoto: senderPhoto ?? this.senderPhoto,
      senderMosqueName: senderMosqueName ?? this.senderMosqueName,
      senderRole: senderRole ?? this.senderRole,
      text: text ?? this.text,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      createdAt: createdAt ?? this.createdAt,
      reactions: reactions ?? this.reactions,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToText: replyToText ?? this.replyToText,
      replyToSenderName: replyToSenderName ?? this.replyToSenderName,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
