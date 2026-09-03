import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../core/services/geocoding_service.dart';
import '../data/registration_repository.dart';
import '../domain/mosque_model.dart';
import 'registration_state.dart';

class RegistrationController extends Notifier<RegistrationState> {
  @override
  RegistrationState build() => const RegistrationState();

  RegistrationRepository get _repo => ref.read(registrationRepositoryProvider);
  GeocodingService get _geocoding => ref.read(geocodingServiceProvider);

  void setImamStep({
    required String fullName,
    required String phone,
    required String email,
    File? verificationDocument,
  }) {
    state = state.copyWith(
      fullName: fullName.trim(),
      phone: phone.trim(),
      email: email.trim(),
      verificationDocument: verificationDocument,
      clearError: true,
    );
  }

  void setIsClaimingExisting(bool isClaiming) {
    state = state.copyWith(
      isClaimingExisting: isClaiming,
      clearError: true,
    );
  }

  void selectUnclaimedMosque(MosqueModel mosque) {
    state = state.copyWith(
      isClaimingExisting: true,
      selectedMosque: mosque,
      mosqueName: mosque.name,
      country: mosque.country,
      city: mosque.city,
      address: mosque.address,
      location: LatLng(mosque.geopoint.latitude, mosque.geopoint.longitude),
      contactPhone: mosque.contactPhone,
      clearError: true,
    );
  }

  void setMosqueFields({
    String? mosqueName,
    String? country,
    String? countryCode,
    String? city,
    String? address,
    LatLng? location,
    File? mosquePhoto,
    int? capacity,
    String? contactPhone,
  }) {
    state = state.copyWith(
      isClaimingExisting: false,
      clearSelectedMosque: true,
      mosqueName: mosqueName,
      country: country,
      countryCode: countryCode,
      city: city,
      address: address,
      location: location,
      mosquePhoto: mosquePhoto,
      capacity: capacity,
      contactPhone: contactPhone,
      clearError: true,
    );
  }

  void setAskFeatureFields({
    bool? acceptingQuestions,
    List<String>? specialties,
    String? bio,
    String? responseTime,
    bool? allowPrivateQuestions,
  }) {
    state = state.copyWith(
      acceptingQuestions: acceptingQuestions ?? state.acceptingQuestions,
      specialties: specialties ?? state.specialties,
      bio: bio ?? state.bio,
      responseTime: responseTime ?? state.responseTime,
      allowPrivateQuestions:
          allowPrivateQuestions ?? state.allowPrivateQuestions,
      clearError: true,
    );
  }

  Future<void> updateLocationFromMap(LatLng location) async {
    state = state.copyWith(location: location, clearError: true);

    final result = await _geocoding.reverseGeocode(location);
    state = state.copyWith(
      city: result.city ?? state.city,
      country: result.country ?? state.country,
      address: result.address ?? state.address,
    );
  }

  Future<bool> submitRegistration() async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      state = state.copyWith(errorMessage: 'يجب تسجيل الدخول أولاً.');
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      String? verificationUrl;
      if (state.verificationDocument != null) {
        verificationUrl = await _repo.uploadFile(
          file: state.verificationDocument!,
          path:
              'imams/${user.uid}/verification_${DateTime.now().millisecondsSinceEpoch}',
        );
      }

      // Case A: Claiming existing mosque
      if (state.isClaimingExisting && state.selectedMosque != null) {
        await _repo.claimExistingMosque(
          imamId: user.uid,
          fullName: state.fullName,
          phone: state.phone,
          email: state.email.isNotEmpty ? state.email : (user.email ?? ''),
          verificationDocumentUrl: verificationUrl,
          mosqueId: state.selectedMosque!.id,
          acceptingQuestions: state.acceptingQuestions,
          specialties: state.specialties,
          bio: state.bio,
          responseTime: state.responseTime,
          allowPrivateQuestions: state.allowPrivateQuestions,
        );
      } else {
        // Case B: Creating new mosque
        if (state.location == null) {
          state = state.copyWith(
            isSubmitting: false,
            errorMessage: 'يرجى تحديد موقع المسجد على الخريطة.',
          );
          return false;
        }

        String? mosquePhotoUrl;
        if (state.mosquePhoto != null) {
          mosquePhotoUrl = await _repo.uploadFile(
            file: state.mosquePhoto!,
            path:
                'mosques/${user.uid}/photo_${DateTime.now().millisecondsSinceEpoch}',
          );
        }

        await _repo.submitRegistration(
          imamId: user.uid,
          fullName: state.fullName,
          phone: state.phone,
          email: state.email.isNotEmpty ? state.email : (user.email ?? ''),
          verificationDocumentUrl: verificationUrl,
          mosqueName: state.mosqueName,
          country: state.country,
          city: state.city,
          address: state.address,
          geopoint: GeoPoint(
            state.location!.latitude,
            state.location!.longitude,
          ),
          mosquePhotoUrl: mosquePhotoUrl,
          contactPhone: state.contactPhone,
          capacity: state.capacity,
          acceptingQuestions: state.acceptingQuestions,
          specialties: state.specialties,
          bio: state.bio,
          responseTime: state.responseTime,
          allowPrivateQuestions: state.allowPrivateQuestions,
        );
      }

      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'فشل حفظ البيانات: $e',
      );
      return false;
    }
  }

  void reset() {
    state = const RegistrationState();
  }
}

final geocodingServiceProvider = Provider<GeocodingService>((ref) {
  return GeocodingService();
});

final registrationControllerProvider =
    NotifierProvider<RegistrationController, RegistrationState>(
  RegistrationController.new,
);
