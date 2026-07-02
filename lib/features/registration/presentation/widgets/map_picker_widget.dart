import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';

class MapPickerWidget extends StatefulWidget {
  const MapPickerWidget({
    super.key,
    required this.location,
    required this.onLocationChanged,
    this.isLoadingLocation = false,
  });

  final LatLng? location;
  final Future<void> Function(LatLng location) onLocationChanged;
  final bool isLoadingLocation;

  @override
  State<MapPickerWidget> createState() => _MapPickerWidgetState();
}

class _MapPickerWidgetState extends State<MapPickerWidget> {
  static const _defaultCenter = LatLng(24.7136, 46.6753); // Riyadh as neutral default
  late final MapController _mapController;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  LatLng get _center => widget.location ?? _defaultCenter;

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'يرجى السماح بالوصول إلى الموقع',
                style: GoogleFonts.tajawal(),
              ),
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final location = LatLng(position.latitude, position.longitude);
      _mapController.move(location, 15);
      await widget.onLocationChanged(location);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 220,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: widget.location != null ? 15 : 4,
                    onTap: (_, point) => widget.onLocationChanged(point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.manbar.manbarAlmasjid',
                    ),
                    if (widget.location != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: widget.location!,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              color: AppColors.emerald,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (widget.isLoadingLocation)
                  Container(
                    color: Colors.black26,
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        AppButton(
          label: 'تحديد موقعي على الخريطة',
          icon: Icons.my_location_rounded,
          style: AppButtonStyle.secondary,
          isLoading: _locating,
          onPressed: _locating ? null : _useMyLocation,
        ),
        const SizedBox(height: 8),
        Text(
          widget.location != null
              ? 'اضغط على الخريطة لتعديل موقع الدبوس'
              : 'اضغط على الخريطة أو استخدم زر تحديد الموقع',
          style: GoogleFonts.tajawal(
            fontSize: 12,
            color: AppColors.grey500,
          ),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
