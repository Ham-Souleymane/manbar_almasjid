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
  }) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _imams =>
      _firestore.collection('imams');

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

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

  /// Streams all unclaimed mosques (where hasImam is false or imamId is empty/null).
  Stream<List<MosqueModel>> watchUnclaimedMosques() {
    return _mosques.snapshots().map((snap) {
      return snap.docs
          .map(MosqueModel.fromFirestore)
          .where((m) => !m.isClaimed)
          .toList();
    });
  }

  /// Gets all unclaimed mosques once.
  Future<List<MosqueModel>> getUnclaimedMosques() async {
    final snap = await _mosques.get();
    return snap.docs
        .map(MosqueModel.fromFirestore)
        .where((m) => !m.isClaimed)
        .toList();
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

    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(responseBody);
      return json['secure_url'];
    }

    throw Exception(
      'Cloudinary upload failed: '
      '${response.statusCode} - $responseBody',
    );
  }

  /// Claims an existing unclaimed mosque and creates the Imam profile atomically.
  Future<void> claimExistingMosque({
    required String imamId,
    required String fullName,
    required String phone,
    required String email,
    required String? verificationDocumentUrl,
    required String mosqueId,
    bool acceptingQuestions = true,
    List<String> specialties = const [],
    String bio = '',
    String responseTime = '',
    bool allowPrivateQuestions = true,
  }) async {
    final now = DateTime.now();

    final imam = ImamModel(
      id: imamId,
      fullName: fullName,
      phone: phone,
      email: email,
      photo: verificationDocumentUrl,
      status: ImamStatus.verified,
      mosqueId: mosqueId,
      createdAt: now,
      acceptingQuestions: acceptingQuestions,
      specialties: specialties,
      bio: bio,
      responseTime: responseTime,
      allowPrivateQuestions: allowPrivateQuestions,
    );

    final batch = _firestore.batch();

    // 1. Create/Update Imam Profile document in 'imams'
    batch.set(_imams.doc(imamId), imam.toFirestore(), SetOptions(merge: true));

    // 2. Also sync to 'users' collection if it exists for cross-compatibility
    batch.set(_users.doc(imamId), {
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'role': 'imam',
      'mosqueId': mosqueId,
      'acceptingQuestions': acceptingQuestions,
      'specialties': specialties,
      'bio': bio,
      'responseTime': responseTime,
      'allowPrivateQuestions': allowPrivateQuestions,
      'updatedAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));

    // 3. Atomically update the Mosque document
    batch.update(_mosques.doc(mosqueId), {
      'imamId': imamId,
      'imamName': fullName,
      'hasImam': true,
      'acceptingQuestions': acceptingQuestions,
      'updatedAt': Timestamp.fromDate(now),
    });

    await batch.commit();
  }

  /// Links an existing mosque to an Imam profile atomically.
  Future<void> linkMosqueToImam({
    required String imamId,
    required String mosqueId,
    required String imamName,
  }) async {
    final now = DateTime.now();
    final batch = _firestore.batch();

    batch.update(_imams.doc(imamId), {
      'mosqueId': mosqueId,
      'updatedAt': Timestamp.fromDate(now),
    });

    batch.set(_users.doc(imamId), {
      'mosqueId': mosqueId,
      'updatedAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));

    batch.update(_mosques.doc(mosqueId), {
      'imamId': imamId,
      'imamName': imamName,
      'hasImam': true,
      'updatedAt': Timestamp.fromDate(now),
    });

    await batch.commit();
  }

  /// Creates a new mosque and the Imam profile atomically.
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
    bool acceptingQuestions = true,
    List<String> specialties = const [],
    String bio = '',
    String responseTime = '',
    bool allowPrivateQuestions = true,
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
      acceptingQuestions: acceptingQuestions,
      specialties: specialties,
      bio: bio,
      responseTime: responseTime,
      allowPrivateQuestions: allowPrivateQuestions,
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
      imamName: fullName,
      hasImam: true,
      verified: false,
      createdAt: now,
      capacity: capacity,
      acceptingQuestions: acceptingQuestions,
    );

    final batch = _firestore.batch();

    // 1. Create Imam Profile in 'imams'
    batch.set(_imams.doc(imamId), imam.toFirestore());

    // 2. Sync to 'users' collection
    batch.set(_users.doc(imamId), {
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'role': 'imam',
      'mosqueId': mosqueRef.id,
      'acceptingQuestions': acceptingQuestions,
      'specialties': specialties,
      'bio': bio,
      'responseTime': responseTime,
      'allowPrivateQuestions': allowPrivateQuestions,
      'createdAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));

    // 3. Create Mosque
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

/// Streams all unclaimed mosques.
final unclaimedMosquesStreamProvider = StreamProvider<List<MosqueModel>>((ref) {
  return ref.watch(registrationRepositoryProvider).watchUnclaimedMosques();
});
