import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../domain/imam_model.dart';
import '../domain/imam_status.dart';
import '../domain/mosque_model.dart';

class RegistrationRepository {
  RegistrationRepository({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _firestore = firestore,
        _storage = storage;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

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

  Future<ImamModel?> getImam(String imamId) async {
    final doc = await _imams.doc(imamId).get();
    if (!doc.exists) return null;
    return ImamModel.fromFirestore(doc);
  }

  Future<String> uploadFile({
    required File file,
    required String path,
  }) async {
    final ref = _storage.ref().child(path);
    await ref.putFile(file);
    return ref.getDownloadURL();
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
      status: ImamStatus.pending,
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
    storage: ref.watch(firebaseStorageProvider),
  );
});

/// Streams the current signed-in user's imam profile (null if none).
final currentImamProvider = StreamProvider<ImamModel?>((ref) {
  final user = ref.watch(authStateChangesProvider).asData?.value;
  if (user == null) return Stream.value(null);
  return ref.watch(registrationRepositoryProvider).watchImam(user.uid);
});
