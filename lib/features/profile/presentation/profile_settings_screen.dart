import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/locale_provider.dart';
import '../../auth/application/auth_controller.dart';
import '../../registration/data/registration_repository.dart';
import '../../registration/domain/imam_model.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  String? _uploadedPhotoUrl;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();

    // Initialize controller values from current profile state
    Future.microtask(() {
      final imam = ref.read(currentImamProvider).asData?.value;
      if (imam != null) {
        _nameController.text = imam.fullName;
        _phoneController.text = imam.phone;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {Color color = const Color(0xFF0F766E)}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(ImamModel imam) async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked == null) return;

      setState(() => _isUploadingPhoto = true);

      final url = await ref.read(registrationRepositoryProvider).uploadFile(
            file: File(picked.path),
            path: 'profile_photos/${imam.id}',
          );

      await FirebaseFirestore.instance
          .collection('imams')
          .doc(imam.id)
          .update({'photo': url});

      setState(() {
        _uploadedPhotoUrl = url;
      });
      if (mounted) _showSnackBar(context.l10n.photoUpdated);
    } catch (e) {
      if (mounted) _showSnackBar('${context.l10n.error}: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _saveProfile(ImamModel imam) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final updatedImam = imam.copyWith(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        photo: _uploadedPhotoUrl ?? imam.photo,
      );

      await FirebaseFirestore.instance
          .collection('imams')
          .doc(imam.id)
          .set(updatedImam.toFirestore(), SetOptions(merge: true));

      if (mounted) _showSnackBar(context.l10n.profileSaved);
    } catch (e) {
      if (mounted) _showSnackBar('${context.l10n.error}: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _togglePreference(ImamModel imam, String field, bool value) async {
    try {
      await FirebaseFirestore.instance
          .collection('imams')
          .doc(imam.id)
          .update({field: value});
      if (mounted) _showSnackBar(context.l10n.preferencesUpdated);
    } catch (e) {
      if (mounted) _showSnackBar('${context.l10n.error}: $e', color: Colors.red);
    }
  }

  Future<void> _confirmDeleteAccount(ImamModel imam) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.deleteAccountTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text(l10n.deleteAccountMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.deleteAccountNow,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isSaving = true);
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception(l10n.anErrorOccurred);

        final batch = FirebaseFirestore.instance.batch();

        // Delete Imam profile document
        batch.delete(FirebaseFirestore.instance.collection('imams').doc(imam.id));

        // Delete Mosque document if linked
        if (imam.mosqueId != null && imam.mosqueId!.isNotEmpty) {
          batch.delete(FirebaseFirestore.instance.collection('mosques').doc(imam.mosqueId!));
        }

        await batch.commit();
        await user.delete();

        if (mounted) _showSnackBar(l10n.mosquePermanentlyDeleted);

        // Redirect to login (normally handled by authStateChanges changes)
        if (mounted) {
          ref.read(authControllerProvider.notifier).signOut();
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          _showDialogRequiresRecentLogin();
        } else {
          if (mounted) _showSnackBar('${l10n.deleteFailed}: ${e.message}', color: Colors.red);
        }
      } catch (e) {
        if (mounted) _showSnackBar('${l10n.deleteFailed}: $e', color: Colors.red);
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  void _showDialogRequiresRecentLogin() {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.recentLoginRequired,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(l10n.recentLoginMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.ok),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(authControllerProvider.notifier).signOut();
            },
            child: Text(l10n.logoutNow,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F766E))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imamAsync = ref.watch(currentImamProvider);
    final l10n = context.l10n;
    final locale = ref.watch(localeProvider);
    final isArabic = locale.languageCode == 'ar';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: Text(
          l10n.profileSettings,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0.5,
        centerTitle: true,
      ),
      body: imamAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF0F766E))),
        error: (e, _) => Center(child: Text('${l10n.errorLoadingData}: $e')),
        data: (imam) {
          if (imam == null) {
            return Center(child: Text(l10n.profileNotFound));
          }

          // Sync controller values only if they are empty (avoids wiping user typing)
          if (_nameController.text.isEmpty && imam.fullName.isNotEmpty) {
            _nameController.text = imam.fullName;
          }
          if (_phoneController.text.isEmpty && imam.phone.isNotEmpty) {
            _phoneController.text = imam.phone;
          }

          final photoUrl = _uploadedPhotoUrl ?? imam.photo;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Avatar & Header Details
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        color: Colors.white,
                        elevation: 0.5,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 54,
                                    backgroundColor: const Color(0xFFE5F3F1),
                                    backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                                        ? NetworkImage(photoUrl)
                                        : null,
                                    child: photoUrl == null || photoUrl.isEmpty
                                        ? const Icon(Icons.person_rounded,
                                            size: 54, color: Color(0xFF0F766E))
                                        : null,
                                  ),
                                  if (_isUploadingPhoto)
                                    Positioned.fill(
                                      child: ClipOval(
                                        child: Container(
                                          color: Colors.black26,
                                          child: const Center(
                                            child: CircularProgressIndicator(color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ),
                                  Positioned(
                                    bottom: 0,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _pickAndUploadPhoto(imam),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF0F766E),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                imam.fullName.isNotEmpty ? imam.fullName : l10n.imamLabel,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF111827)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                imam.email,
                                style: const TextStyle(fontSize: 13, color: Colors.black45),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Form Section
                      Text(
                        l10n.editPersonalData,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
                      ),
                      const SizedBox(height: 10),
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: Colors.white,
                        elevation: 0.5,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: l10n.fullName,
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  prefixIcon: const Icon(Icons.person_rounded),
                                ),
                                validator: (v) =>
                                    v == null || v.trim().isEmpty ? l10n.nameRequired : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _phoneController,
                                decoration: InputDecoration(
                                  labelText: l10n.contactPhone,
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  prefixIcon: const Icon(Icons.phone_rounded),
                                ),
                                keyboardType: TextInputType.phone,
                                validator: (v) =>
                                    v == null || v.trim().isEmpty ? l10n.phoneRequired : null,
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : () => _saveProfile(imam),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0F766E),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: _isSaving
                                      ? const CircularProgressIndicator(color: Colors.white)
                                      : Text(l10n.saveChanges,
                                          style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Notification Preferences
                      Text(
                        l10n.notificationSettings,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
                      ),
                      const SizedBox(height: 10),
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: Colors.white,
                        elevation: 0.5,
                        child: Column(
                          children: [
                            SwitchListTile(
                              title: Text(l10n.commentNotifications,
                                  style: const TextStyle(fontSize: 14)),
                              subtitle: Text(l10n.commentNotificationsSubtitle,
                                  style: const TextStyle(fontSize: 12)),
                              activeThumbColor: const Color(0xFF0F766E),
                              value: imam.commentsNotify,
                              onChanged: (val) =>
                                  _togglePreference(imam, 'commentsNotify', val),
                            ),
                            const Divider(height: 1, indent: 16, endIndent: 16),
                            SwitchListTile(
                              title: Text(l10n.verificationNotifications,
                                  style: const TextStyle(fontSize: 14)),
                              subtitle: Text(l10n.verificationNotificationsSubtitle,
                                  style: const TextStyle(fontSize: 12)),
                              activeThumbColor: const Color(0xFF0F766E),
                              value: imam.verificationNotify,
                              onChanged: (val) =>
                                  _togglePreference(imam, 'verificationNotify', val),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Language Section
                      Text(
                        l10n.language,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
                      ),
                      const SizedBox(height: 10),
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: Colors.white,
                        elevation: 0.5,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.language_rounded,
                                  color: Color(0xFF0F766E), size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  l10n.language,
                                  style: const TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                              ),
                              // Language toggle chips
                              Row(
                                children: [
                                  _LangChip(
                                    label: l10n.languageArabic,
                                    selected: isArabic,
                                    onTap: () => ref
                                        .read(localeProvider.notifier)
                                        .setLocale(const Locale('ar', 'AE')),
                                  ),
                                  const SizedBox(width: 8),
                                  _LangChip(
                                    label: l10n.languageEnglish,
                                    selected: !isArabic,
                                    onTap: () => ref
                                        .read(localeProvider.notifier)
                                        .setLocale(const Locale('en', 'US')),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Account operations
                      Text(
                        l10n.accountManagement,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
                      ),
                      const SizedBox(height: 10),
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: Colors.white,
                        elevation: 0.5,
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.logout_rounded, color: Colors.orange),
                                title: Text(l10n.logout,
                                    style: const TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.w600)),
                                trailing: const Icon(Icons.chevron_right_rounded),
                                onTap: () =>
                                    ref.read(authControllerProvider.notifier).signOut(),
                              ),
                              const Divider(height: 1, indent: 16, endIndent: 16),
                              ListTile(
                                leading: const Icon(Icons.delete_forever_rounded,
                                    color: Colors.red),
                                title: Text(l10n.deleteAccount,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red)),
                                trailing:
                                    const Icon(Icons.chevron_right_rounded, color: Colors.red),
                                onTap: () => _confirmDeleteAccount(imam),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
              if (_isSaving)
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0F766E)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Small language chip used in the profile settings language switcher.
class _LangChip extends StatelessWidget {
  const _LangChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0F766E) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF0F766E) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }
}
