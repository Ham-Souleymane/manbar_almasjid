import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:http/http.dart' as http;

import '../../../core/providers/firebase_providers.dart';
import '../domain/imam_model.dart';
import '../domain/imam_status.dart';
import '../domain/mosque_model.dart';

class RegistrationRepository {
  RegistrationRepository({
    required FirebaseFirestore firestore,
  })  : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _imams =>
      _firestore.collection('imams');

  CollectionReference<Map<String, dynamic>> get _mosques =>
      _firestore.collection('mosques');

  Stream<ImamModel?> watchImam(String imamId) {
    return _imams.doc(imamId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ImamModel.fromFirestore(doc);
    });
  }

  Stream<MosqueModel?> watchMosque(String mosqueId) {
    return _mosques.doc(mosqueId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return MosqueModel.fromFirestore(doc);
    });
  }

  Future<ImamModel?> getImam(String imamId) async {
    final doc = await _imams.doc(imamId).get();
    if (!doc.exists) return null;
    return ImamModel.fromFirestore(doc);
  }

 Future<String> uploadFile({
  required File file,
  required String path,
}) async {
  const cloudName = 'vbc9yur2';
  const uploadPreset = 'ml_default';

  final url = Uri.parse(
    'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
  );

  final request = http.MultipartRequest(
    'POST',
    url,
  );

  request.fields['upload_preset'] = uploadPreset;

  request.files.add(
    await http.MultipartFile.fromPath(
      'file',
      file.path,
    ),
  );

  final response = await request.send();

  final responseBody =
      await response.stream.bytesToString();

  if (response.statusCode == 200 ||
      response.statusCode == 201) {
    final json = jsonDecode(responseBody);
    return json['secure_url'];
  }

  throw Exception(
    'Cloudinary upload failed: '
    '${response.statusCode} - $responseBody',
  );
}

  Future<void> submitRegistration({
    required String imamId,
    required String fullName,
    required String phone,
    required String email,
    required String? verificationDocumentUrl,
    required String mosqueName,
    required String country,
    required String city,
    required String address,
    required GeoPoint geopoint,
    required String? mosquePhotoUrl,
    required String contactPhone,
    required int? capacity,
  }) async {
    final mosqueRef = _mosques.doc();
    final now = DateTime.now();

    final imam = ImamModel(
      id: imamId,
      fullName: fullName,
      phone: phone,
      email: email,
      photo: verificationDocumentUrl,
      status: ImamStatus.verified,
      mosqueId: mosqueRef.id,
      createdAt: now,
    );

    final mosque = MosqueModel(
      id: mosqueRef.id,
      name: mosqueName,
      country: country,
      city: city,
      address: address,
      geopoint: geopoint,
      photo: mosquePhotoUrl,
      contactPhone: contactPhone,
      imamId: imamId,
      verified: false,
      createdAt: now,
      capacity: capacity,
    );

    final batch = _firestore.batch();
    batch.set(_imams.doc(imamId), imam.toFirestore());
    batch.set(mosqueRef, mosque.toFirestore());
    await batch.commit();
  }
}

final registrationRepositoryProvider = Provider<RegistrationRepository>((ref) {
  return RegistrationRepository(
    firestore: ref.watch(firestoreProvider),
  );
});

/// Streams the current signed-in user's imam profile (null if none).
final currentImamProvider = StreamProvider<ImamModel?>((ref) {
  final user = ref.watch(authStateChangesProvider).asData?.value;
  if (user == null) return Stream.value(null);
  return ref.watch(registrationRepositoryProvider).watchImam(user.uid);
});

/// Streams the mosque linked to the current imam (null if imam or mosque not found).
final currentMosqueProvider = StreamProvider<MosqueModel?>((ref) {
  final imam = ref.watch(currentImamProvider).asData?.value;
  if (imam == null || imam.mosqueId == null) return Stream.value(null);
  return ref.watch(registrationRepositoryProvider).watchMosque(imam.mosqueId!);
});
