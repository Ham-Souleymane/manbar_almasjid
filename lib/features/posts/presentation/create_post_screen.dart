import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' as intl;

import '../../../core/l10n/app_localizations.dart';
import '../../registration/data/registration_repository.dart';
import '../../registration/domain/imam_status.dart';
import '../../suggestions/presentation/suggest_to_admin_sheet.dart';
import '../data/post_model.dart';
import '../data/posts_repository.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();

  String _selectedCategory = 'إعلان';
  final List<String> _categories = ['درس', 'خطبة', 'إعلان', 'نشاط', 'تنبيه'];

  File? _attachedFile;
  String _mediaType = 'none'; // 'image' | 'video' | 'file' | 'none'
  String? _attachedFileName;

  DateTime? _eventDate;
  DateTime? _scheduledFor;

  bool _isSubmitting = false;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final l10n = context.l10n;
    try {
      final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          _attachedFile = File(picked.path);
          _mediaType = 'image';
          _attachedFileName = picked.name;
        });
      }
    } catch (e) {
      _showSnackBar('${l10n.error}: $e');
    }
  }

  Future<void> _pickVideo() async {
    final l10n = context.l10n;
    try {
      final picked = await _imagePicker.pickVideo(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          _attachedFile = File(picked.path);
          _mediaType = 'video';
          _attachedFileName = picked.name;
        });
      }
    } catch (e) {
      _showSnackBar('${l10n.error}: $e');
    }
  }

  Future<void> _pickFile() async {
    final l10n = context.l10n;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _attachedFile = File(result.files.single.path!);
          _mediaType = 'file';
          _attachedFileName = result.files.single.name;
        });
      }
    } catch (e) {
      _showSnackBar('${l10n.error}: $e');
    }
  }

  void _clearAttachment() {
    setState(() {
      _attachedFile = null;
      _mediaType = 'none';
      _attachedFileName = null;
    });
  }

  Future<void> _selectEventDate() async {
    final locale = Localizations.localeOf(context);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: locale,
    );
    if (pickedDate != null) {
      if (!mounted) return;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          _eventDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _selectScheduledDate() async {
    final locale = Localizations.localeOf(context);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      locale: locale,
    );
    if (pickedDate != null) {
      if (!mounted) return;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          _scheduledFor = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF0F766E),
      ),
    );
  }

  Future<void> _publishPost() async {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;

    final imamAsync = ref.read(currentImamProvider);
    final mosqueAsync = ref.read(currentMosqueProvider);

    final imam = imamAsync.asData?.value;
    final mosque = mosqueAsync.asData?.value;

    if (imam == null || mosque == null) {
      _showSnackBar(l10n.errorLoadingData);
      return;
    }

    if (imam.status != ImamStatus.verified) {
      _showSnackBar(l10n.accountNotVerified);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      List<String> mediaUrls = [];
      if (_attachedFile != null) {
        final url = await ref.read(postsRepositoryProvider).uploadPostMedia(
              file: _attachedFile!,
              imamId: imam.id,
              mediaType: _mediaType,
            );
        mediaUrls.add(url);
      }

      final post = PostModel(
        id: '', // Will be set by Firebase docRef
        mosqueId: mosque.id,
        imamId: imam.id,
        text: _textController.text.trim(),
        mediaUrls: mediaUrls,
        mediaType: _mediaType,
        category: _selectedCategory,
        eventDate: _eventDate,
        scheduledFor: _scheduledFor,
        createdAt: DateTime.now(),
        viewCount: 0,
      );

      await ref.read(postsRepositoryProvider).createPost(post);

      _showSnackBar(l10n.postPublished);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _showSnackBar('${l10n.error}: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _getCategoryDisplayName(String category, AppLocalizations l10n) {
    switch (category) {
      case 'درس':
        return l10n.categoryLesson;
      case 'خطبة':
        return l10n.categoryKhutbah;
      case 'نشاط':
        return l10n.categoryActivity;
      case 'تنبيه':
        return l10n.categoryAlert;
      case 'إعلان':
      default:
        return l10n.categoryAnnouncement;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final imamAsync = ref.watch(currentImamProvider);
    final mosqueAsync = ref.watch(currentMosqueProvider);

    final isVerified = imamAsync.asData?.value?.status == ImamStatus.verified;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: Text(
          l10n.createPost,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF111827),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        elevation: 0.5,
        centerTitle: true,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Color(0xFF111827),
                  size: 20,
                ),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: TextButton.icon(
              onPressed: () => showSuggestToAdminSheet(context),
              icon: const Icon(
                Icons.lightbulb_rounded,
                size: 18,
                color: Color(0xFF0F766E),
              ),
              label: const Text(
                'إقترح للإدارة',
                style: TextStyle(
                  color: Color(0xFF0F766E),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor:
                    const Color(0xFF0F766E).withValues(alpha: 0.1),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mosque identity card at top
                    mosqueAsync.when(
                      data: (mosque) {
                        if (mosque == null) return const SizedBox();
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: mosque.photo != null &&
                                        mosque.photo!.isNotEmpty
                                    ? Image.network(
                                        mosque.photo!,
                                        width: 45,
                                        height: 45,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        width: 45,
                                        height: 45,
                                        color: const Color(0xFFE5F3F1),
                                        child: const Icon(Icons.mosque_rounded,
                                            color: Color(0xFF0F766E),
                                            size: 24),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      mosque.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      mosque.address,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              if (isVerified)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE5F3F1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.verified_rounded,
                                          color: Color(0xFF0F766E), size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        l10n.verified,
                                        style: const TextStyle(
                                            color: Color(0xFF0F766E),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                      loading: () => const Center(
                          child: LinearProgressIndicator(
                        color: Color(0xFF0F766E),
                      )),
                      error: (_, __) => const SizedBox(),
                    ),
                    const SizedBox(height: 16),

                    // Text Field Area
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _textController,
                        maxLines: 8,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return l10n.enterPostContent;
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: l10n.postContentHint,
                          hintStyle: const TextStyle(color: Colors.black38),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category selection
                    Text(
                      l10n.postCategory,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF374151)),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _categories.map((category) {
                          final isSelected = _selectedCategory == category;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: ChoiceChip(
                              label: Text(_getCategoryDisplayName(category, l10n)),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF4B5563),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              selected: isSelected,
                              selectedColor: const Color(0xFF0F766E),
                              backgroundColor: Colors.white,
                              elevation: 0.5,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected
                                      ? const Color(0xFF0F766E)
                                      : Colors.grey.shade300,
                                ),
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedCategory = category;
                                  });
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Media attachment preview/indicator
                    if (_attachedFile != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _mediaType == 'image'
                                  ? Icons.image_rounded
                                  : _mediaType == 'video'
                                      ? Icons.video_collection_rounded
                                      : Icons.insert_drive_file_rounded,
                              color: const Color(0xFF0F766E),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _attachedFileName ?? l10n.fileLabel,
                                style: const TextStyle(
                                    fontSize: 13, color: Color(0xFF1F2937)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  color: Colors.red),
                              onPressed: _clearAttachment,
                            ),
                          ],
                        ),
                      ),

                    // Attachment buttons
                    Text(
                      l10n.attachMedia,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF374151)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _mediaAttachButton(
                            icon: Icons.image_rounded,
                            label: l10n.imageLabel,
                            onTap: _pickImage,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _mediaAttachButton(
                            icon: Icons.video_collection_rounded,
                            label: l10n.videoLabel,
                            onTap: _pickVideo,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _mediaAttachButton(
                            icon: Icons.insert_drive_file_rounded,
                            label: l10n.fileLabel,
                            onTap: _pickFile,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Scheduling / Dates Section
                    Text(
                      l10n.additionalOptions,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF374151)),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildDateTimePickerTile(
                            icon: Icons.calendar_today_rounded,
                            title: l10n.eventDateLabel,
                            subtitle: _eventDate != null
                                ? intl.DateFormat('yyyy/MM/dd hh:mm a')
                                    .format(_eventDate!)
                                : l10n.selectEventDateHint,
                            onTap: _selectEventDate,
                            onClear: _eventDate != null
                                ? () => setState(() => _eventDate = null)
                                : null,
                          ),
                          const Divider(height: 1, indent: 16, endIndent: 16),
                          _buildDateTimePickerTile(
                            icon: Icons.schedule_rounded,
                            title: l10n.schedulePublish,
                            subtitle: _scheduledFor != null
                                ? intl.DateFormat('yyyy/MM/dd hh:mm a')
                                    .format(_scheduledFor!)
                                : l10n.schedulePublishHint,
                            onTap: _selectScheduledDate,
                            onClear: _scheduledFor != null
                                ? () => setState(() => _scheduledFor = null)
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (isVerified && !_isSubmitting)
                            ? _publishPost
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          disabledForegroundColor: Colors.grey.shade500,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _scheduledFor != null ? l10n.schedulePublish : l10n.publishNow,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
          if (_isSubmitting)
            Container(
              color: Colors.black26,
              child: Center(
                child: Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: Color(0xFF0F766E),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.publishingPostMessage,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _mediaAttachButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF0F766E), size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF4B5563),
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimePickerTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF0F766E)),
      title: Text(
        title,
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937)),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.black54),
      ),
      trailing: onClear != null
          ? IconButton(
              icon: const Icon(Icons.clear_rounded, color: Colors.grey),
              onPressed: onClear,
            )
          : const Icon(Icons.chevron_right_rounded, color: Colors.black38),
      onTap: onTap,
    );
  }
}
