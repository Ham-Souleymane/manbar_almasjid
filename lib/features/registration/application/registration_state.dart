import 'dart:io';

import 'package:latlong2/latlong.dart';

class RegistrationState {
  const RegistrationState({
    this.fullName = '',
    this.phone = '',
    this.email = '',
    this.verificationDocument,
    this.mosqueName = '',
    this.country = '',
    this.countryCode = '',
    this.city = '',
    this.address = '',
    this.location,
    this.mosquePhoto,
    this.capacity,
    this.contactPhone = '',
    this.isSubmitting = false,
    this.errorMessage,
  });

  final String fullName;
  final String phone;
  final String email;
  final File? verificationDocument;
  final String mosqueName;
  final String country;
  final String countryCode;
  final String city;
  final String address;
  final LatLng? location;
  final File? mosquePhoto;
  final int? capacity;
  final String contactPhone;
  final bool isSubmitting;
  final String? errorMessage;

  RegistrationState copyWith({
    String? fullName,
    String? phone,
    String? email,
    File? verificationDocument,
    bool clearVerificationDocument = false,
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
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
