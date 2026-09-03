import 'package:cloud_firestore/cloud_firestore.dart';

class MosqueModel {
  final String id;
  final String name;
  final String imamName;
  final String imamPhone;
  final String description;
  final String city;
  final String address;
  final String logoUrl;
  final String coverUrl;
  final bool isVerified;
  final String imamStatus; // "pending" | "approved" | "rejected"
  final GeoPoint? geopoint;
  final int? capacity;

  MosqueModel({
    required this.id,
    required this.name,
    required this.imamName,
    required this.imamPhone,
    required this.description,
    required this.city,
    required this.address,
    required this.logoUrl,
    required this.coverUrl,
    required this.isVerified,
    required this.imamStatus,
    this.geopoint,
    this.capacity,
  });

  factory MosqueModel.fromMap(String id, Map<String, dynamic> data) {
    return MosqueModel(
      id: id,
      name: data['name'] ?? '',
      imamName: data['imamName'] ?? '',
      imamPhone: data['imamPhone'] ?? data['contactPhone'] ?? '',
      description: data['description'] ?? '',
      city: data['city'] ?? '',
      address: data['address'] ?? '',
      logoUrl: data['logoUrl'] ?? data['photo'] ?? '',
      coverUrl: data['coverUrl'] ?? '',
      isVerified: (data['isVerified'] as bool?) ?? (data['verified'] as bool?) ?? false,
      imamStatus: data['imamStatus'] ?? 'pending',
      geopoint: data['geopoint'] as GeoPoint?,
      capacity: data['capacity'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imamName': imamName,
      'imamPhone': imamPhone,
      'description': description,
      'city': city,
      'address': address,
      'logoUrl': logoUrl,
      'coverUrl': coverUrl,
      'isVerified': isVerified,
      'imamStatus': imamStatus,
      if (geopoint != null) 'geopoint': geopoint,
      if (capacity != null) 'capacity': capacity,
    };
  }
}
