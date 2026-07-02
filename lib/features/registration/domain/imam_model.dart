import 'package:cloud_firestore/cloud_firestore.dart';

import 'imam_status.dart';

class ImamModel {
  const ImamModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    this.photo,
    required this.status,
    this.mosqueId,
    required this.createdAt,
  });

  final String id;
  final String fullName;
  final String phone;
  final String email;
  final String? photo;
  final ImamStatus status;
  final String? mosqueId;
  final DateTime createdAt;

  bool get isPending => status == ImamStatus.pending;
  bool get isVerified => status == ImamStatus.verified;
  bool get isRejected => status == ImamStatus.rejected;

  factory ImamModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ImamModel(
      id: doc.id,
      fullName: data['fullName'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      email: data['email'] as String? ?? '',
      photo: data['photo'] as String?,
      status: ImamStatus.fromString(data['status'] as String? ?? 'pending'),
      mosqueId: data['mosqueId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fullName': fullName,
      'phone': phone,
      'email': email,
      if (photo != null) 'photo': photo,
      'status': status.value,
      if (mosqueId != null) 'mosqueId': mosqueId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
