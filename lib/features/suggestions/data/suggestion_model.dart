import 'package:cloud_firestore/cloud_firestore.dart';

class SuggestionModel {
  final String id;
  final String imamId;
  final String imamName;
  final String imamPhone;
  final String mosqueId;
  final String mosqueName;
  final String type; // e.g. 'اقتراح ميزة جديدة' | 'تعديل أو تحسين' | 'طلب إضافة تصنيف' | 'مشكلة فنية' | 'أخرى'
  final String title;
  final String content;
  final String status; // 'pending' | 'in_progress' | 'implemented' | 'rejected'
  final DateTime createdAt;
  final String? adminResponse;
  final DateTime? respondedAt;

  const SuggestionModel({
    required this.id,
    required this.imamId,
    required this.imamName,
    this.imamPhone = '',
    this.mosqueId = '',
    this.mosqueName = '',
    required this.type,
    required this.title,
    required this.content,
    this.status = 'pending',
    required this.createdAt,
    this.adminResponse,
    this.respondedAt,
  });

  factory SuggestionModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return SuggestionModel(
      id: doc.id,
      imamId: data['imamId'] as String? ?? '',
      imamName: data['imamName'] as String? ?? '',
      imamPhone: data['imamPhone'] as String? ?? '',
      mosqueId: data['mosqueId'] as String? ?? '',
      mosqueName: data['mosqueName'] as String? ?? '',
      type: data['type'] as String? ?? 'اقتراح ميزة جديدة',
      title: data['title'] as String? ?? '',
      content: data['content'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      adminResponse: data['adminResponse'] as String?,
      respondedAt: (data['respondedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'imamId': imamId,
      'imamName': imamName,
      'imamPhone': imamPhone,
      'mosqueId': mosqueId,
      'mosqueName': mosqueName,
      'type': type,
      'title': title,
      'content': content,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      if (adminResponse != null) 'adminResponse': adminResponse,
      if (respondedAt != null)
        'respondedAt': Timestamp.fromDate(respondedAt!),
    };
  }
}
