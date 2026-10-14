import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/media_server_config.dart';
import '../models/uploaded_media.dart';

/// Exception thrown when a media upload or deletion fails.
class MediaUploadException implements Exception {
  final String message;
  final int? statusCode;
  final String? responseBody;

  const MediaUploadException(
    this.message, {
    this.statusCode,
    this.responseBody,
  });

  @override
  String toString() {
    if (statusCode != null) {
      return 'MediaUploadException (HTTP $statusCode): $message${responseBody != null ? ' - $responseBody' : ''}';
    }
    return 'MediaUploadException: $message';
  }
}

/// Service dedicated to handling media uploads and management on the VPS Media Server.
///
/// Ensures strict isolation from StayFix or any other application by tagging
/// every request with the dedicated [appId] (default: `manbar_almasjid`).
class MediaUploadService {
  final http.Client _client;
  final String? _customBaseUrl;
  final String? _defaultAppId;
  final bool _ownsClient;

  MediaUploadService({
    http.Client? client,
    String? baseUrl,
    String? appId,
  })  : _client = client ?? http.Client(),
        _customBaseUrl = baseUrl,
        _defaultAppId = appId,
        _ownsClient = client == null;

  /// Effective Base URL of the media server.
  String get baseUrl {
    final raw = _customBaseUrl ?? MediaServerConfig.baseUrl;
    return raw.replaceAll(RegExp(r'/+$'), '');
  }

  /// Effective App ID for storage isolation.
  String get appId => _defaultAppId ?? MediaServerConfig.appId;

  /// Resolves the effective authentication token and user ID.
  /// Falls back to FirebaseAuth.instance.currentUser if available.
  Future<({String? token, String? userId})> _resolveAuth({
    String? token,
    String? userId,
  }) async {
    String? effectiveToken = token;
    String? effectiveUserId = userId;

    if (effectiveToken == null || effectiveToken.isEmpty) {
      if (MediaServerConfig.apiKey.isNotEmpty) {
        effectiveToken = MediaServerConfig.apiKey;
        debugPrint('[MediaUpload] Using static API key for auth.');
      } else {
        try {
          final currentUser = FirebaseAuth.instance.currentUser;
          effectiveUserId ??= currentUser?.uid;
          if (currentUser != null) {
            effectiveToken = await currentUser.getIdToken();
            debugPrint(
              '[MediaUpload] ✅ Firebase ID token fetched. uid=${currentUser.uid} '
              'token=${effectiveToken?.substring(0, 20)}...',
            );
          } else {
            debugPrint('[MediaUpload] ⚠️ No signed-in Firebase user found. Upload will be unauthenticated.');
          }
        } catch (e) {
          // Firebase might not be initialized in test environment
          debugPrint('[MediaUpload] ❌ Failed to get Firebase token: $e');
        }
      }
    } else if (effectiveUserId == null || effectiveUserId.isEmpty) {
      try {
        effectiveUserId = FirebaseAuth.instance.currentUser?.uid;
      } catch (_) {}
    }

    return (token: effectiveToken, userId: effectiveUserId);
  }

