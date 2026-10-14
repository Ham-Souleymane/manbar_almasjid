import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/media_upload_service.dart';

/// Global provider for [MediaUploadService].
final mediaUploadServiceProvider = Provider<MediaUploadService>((ref) {
  final service = MediaUploadService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});
