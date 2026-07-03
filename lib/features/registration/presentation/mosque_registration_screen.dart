import 'dart:io';

import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../auth/presentation/widgets/auth_text_field.dart';
import '../application/registration_controller.dart';
import 'widgets/document_upload_area.dart';
import 'widgets/map_picker_widget.dart';
import 'widgets/registration_progress_indicator.dart';

class MosqueRegistrationScreen extends ConsumerStatefulWidget {
  const MosqueRegistrationScreen({super.key});

  @override
  ConsumerState<MosqueRegistrationScreen> createState() =>
      _MosqueRegistrationScreenState();
}

class _MosqueRegistrationScreenState
    extends ConsumerState<MosqueRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();

  String _country = '';
  String _countryCode = '';
  File? _mosquePhoto;
  bool _isGeocoding = false;

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
  }

  @override
  void dispose() {
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_country.isEmpty) {
      context.showSnackBar('يرجى اختيار الدولة', isError: true);
      return;
    }

    final regState = ref.read(registrationControllerProvider);
    if (regState.location == null) {
      context.showSnackBar('يرجى تحديد موقع المسجد على الخريطة', isError: true);
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

    final success = await ref
        .read(registrationControllerProvider.notifier)
        .submitRegistration();

    if (!mounted) return;
    if (success) {
      context.go(AppRoutes.underReview);
    } else {
      final error = ref.read(registrationControllerProvider).errorMessage;
      context.showSnackBar(error ?? 'حدث خطأ', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final regState = ref.watch(registrationControllerProvider);

    return LoadingOverlay(
      isLoading: regState.isSubmitting,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          title: const Text('تسجيل المسجد'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(AppRoutes.registerImam),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const RegistrationProgressIndicator(currentStep: 2),
                  const SizedBox(height: 28),
                  Text(
                    'بيانات المسجد',
                    style: GoogleFonts.tajawal(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.emeraldDark,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 24),
                  AuthTextField(
                    label: 'اسم المسجد',
                    hint: 'مسجد النور',
                    controller: _nameController,
                    prefixIcon: Icons.mosque_outlined,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'أدخل اسم المسجد';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _CountryPickerField(
                    country: _country,
                    onTap: _pickCountry,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    label: 'المدينة',
                    hint: 'تُملأ تلقائياً من الخريطة أو أدخلها يدوياً',
                    controller: _cityController,
                    prefixIcon: Icons.location_city_outlined,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'أدخل المدينة';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    label: 'العنوان',
                    hint: 'الشارع، الحي، الرمز البريدي...',
                    controller: _addressController,
                    prefixIcon: Icons.place_outlined,
                    keyboardType: TextInputType.streetAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'أدخل العنوان';
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
                    label: 'صورة المسجد',
                    hint: 'اضغط لرفع صورة للمسجد',
                    file: _mosquePhoto,
                    onFileSelected: (file) => setState(() => _mosquePhoto = file),
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  AuthTextField(
                    label: 'رقم التواصل',
                    hint: '+966 5XX XXX XXXX',
                    controller: _contactController,
                    prefixIcon: Icons.phone_in_talk_outlined,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'أدخل رقم التواصل';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  AppButton(
                    label: 'حفظ وإرسال للمراجعة',
                    isLoading: regState.isSubmitting,
                    onPressed: regState.isSubmitting ? null : _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CountryPickerField extends StatelessWidget {
  const _CountryPickerField({
    required this.country,
    required this.onTap,
  });

  final String country;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'الدولة',
          prefixIcon: Icon(Icons.public_outlined, size: 20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                country.isEmpty ? 'اختر الدولة' : country,
                style: GoogleFonts.tajawal(
                  fontSize: 15,
                  color: country.isEmpty ? AppColors.grey500 : AppColors.charcoal,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: AppColors.grey500),
          ],
        ),
      ),
    );
  }
}