  /// Uploads any binary file (image, audio, video, attachment) to the VPS Media Server.
  ///
  /// - [file]: The local file to upload.
  /// - [category]: Logical grouping (e.g. "profile", "chat", "posts", "attachments").
  /// - [customAppId]: Optional override for the target app storage directory.
  /// - [authToken]: Optional bearer token. If omitted, falls back to [MediaServerConfig.apiKey].
  /// - [userId]: Optional user ID passed as `X-User-Id` header.
  Future<UploadedMedia> uploadFile({
    required File file,
    required String category,
    String? customAppId,
    String? authToken,
    String? userId,
  }) async {
    if (!file.existsSync()) {
      throw MediaUploadException('File does not exist at path: ${file.path}');
    }

    final targetAppId = customAppId ?? appId;
    final uploadUri = Uri.parse('$baseUrl/api/media/upload');

    final mimeType = detectMimeType(file.path);
    final mediaType = MediaType.parse(mimeType);

    final request = http.MultipartRequest('POST', uploadUri);

    // Required fields
    request.fields['category'] = category;
    request.fields['appId'] = targetAppId;

    // Authentication headers (auto-resolves from FirebaseAuth if omitted)
    final auth = await _resolveAuth(token: authToken, userId: userId);
    if (auth.token != null && auth.token!.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer ${auth.token}';
    }
    if (auth.userId != null && auth.userId!.isNotEmpty) {
      request.headers['X-User-Id'] = auth.userId!;
    }

    // Attach binary file with detected Content-Type
    final multipartFile = await http.MultipartFile.fromPath(
      'file',
      file.path,
      contentType: mediaType,
    );
    request.files.add(multipartFile);

    try {
      debugPrint(
        '[MediaUpload] → POST ${uploadUri.toString()} '
        '| category=$category appId=$targetAppId '
        '| auth=${request.headers.containsKey('Authorization') ? '✅ Bearer' : '❌ NONE'}',
      );
      final streamedResponse = await _client.send(request);
      final responseBody = await streamedResponse.stream.bytesToString();
      debugPrint('[MediaUpload] ← HTTP ${streamedResponse.statusCode}: $responseBody');

      if (streamedResponse.statusCode == 200 || streamedResponse.statusCode == 201) {
        final decoded = jsonDecode(responseBody);
        if (decoded is Map<String, dynamic>) {
          return UploadedMedia.fromJson(
            decoded,
            baseUrl: baseUrl,
            fallbackCategory: category,
            fallbackMimeType: mimeType,
          );
        } else {
          throw MediaUploadException(
            'Invalid response format from media server',
            statusCode: streamedResponse.statusCode,
            responseBody: responseBody,
          );
        }
      } else {
        throw MediaUploadException(
          'Media server rejected upload',
          statusCode: streamedResponse.statusCode,
          responseBody: responseBody,
        );
      }
    } on SocketException catch (e) {
      throw MediaUploadException('Network error connecting to media server: ${e.message}');
    } on http.ClientException catch (e) {
      throw MediaUploadException('HTTP client error during upload: ${e.message}');
    } catch (e) {
      if (e is MediaUploadException) rethrow;
      throw MediaUploadException('Unexpected upload failure: $e');
    }
  }

  /// Deletes one or multiple files by their IDs from the media server.
  ///
  /// - [fileIds]: List of server file IDs to permanently remove.
  /// - [customAppId]: Optional app ID scope.
  /// - [authToken]: Optional bearer token.
  /// - [userId]: Optional user ID.
  Future<bool> deleteFiles(
    List<String> fileIds, {
    String? customAppId,
    String? authToken,
    String? userId,
  }) async {
    if (fileIds.isEmpty) return true;

    final targetAppId = customAppId ?? appId;
    final deleteUri = Uri.parse('$baseUrl/api/media/delete-many');

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    final auth = await _resolveAuth(token: authToken, userId: userId);
    if (auth.token != null && auth.token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${auth.token}';
    }
    if (auth.userId != null && auth.userId!.isNotEmpty) {
      headers['X-User-Id'] = auth.userId!;
    }

    final body = jsonEncode({
      'fileIds': fileIds,
      'appId': targetAppId,
    });

    try {
      final response = await _client.post(
        deleteUri,
        headers: headers,
        body: body,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }

      throw MediaUploadException(
        'Failed to delete media files',
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    } on SocketException catch (e) {
      throw MediaUploadException('Network error connecting to media server: ${e.message}');
    } catch (e) {
      if (e is MediaUploadException) rethrow;
      throw MediaUploadException('Unexpected deletion failure: $e');
    }
  }

  /// Normalizes an uploaded URL to ensure it has a full, absolute address.
  String normalizeUrl(String rawUrl) {
    return UploadedMedia.normalizeUrl(rawUrl, baseUrl: baseUrl);
  }

  /// Automatic detection of MIME types based on file extension with fallback.
  static String detectMimeType(String filePath) {
    final dotIndex = filePath.lastIndexOf('.');
    if (dotIndex == -1) return 'application/octet-stream';

    final extension = filePath.substring(dotIndex + 1).toLowerCase();
    switch (extension) {
      // Images
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'svg':
        return 'image/svg+xml';
      case 'bmp':
        return 'image/bmp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';

      // Audio
      case 'mp3':
        return 'audio/mpeg';
      case 'm4a':
        return 'audio/mp4';
      case 'wav':
        return 'audio/wav';
      case 'aac':
        return 'audio/aac';
      case 'ogg':
      case 'oga':
        return 'audio/ogg';
      case 'flac':
        return 'audio/flac';

      // Video
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'webm':
        return 'video/webm';
      case 'mkv':
        return 'video/x-matroska';
      case 'avi':
        return 'video/x-msvideo';

      // Documents
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'txt':
        return 'text/plain';
      case 'csv':
        return 'text/csv';
      case 'zip':
        return 'application/zip';

      default:
        return 'application/octet-stream';
    }
  }

  /// Closes client resources if this service created its own client.
  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }
}
