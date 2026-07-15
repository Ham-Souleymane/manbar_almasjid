import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String userName;
  final String? photo;
  final String text;
  final DateTime timestamp;

  CommentModel({
    required this.id,
    required this.userName,
    this.photo,
    required this.text,
    required this.timestamp,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return CommentModel(
      id: doc.id,
      userName: data['userName'] as String? ?? 'مستخدم مجهول',
      photo: (data['userPhotoUrl'] as String?) ?? (data['photo'] as String?),
      text: data['text'] as String? ?? '',
      timestamp: (data['createdAt'] as Timestamp?)?.toDate() ??
          (data['timestamp'] as Timestamp?)?.toDate() ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userName': userName,
      if (photo != null) 'userPhotoUrl': photo,
      'text': text,
      'createdAt': Timestamp.fromDate(timestamp),
    };
  }
}
