import 'dart:io';

import 'package:latlong2/latlong.dart';
import '../domain/mosque_model.dart';

class RegistrationState {
  const RegistrationState({
    this.fullName = '',
    this.phone = '',
    this.email = '',
    this.verificationDocument,
    this.isClaimingExisting = false,
    this.selectedMosque,
    this.mosqueName = '',
    this.country = '',
    this.countryCode = '',
    this.city = '',
    this.address = '',
    this.location,
    this.mosquePhoto,
    this.capacity,
    this.contactPhone = '',
    this.acceptingQuestions = true,
    this.specialties = const [],
    this.bio = '',
    this.responseTime = '',
    this.allowPrivateQuestions = true,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final String fullName;
  final String phone;
  final String email;
  final File? verificationDocument;

  // ── Mosque step state ─────────────────────────────────────────
  final bool isClaimingExisting;
  final MosqueModel? selectedMosque;
  final String mosqueName;
  final String country;
  final String countryCode;
  final String city;
  final String address;
  final LatLng? location;
  final File? mosquePhoto;
  final int? capacity;
  final String contactPhone;

  // ── Ask Sheikh step state ─────────────────────────────────────
  final bool acceptingQuestions;
  final List<String> specialties;
  final String bio;
  final String responseTime;
  final bool allowPrivateQuestions;

  final bool isSubmitting;
  final String? errorMessage;

  RegistrationState copyWith({
    String? fullName,
    String? phone,
    String? email,
    File? verificationDocument,
    bool clearVerificationDocument = false,
    bool? isClaimingExisting,
    MosqueModel? selectedMosque,
    bool clearSelectedMosque = false,
    String? mosqueName,
    String? country,
    String? countryCode,
    String? city,
    String? address,
    LatLng? location,
    bool clearLocation = false,
    File? mosquePhoto,
    bool clearMosquePhoto = false,
    int? capacity,
    bool clearCapacity = false,
    String? contactPhone,
    bool? acceptingQuestions,
    List<String>? specialties,
    String? bio,
    String? responseTime,
    bool? allowPrivateQuestions,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RegistrationState(
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      verificationDocument: clearVerificationDocument
          ? null
          : (verificationDocument ?? this.verificationDocument),
      isClaimingExisting: isClaimingExisting ?? this.isClaimingExisting,
      selectedMosque: clearSelectedMosque
          ? null
          : (selectedMosque ?? this.selectedMosque),
      mosqueName: mosqueName ?? this.mosqueName,
      country: country ?? this.country,
      countryCode: countryCode ?? this.countryCode,
      city: city ?? this.city,
      address: address ?? this.address,
      location: clearLocation ? null : (location ?? this.location),
      mosquePhoto:
          clearMosquePhoto ? null : (mosquePhoto ?? this.mosquePhoto),
      capacity: clearCapacity ? null : (capacity ?? this.capacity),
      contactPhone: contactPhone ?? this.contactPhone,
      acceptingQuestions: acceptingQuestions ?? this.acceptingQuestions,
      specialties: specialties ?? this.specialties,
      bio: bio ?? this.bio,
      responseTime: responseTime ?? this.responseTime,
      allowPrivateQuestions:
          allowPrivateQuestions ?? this.allowPrivateQuestions,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
