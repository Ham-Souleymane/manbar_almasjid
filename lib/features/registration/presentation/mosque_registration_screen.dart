import 'dart:io';

import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../auth/presentation/widgets/auth_text_field.dart';
import '../application/registration_controller.dart';
import '../application/registration_state.dart';
import '../data/registration_repository.dart';
import '../domain/mosque_model.dart';
import 'widgets/document_upload_area.dart';
import 'widgets/map_picker_widget.dart';
import 'widgets/registration_progress_indicator.dart';
import 'widgets/unclaimed_mosque_card.dart';

class MosqueRegistrationScreen extends ConsumerStatefulWidget {
  const MosqueRegistrationScreen({super.key});

  @override
  ConsumerState<MosqueRegistrationScreen> createState() =>
      _MosqueRegistrationScreenState();
}

class _MosqueRegistrationScreenState
    extends ConsumerState<MosqueRegistrationScreen> {
  int _selectedTab = 0; // 0 = Select Existing, 1 = Add New
  final _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();

  String _searchQuery = '';
  String _country = '';
  String _countryCode = '';
  File? _mosquePhoto;
  bool _isGeocoding = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    final regState = ref.read(registrationControllerProvider);
    _nameController.text = regState.mosqueName;
    _cityController.text = regState.city;
    _addressController.text = regState.address;
    _contactController.text = regState.contactPhone;
    _country = regState.country;
    _countryCode = regState.countryCode;

    if (regState.isClaimingExisting) {
      _selectedTab = 0;
    }

    _determinePosition();
  }

  Future<void> _determinePosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      if (mounted) {
        setState(() => _currentPosition = pos);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  void _pickCountry() {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      onSelect: (country) {
        setState(() {
          _country = country.name;
          _countryCode = country.countryCode;
        });
      },
    );
  }

  Future<void> _onLocationChanged(LatLng location) async {
    setState(() => _isGeocoding = true);
    await ref
        .read(registrationControllerProvider.notifier)
        .updateLocationFromMap(location);

    if (!mounted) return;
    final regState = ref.read(registrationControllerProvider);
    setState(() {
      _isGeocoding = false;
      if (regState.city.isNotEmpty) _cityController.text = regState.city;
      if (regState.country.isNotEmpty) _country = regState.country;
      if (regState.address.isNotEmpty) {
        _addressController.text = regState.address;
      }
    });
  }

  void _confirmAndSelectMosque(MosqueModel mosque) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.verified_outlined, color: AppColors.emerald),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.claimMosqueConfirmTitle,
                style: GoogleFonts.tajawal(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.emeraldDark,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          l10n.claimMosqueConfirmMessage(mosque.name, mosque.city),
          style: GoogleFonts.tajawal(fontSize: 14, color: AppColors.charcoal),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              l10n.cancel,
              style: GoogleFonts.tajawal(color: AppColors.grey700),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref
                  .read(registrationControllerProvider.notifier)
                  .selectUnclaimedMosque(mosque);
              context.showSnackBar(l10n.mosqueSelected);
              context.go(AppRoutes.askFeatureSetup);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              l10n.confirmClaim,
              style: GoogleFonts.tajawal(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _proceedToAskSetupForNewMosque() {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;
    if (_country.isEmpty) {
      context.showSnackBar(l10n.selectCountryFirst, isError: true);
      return;
    }

    final regState = ref.read(registrationControllerProvider);
    if (regState.location == null) {
      context.showSnackBar(l10n.selectMosqueLocation, isError: true);
      return;
    }

    ref.read(registrationControllerProvider.notifier).setMosqueFields(
          mosqueName: _nameController.text.trim(),
          country: _country,
          countryCode: _countryCode,
          city: _cityController.text.trim(),
          address: _addressController.text.trim(),
          mosquePhoto: _mosquePhoto,
          contactPhone: _contactController.text.trim(),
          capacity: null,
        );

    context.go(AppRoutes.askFeatureSetup);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final regState = ref.watch(registrationControllerProvider);
    final unclaimedMosquesAsync = ref.watch(unclaimedMosquesStreamProvider);

    return LoadingOverlay(
      isLoading: regState.isSubmitting,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          title: Text(l10n.registerMosque),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(AppRoutes.registerImam),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RegistrationProgressIndicator(
                      currentStep: 2,
                      totalSteps: 3,
                      stepTitle: l10n.mosqueData,
                    ),
                    const SizedBox(height: 16),
                    // Segmented Selector Tabs
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: _TabButton(
                              title: l10n.selectExistingMosque,
                              icon: Icons.search_rounded,
                              isSelected: _selectedTab == 0,
                              onTap: () {
                                setState(() => _selectedTab = 0);
                                ref
                                    .read(registrationControllerProvider.notifier)
                                    .setIsClaimingExisting(true);
                              },
                            ),
                          ),
                          Expanded(
                            child: _TabButton(
                              title: l10n.addNewMosque,
                              icon: Icons.add_business_outlined,
                              isSelected: _selectedTab == 1,
                              onTap: () {
                                setState(() => _selectedTab = 1);
                                ref
                                    .read(registrationControllerProvider.notifier)
                                    .setIsClaimingExisting(false);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Tab View Content
              Expanded(
                child: _selectedTab == 0
                    ? _buildSelectExistingTab(l10n, unclaimedMosquesAsync, regState)
                    : _buildAddNewMosqueTab(l10n, regState),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectExistingTab(
    AppLocalizations l10n,
    AsyncValue<List<MosqueModel>> unclaimedMosquesAsync,
    RegistrationState regState,
  ) {
    return Column(
      children: [
        // Search Input
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: l10n.searchMosquePlaceholder,
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.emerald),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              fillColor: Colors.white,
              filled: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.grey300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.grey300),
              ),
            ),
          ),
        ),
        // List of Unclaimed Mosques
        Expanded(
          child: unclaimedMosquesAsync.when(
            loading: () => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.emerald),
                  const SizedBox(height: 12),
                  Text(
                    l10n.loadingUnclaimedMosques,
                    style: GoogleFonts.tajawal(color: AppColors.grey700),
                  ),
                ],
              ),
            ),
            error: (err, _) => Center(
              child: Text(
                '${l10n.error}: $err',
                style: GoogleFonts.tajawal(color: AppColors.error),
              ),
            ),
            data: (mosques) {
              final filtered = mosques.where((m) {
                if (_searchQuery.isEmpty) return true;
                final name = m.name.toLowerCase();
                final city = m.city.toLowerCase();
                final address = m.address.toLowerCase();
                return name.contains(_searchQuery) ||
                    city.contains(_searchQuery) ||
                    address.contains(_searchQuery);
              }).toList();

              // Sort by distance if current GPS location is available
              if (_currentPosition != null) {
                filtered.sort((a, b) {
                  final distA = Geolocator.distanceBetween(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                    a.geopoint.latitude,
                    a.geopoint.longitude,
                  );
                  final distB = Geolocator.distanceBetween(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                    b.geopoint.latitude,
                    b.geopoint.longitude,
                  );
                  return distA.compareTo(distB);
                });
              }

              if (filtered.isEmpty) {
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: AppColors.emeraldPale,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.mosque_outlined,
                            size: 48,
                            color: AppColors.emerald,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noUnclaimedMosquesFound,
                          style: GoogleFonts.tajawal(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.emeraldDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.cantFindYourMosque,
                          style: GoogleFonts.tajawal(
                            fontSize: 14,
                            color: AppColors.grey700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() => _selectedTab = 1);
                            ref
                                .read(registrationControllerProvider.notifier)
                                .setIsClaimingExisting(false);
                          },
                          icon: const Icon(Icons.add_location_alt_outlined),
                          label: Text(l10n.clickToRegisterNewMosque),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.emerald,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                itemCount: filtered.length + 1,
                itemBuilder: (context, index) {
                  if (index == filtered.length) {
                    // Quick footer prompt to add new mosque if not found
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() => _selectedTab = 1);
                            ref
                                .read(registrationControllerProvider.notifier)
                                .setIsClaimingExisting(false);
                          },
                          icon: const Icon(Icons.add_circle_outline, size: 18),
                          label: Text(
                            '${l10n.cantFindYourMosque} ${l10n.clickToRegisterNewMosque}',
                            style: GoogleFonts.tajawal(
                              fontWeight: FontWeight.w700,
                              color: AppColors.emerald,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  final mosque = filtered[index];
                  final isSelected = regState.selectedMosque?.id == mosque.id;
                  double? distance;
                  if (_currentPosition != null) {
                    distance = Geolocator.distanceBetween(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                      mosque.geopoint.latitude,
                      mosque.geopoint.longitude,
                    );
                  }

                  return UnclaimedMosqueCard(
                    mosque: mosque,
                    isSelected: isSelected,
                    distanceMeters: distance,
                    onSelect: () => _confirmAndSelectMosque(mosque),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddNewMosqueTab(AppLocalizations l10n, RegistrationState regState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthTextField(
              label: l10n.mosqueName,
              hint: l10n.mosqueNameHint,
              controller: _nameController,
              prefixIcon: Icons.mosque_outlined,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return l10n.enterMosqueName;
                return null;
              },
            ),
            const SizedBox(height: 16),
            _CountryPickerField(
              country: _country,
              onTap: _pickCountry,
              label: l10n.countryLabel,
              placeholder: l10n.chooseCountry,
            ),
            const SizedBox(height: 16),
            AuthTextField(
              label: l10n.city,
              hint: l10n.cityHint,
              controller: _cityController,
              prefixIcon: Icons.location_city_outlined,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return l10n.enterCity;
                return null;
              },
            ),
            const SizedBox(height: 16),
            AuthTextField(
              label: l10n.address,
              hint: l10n.addressHint,
              controller: _addressController,
              prefixIcon: Icons.place_outlined,
              keyboardType: TextInputType.streetAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return l10n.enterAddress;
                return null;
              },
            ),
            const SizedBox(height: 20),
            MapPickerWidget(
              location: regState.location,
              isLoadingLocation: _isGeocoding,
              onLocationChanged: _onLocationChanged,
            ),
            const SizedBox(height: 24),
            DocumentUploadArea(
              label: l10n.mosquePhoto,
              hint: l10n.uploadMosquePhoto,
              file: _mosquePhoto,
              onFileSelected: (file) => setState(() => _mosquePhoto = file),
            ),
            const SizedBox(height: 16),
            AuthTextField(
              label: l10n.contactPhone,
              hint: l10n.contactHint,
              controller: _contactController,
              prefixIcon: Icons.phone_in_talk_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return l10n.enterContactNumber;
                return null;
              },
            ),
            const SizedBox(height: 32),
            AppButton(
              label: l10n.next,
              onPressed: _proceedToAskSetupForNewMosque,
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.emerald : AppColors.grey500,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                style: GoogleFonts.tajawal(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.emeraldDark : AppColors.grey700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountryPickerField extends StatelessWidget {
  const _CountryPickerField({
    required this.country,
    required this.onTap,
    required this.label,
    required this.placeholder,
  });

  final String country;
  final VoidCallback onTap;
  final String label;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.public_outlined, size: 20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                country.isEmpty ? placeholder : country,
                style: GoogleFonts.tajawal(
                  fontSize: 15,
                  color: country.isEmpty ? AppColors.grey500 : AppColors.charcoal,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: AppColors.grey500),
          ],
        ),
      ),
    );
  }
}
