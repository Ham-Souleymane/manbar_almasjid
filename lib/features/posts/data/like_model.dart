import 'package:cloud_firestore/cloud_firestore.dart';

class LikeModel {
  final String userId;
  final String userName;
  final String? photo;
  final DateTime timestamp;

  LikeModel({
    required this.userId,
    required this.userName,
    this.photo,
    required this.timestamp,
  });

  factory LikeModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return LikeModel(
      userId: doc.id,
      userName: data['userName'] as String? ?? 'مستخدم مجهول',
      photo: (data['userPhotoUrl'] as String?) ?? (data['photo'] as String?),
      timestamp: (data['likedAt'] as Timestamp?)?.toDate() ??
          (data['createdAt'] as Timestamp?)?.toDate() ??
          (data['timestamp'] as Timestamp?)?.toDate() ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userName': userName,
      if (photo != null) 'userPhotoUrl': photo,
      'likedAt': Timestamp.fromDate(timestamp),
    };
  }
}
