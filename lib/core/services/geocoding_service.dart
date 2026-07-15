import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

class GeocodingResult {
  const GeocodingResult({
    this.city,
    this.country,
    this.address,
  });

  final String? city;
  final String? country;
  final String? address;
}

class GeocodingService {
  Future<GeocodingResult> reverseGeocode(LatLng location) async {
    try {
      final placemarks = await Geocoding().placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (placemarks.isEmpty) return const GeocodingResult();

      final place = placemarks.first;
      final city = _firstNonEmpty([
        place.locality,
        place.subAdministrativeArea,
        place.administrativeArea,
      ]);
      final country = place.country;
      final address = _firstNonEmpty([
        place.street,
        place.subLocality,
        place.name,
      ]);

      return GeocodingResult(
        city: city,
        country: country,
        address: address,
      );
    } catch (_) {
      return const GeocodingResult();
    }
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }
}
