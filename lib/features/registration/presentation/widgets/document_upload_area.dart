import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';

class DocumentUploadArea extends StatelessWidget {
  const DocumentUploadArea({
    super.key,
    required this.file,
    required this.onFileSelected,
    this.label = 'رفع مستند التحقق',
    this.hint = 'اضغط لرفع صورة الهوية أو مستند التحقق',
  });

  final File? file;
  final ValueChanged<File?> onFileSelected;
  final String label;
  final String hint;

  Future<void> _pickFile(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text('معرض الصور', style: GoogleFonts.tajawal()),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text('الكاميرا', style: GoogleFonts.tajawal()),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      onFileSelected(File(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: GoogleFonts.tajawal(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _pickFile(context),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: file != null ? AppColors.emerald : AppColors.divider,
                width: file != null ? 2 : 1,
              ),
            ),
            child: file != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(file!, fit: BoxFit.cover),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => onFileSelected(null),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.upload_file_rounded,
                        size: 36,
                        color: AppColors.emerald.withValues(alpha: 0.7),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        hint,
                        style: GoogleFonts.tajawal(
                          fontSize: 13,
                          color: AppColors.grey500,
                        ),
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
