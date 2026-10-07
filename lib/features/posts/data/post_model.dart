import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String mosqueId;
  final String imamId;
  final String text;
  final List<String> mediaUrls;
  final String mediaType; // 'image' | 'video' | 'file' | 'none'
  final String category; // 'درس' | 'خطبة' | 'إعلان' | 'نشاط' | 'تنبيه'
  final DateTime? eventDate;
  final DateTime? scheduledFor;
  final DateTime createdAt;
  final int viewCount;
  final int likeCount;
  final int commentCount;
  final bool postAsImam;

  PostModel({
    required this.id,
    required this.mosqueId,
    required this.imamId,
    required this.text,
    required this.mediaUrls,
    required this.mediaType,
    required this.category,
    this.eventDate,
    this.scheduledFor,
    required this.createdAt,
    required this.viewCount,
    this.likeCount = 0,
    this.commentCount = 0,
    this.postAsImam = false,
  });

  factory PostModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return PostModel(
      id: doc.id,
      mosqueId: data['mosqueId'] as String? ?? '',
      imamId: data['imamId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
      mediaType: data['mediaType'] as String? ?? 'none',
      category: data['category'] as String? ?? 'إعلان',
      eventDate: (data['eventDate'] as Timestamp?)?.toDate(),
      scheduledFor: (data['scheduledFor'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      viewCount: data['viewCount'] as int? ?? 0,
      likeCount: data['likeCount'] as int? ?? 0,
      commentCount: data['commentCount'] as int? ?? 0,
      postAsImam: data['postAsImam'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'mosqueId': mosqueId,
      'imamId': imamId,
      'text': text,
      'mediaUrls': mediaUrls,
      'mediaType': mediaType,
      'category': category,
      if (eventDate != null) 'eventDate': Timestamp.fromDate(eventDate!),
      if (scheduledFor != null) 'scheduledFor': Timestamp.fromDate(scheduledFor!),
      'createdAt': Timestamp.fromDate(createdAt),
      'viewCount': viewCount,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'postAsImam': postAsImam,
    };
  }

  PostModel copyWith({
    String? id,
    String? mosqueId,
    String? imamId,
    String? text,
    List<String>? mediaUrls,
    String? mediaType,
    String? category,
    DateTime? eventDate,
    DateTime? scheduledFor,
    DateTime? createdAt,
    int? viewCount,
    int? likeCount,
    int? commentCount,
    bool? postAsImam,
  }) {
    return PostModel(
      id: id ?? this.id,
      mosqueId: mosqueId ?? this.mosqueId,
      imamId: imamId ?? this.imamId,
      text: text ?? this.text,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      mediaType: mediaType ?? this.mediaType,
      category: category ?? this.category,
      eventDate: eventDate ?? this.eventDate,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      createdAt: createdAt ?? this.createdAt,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      postAsImam: postAsImam ?? this.postAsImam,
    );
  }
}
