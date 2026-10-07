import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/app_localizations.dart';
import '../data/admin_repository.dart';
import '../../registration/domain/mosque_model.dart';

enum _MosqueViewMode { list, map }

class AllMosquesScreen extends ConsumerStatefulWidget {
  const AllMosquesScreen({super.key});

  @override
  ConsumerState<AllMosquesScreen> createState() => _AllMosquesScreenState();
}

class _AllMosquesScreenState extends ConsumerState<AllMosquesScreen> {
  String _query = '';
  _MosqueViewMode _viewMode = _MosqueViewMode.list;
  late final MapController _mapController;
  MosqueModel? _selectedMosque;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  bool _hasCoordinates(MosqueModel mosque) {
    return mosque.geopoint.latitude != 0 || mosque.geopoint.longitude != 0;
  }

  void _onShowOnMap(MosqueModel mosque) {
    setState(() {
      _viewMode = _MosqueViewMode.map;
      _selectedMosque = mosque;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_hasCoordinates(mosque)) {
        _mapController.move(
          LatLng(mosque.geopoint.latitude, mosque.geopoint.longitude),
          15,
        );
      }
    });
  }

  Future<void> _goToMyLocation() async {
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
                context.l10n.locale.languageCode == 'ar'
                    ? 'يرجى تفعيل إذن الوصول للموقع الجغرافي'
                    : 'Please grant location permission',
              ),
            ),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      _mapController.move(LatLng(pos.latitude, pos.longitude), 14);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _fitAllMosques(List<MosqueModel> mosquesWithCoords) {
    if (mosquesWithCoords.isEmpty) return;
    final points = mosquesWithCoords
        .map((m) => LatLng(m.geopoint.latitude, m.geopoint.longitude))
        .toList();

    if (points.length == 1) {
      _mapController.move(points.first, 15);
    } else {
      _mapController.fitCamera(
        CameraFit.coordinates(
          coordinates: points,
          padding: const EdgeInsets.all(60),
          maxZoom: 15,
        ),
      );
    }
  }

  Future<void> _openDirections(MosqueModel mosque) async {
    final lat = mosque.geopoint.latitude;
    final lng = mosque.geopoint.longitude;
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.error)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.l10n.error}: $e')),
        );
      }
    }
  }

  Future<void> _confirmAndDeleteMosque(MosqueModel mosque) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.deleteMosqueConfirmTitle,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text(l10n.deleteMosqueConfirmBody(mosque.name)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete,
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await ref
          .read(adminRepositoryProvider)
          .deleteMosqueAsAdmin(mosque.id);
      if (mounted) {
        setState(() {
          if (_selectedMosque?.id == mosque.id) {
            _selectedMosque = null;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.mosquePermanentlyDeleted),
            backgroundColor: const Color(0xFF0F766E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${l10n.deleteMosque}: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mosquesAsync = ref.watch(allMosquesProvider);
    final l10n = context.l10n;

    return Column(
      children: [
        // Top Search Bar and View Mode Switcher
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: l10n.searchMosqueHint,
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: Color(0xFF0F766E)),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  onChanged: (v) =>
                      setState(() => _query = v.trim().toLowerCase()),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: l10n.listView,
                      icon: Icon(
                        Icons.view_list_rounded,
                        color: _viewMode == _MosqueViewMode.list
                            ? const Color(0xFF0F766E)
                            : Colors.grey,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: _viewMode == _MosqueViewMode.list
                            ? const Color(0xFFE5F3F1)
                            : Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () =>
                          setState(() => _viewMode = _MosqueViewMode.list),
                    ),
                    IconButton(
                      tooltip: l10n.mapView,
                      icon: Icon(
                        Icons.map_rounded,
                        color: _viewMode == _MosqueViewMode.map
                            ? const Color(0xFF0F766E)
                            : Colors.grey,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: _viewMode == _MosqueViewMode.map
                            ? const Color(0xFFE5F3F1)
                            : Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () =>
                          setState(() => _viewMode = _MosqueViewMode.map),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Main Body: List View or Map View
        Expanded(
          child: mosquesAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF0F766E))),
            error: (e, _) => Center(child: Text('${l10n.error}: $e')),
            data: (mosques) {
              final filtered = _query.isEmpty
                  ? mosques
                  : mosques
                      .where((m) =>
                          m.name.toLowerCase().contains(_query) ||
                          m.city.toLowerCase().contains(_query) ||
                          m.country.toLowerCase().contains(_query))
                      .toList();

              if (_viewMode == _MosqueViewMode.list) {
                if (filtered.isEmpty) {
                  return Center(
                      child: Text(l10n.noMatchingMosques,
                          style: const TextStyle(color: Colors.black45)));
                }
                return RefreshIndicator(
                  color: const Color(0xFF0F766E),
                  onRefresh: () async => ref.invalidate(allMosquesProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) => _MosqueCard(
                      mosque: filtered[i],
                      hasCoords: _hasCoordinates(filtered[i]),
                      onShowOnMap: () => _onShowOnMap(filtered[i]),
                      onDelete: () => _confirmAndDeleteMosque(filtered[i]),
                    ),
                  ),
                );
              }

              // Map View
              final validMosques = filtered.where(_hasCoordinates).toList();
              final initialCenter = validMosques.isNotEmpty
                  ? LatLng(validMosques.first.geopoint.latitude,
                      validMosques.first.geopoint.longitude)
                  : const LatLng(21.4225, 39.8262); // Mecca fallback

              return Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: initialCenter,
                      initialZoom: validMosques.isNotEmpty ? 12 : 5,
                      onTap: (_, __) {
                        if (_selectedMosque != null) {
                          setState(() => _selectedMosque = null);
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.manbar.manbarAlmasjid',
                      ),
                      MarkerLayer(
                        markers: validMosques.map((mosque) {
                          final point = LatLng(mosque.geopoint.latitude,
                              mosque.geopoint.longitude);
                          final isSelected = _selectedMosque?.id == mosque.id;

                          return Marker(
                            point: point,
                            width: isSelected ? 52 : 42,
                            height: isSelected ? 52 : 42,
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _selectedMosque = mosque);
                                _mapController.move(point, 15);
                              },
                              child: AnimatedScale(
                                scale: isSelected ? 1.15 : 1.0,
                                duration: const Duration(milliseconds: 200),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF134E4A)
                                            : const Color(0xFF0F766E),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.amber
                                              : Colors.white,
                                          width: isSelected ? 3 : 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (isSelected
                                                    ? const Color(0xFF0F766E)
                                                    : Colors.black)
                                                .withValues(
                                                    alpha:
                                                        isSelected ? 0.45 : 0.25),
                                            blurRadius: isSelected ? 8 : 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      padding:
                                          EdgeInsets.all(isSelected ? 9 : 7),
                                      child: const Icon(
                                        Icons.mosque_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    if (mosque.verified)
                                      Positioned(
                                        top: -2,
                                        right: -2,
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(1),
                                          child: const Icon(
                                            Icons.verified_rounded,
                                            color: Color(0xFF0F766E),
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                  // Top overlay: Mosque count chip
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.mosque_rounded,
                              size: 16, color: Color(0xFF0F766E)),
                          const SizedBox(width: 6),
                          Text(
                            l10n.mosquesOnMapCount(validMosques.length),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F766E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Top right: Floating controls (Fit bounds & My location)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FloatingActionButton.small(
                          heroTag: 'fit_all_mosques_fab',
                          tooltip: l10n.fitAllMosques,
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0F766E),
                          elevation: 3,
                          onPressed: () => _fitAllMosques(validMosques),
                          child: const Icon(Icons.crop_free_rounded),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: 'my_location_mosques_fab',
                          tooltip: l10n.locale.languageCode == 'ar'
                              ? 'موقعي'
                              : 'My Location',
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0F766E),
                          elevation: 3,
                          onPressed: _locating ? null : _goToMyLocation,
                          child: _locating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF0F766E),
                                  ),
                                )
                              : const Icon(Icons.my_location_rounded),
                        ),
                      ],
                    ),
                  ),

                  // No mosques warning overlay if empty
                  if (validMosques.isEmpty)
                    Positioned(
                      top: 70,
                      left: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_off_rounded,
                                color: Colors.orange),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l10n.noMosquesWithLocation,
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Bottom floating selection card
                  if (_selectedMosque != null)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: _MosqueDetailCard(
                        mosque: _selectedMosque!,
                        onClose: () => setState(() => _selectedMosque = null),
                        onDirections: () => _openDirections(_selectedMosque!),
                        onDelete: () =>
                            _confirmAndDeleteMosque(_selectedMosque!),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MosqueDetailCard extends StatelessWidget {
  final MosqueModel mosque;
  final VoidCallback onClose;
  final VoidCallback onDirections;
  final VoidCallback onDelete;

  const _MosqueDetailCard({
    required this.mosque,
    required this.onClose,
    required this.onDirections,
    required this.onDelete,
  });

  Widget _placeholderIcon() {
    return Container(
      width: 58,
      height: 58,
      color: const Color(0xFFE5F3F1),
      child:
          const Icon(Icons.mosque_rounded, color: Color(0xFF0F766E), size: 28),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isAr = l10n.locale.languageCode == 'ar';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      shadowColor: Colors.black38,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: mosque.photo != null
                      ? Image.network(
                          mosque.photo!,
                          width: 58,
                          height: 58,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholderIcon(),
                        )
                      : _placeholderIcon(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              mosque.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (mosque.verified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified_rounded,
                              color: Color(0xFF0F766E),
                              size: 18,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 14, color: Colors.black54),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${mosque.city}، ${mosque.country}${mosque.address.isNotEmpty ? ' - ${mosque.address}' : ''}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            mosque.isClaimed
                                ? Icons.person_rounded
                                : Icons.person_outline_rounded,
                            size: 14,
                            color: mosque.isClaimed
                                ? const Color(0xFF0F766E)
                                : Colors.black45,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              mosque.isClaimed &&
                                      mosque.imamName != null &&
                                      mosque.imamName!.isNotEmpty
                                  ? mosque.imamName!
                                  : (isAr ? 'بدون إمام مسجل' : 'Unclaimed / No Imam'),
                              style: TextStyle(
                                fontSize: 12,
                                color: mosque.isClaimed
                                    ? const Color(0xFF0F766E)
                                    : Colors.black45,
                                fontWeight: mosque.isClaimed
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 20, color: Colors.black45),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onClose,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.directions_rounded, size: 18),
                    label: Text(l10n.openInMaps,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                    onPressed: onDirections,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red.shade200),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  ),
                  icon: const Icon(Icons.delete_forever_rounded, size: 18),
                  label: Text(l10n.delete,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold)),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MosqueCard extends StatelessWidget {
  final MosqueModel mosque;
  final bool hasCoords;
  final VoidCallback onShowOnMap;
  final VoidCallback onDelete;

  const _MosqueCard({
    required this.mosque,
    required this.hasCoords,
    required this.onShowOnMap,
    required this.onDelete,
  });

  Widget _placeholderIcon() {
    return Container(
      width: 56,
      height: 56,
      color: const Color(0xFFE5F3F1),
      child:
          const Icon(Icons.mosque_rounded, color: Color(0xFF0F766E), size: 28),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Mosque photo or icon
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: mosque.photo != null
                  ? Image.network(
                      mosque.photo!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderIcon(),
                    )
                  : _placeholderIcon(),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          mosque.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (mosque.verified)
                        const Icon(Icons.verified_rounded,
                            color: Color(0xFF0F766E), size: 18),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${mosque.city}، ${mosque.country}',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            // "Show on Map" action button
            if (hasCoords)
              IconButton(
                tooltip: l10n.showOnMap,
                icon: const Icon(Icons.map_rounded,
                    color: Color(0xFF0F766E)),
                onPressed: onShowOnMap,
              ),
            // Actions (Delete)
            IconButton(
              tooltip: l10n.deleteMosque,
              icon: const Icon(Icons.delete_forever_rounded,
                  color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
