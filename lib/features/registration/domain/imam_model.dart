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
    this.commentsNotify = true,
    this.verificationNotify = true,
    this.acceptingQuestions = true,
    this.specialties = const [],
    this.bio = '',
    this.responseTime = '',
    this.allowPrivateQuestions = true,
  });

  final String id;
  final String fullName;
  final String phone;
  final String email;
  final String? photo;
  final ImamStatus status;
  final String? mosqueId;
  final DateTime createdAt;
  final bool commentsNotify;
  final bool verificationNotify;

  // ── Ask Sheikh / Qualifications & Availability ──────────────
  final bool acceptingQuestions;
  final List<String> specialties;
  final String bio;
  final String responseTime;
  final bool allowPrivateQuestions;

  bool get isPending => status == ImamStatus.pending;
  bool get isVerified => status == ImamStatus.verified;
  bool get isRejected => status == ImamStatus.rejected;
  bool get isBlocked => status == ImamStatus.blocked;

  factory ImamModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    // Support both 'specialties' and legacy 'fields'
    final rawSpecialties = data['specialties'] ?? data['fields'];
    final specialtiesList = rawSpecialties is List
        ? rawSpecialties.map((e) => e.toString()).toList()
        : <String>[];

    return ImamModel(
      id: doc.id,
      fullName: data['fullName']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      photo: data['photo']?.toString(),
      status: ImamStatus.fromString(data['status']?.toString() ?? 'pending'),
      mosqueId: data['mosqueId']?.toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      commentsNotify:
          data['commentsNotify'] == null ? true : data['commentsNotify'] == true,
      verificationNotify: data['verificationNotify'] == null
          ? true
          : data['verificationNotify'] == true,
      acceptingQuestions: data['acceptingQuestions'] == null
          ? true
          : data['acceptingQuestions'] == true,
      specialties: specialtiesList,
      bio: data['bio']?.toString() ?? '',
      responseTime: data['responseTime']?.toString() ?? '',
      allowPrivateQuestions: data['allowPrivateQuestions'] == null
          ? true
          : data['allowPrivateQuestions'] == true,
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
      'commentsNotify': commentsNotify,
      'verificationNotify': verificationNotify,
      'acceptingQuestions': acceptingQuestions,
      'specialties': specialties,
      'fields': specialties, // legacy alias for compatibility
      'bio': bio,
      'responseTime': responseTime,
      'allowPrivateQuestions': allowPrivateQuestions,
    };
  }

  ImamModel copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? email,
    String? photo,
    ImamStatus? status,
    String? mosqueId,
    DateTime? createdAt,
    bool? commentsNotify,
    bool? verificationNotify,
    bool? acceptingQuestions,
    List<String>? specialties,
    String? bio,
    String? responseTime,
    bool? allowPrivateQuestions,
  }) {
    return ImamModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      photo: photo ?? this.photo,
      status: status ?? this.status,
      mosqueId: mosqueId ?? this.mosqueId,
      createdAt: createdAt ?? this.createdAt,
      commentsNotify: commentsNotify ?? this.commentsNotify,
      verificationNotify: verificationNotify ?? this.verificationNotify,
      acceptingQuestions: acceptingQuestions ?? this.acceptingQuestions,
      specialties: specialties ?? this.specialties,
      bio: bio ?? this.bio,
      responseTime: responseTime ?? this.responseTime,
      allowPrivateQuestions:
          allowPrivateQuestions ?? this.allowPrivateQuestions,
    );
  }
}
