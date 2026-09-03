import 'package:cloud_firestore/cloud_firestore.dart';

class MosqueModel {
  const MosqueModel({
    required this.id,
    required this.name,
    required this.country,
    required this.city,
    required this.address,
    required this.geopoint,
    this.photo,
    required this.contactPhone,
    required this.imamId,
    this.imamName,
    this.hasImam,
    required this.verified,
    required this.createdAt,
    this.capacity,
    this.calculationMethod = 4,
    this.acceptingQuestions = true,
    this.addedBy,
  });

  final String id;
  final String name;
  final String country;
  final String city;
  final String address;
  final GeoPoint geopoint;
  final String? photo;
  final String contactPhone;
  final String imamId;
  final String? imamName;
  final bool? hasImam;
  final bool verified;
  final DateTime createdAt;
  final int? capacity;
  /// Aladhan calculation method ID (default 4 = Umm al-Qura).
  final int calculationMethod;
  final bool acceptingQuestions;
  final String? addedBy;

  bool get isClaimed => (hasImam == true) || imamId.isNotEmpty;

  factory MosqueModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final imamIdVal = data['imamId'] as String? ?? '';
    final hasImamVal = data['hasImam'] as bool?;

    return MosqueModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      country: data['country'] as String? ?? '',
      city: data['city'] as String? ?? '',
      address: data['address'] as String? ?? '',
      geopoint: data['geopoint'] as GeoPoint? ?? const GeoPoint(0, 0),
      photo: data['photo'] as String?,
      contactPhone: data['contactPhone'] as String? ?? '',
      imamId: imamIdVal,
      imamName: data['imamName'] as String?,
      hasImam: hasImamVal ?? imamIdVal.isNotEmpty,
      verified: data['verified'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      capacity: data['capacity'] as int?,
      calculationMethod: data['calculationMethod'] as int? ?? 4,
      acceptingQuestions: data['acceptingQuestions'] == null
          ? true
          : data['acceptingQuestions'] == true,
      addedBy: data['addedBy']?.toString() ?? data['createdBy']?.toString(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'country': country,
      'city': city,
      'address': address,
      'geopoint': geopoint,
      if (photo != null) 'photo': photo,
      'contactPhone': contactPhone,
      'imamId': imamId,
      if (imamName != null) 'imamName': imamName,
      'hasImam': hasImam ?? imamId.isNotEmpty,
      'verified': verified,
      'createdAt': Timestamp.fromDate(createdAt),
      if (capacity != null) 'capacity': capacity,
      'calculationMethod': calculationMethod,
      'acceptingQuestions': acceptingQuestions,
      if (addedBy != null) 'addedBy': addedBy,
    };
  }

  MosqueModel copyWith({
    String? id,
    String? name,
    String? country,
    String? city,
    String? address,
    GeoPoint? geopoint,
    String? photo,
    String? contactPhone,
    String? imamId,
    String? imamName,
    bool? hasImam,
    bool? verified,
    DateTime? createdAt,
    int? capacity,
    int? calculationMethod,
    bool? acceptingQuestions,
    String? addedBy,
  }) {
    return MosqueModel(
      id: id ?? this.id,
      name: name ?? this.name,
      country: country ?? this.country,
      city: city ?? this.city,
      address: address ?? this.address,
      geopoint: geopoint ?? this.geopoint,
      photo: photo ?? this.photo,
      contactPhone: contactPhone ?? this.contactPhone,
      imamId: imamId ?? this.imamId,
      imamName: imamName ?? this.imamName,
      hasImam: hasImam ?? this.hasImam,
      verified: verified ?? this.verified,
      createdAt: createdAt ?? this.createdAt,
      capacity: capacity ?? this.capacity,
      calculationMethod: calculationMethod ?? this.calculationMethod,
      acceptingQuestions: acceptingQuestions ?? this.acceptingQuestions,
      addedBy: addedBy ?? this.addedBy,
    );
  }
}
