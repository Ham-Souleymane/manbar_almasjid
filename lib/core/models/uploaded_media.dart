import 'package:flutter/foundation.dart';
import '../config/media_server_config.dart';

/// Represents a media item uploaded to the isolated VPS media server.
@immutable
class UploadedMedia {
  final String fileId;
  final String url;
  final String mimeType;
  final int? sizeBytes;
  final int? width;
  final int? height;
  final String? category;
  final String? appId;
  final DateTime? createdAt;

  const UploadedMedia({
    required this.fileId,
    required this.url,
    required this.mimeType,
    this.sizeBytes,
    this.width,
    this.height,
    this.category,
    this.appId,
    this.createdAt,
  });

  /// Factory to deserialize JSON returned from the media server.
  ///
  /// Resiliently parses formats like:
  /// - `{ "media": { "fileId": ..., "url": ... } }`
  /// - `{ "data": { "media": { ... } } }`
  /// - Direct media payload `{ "fileId": ..., "url": ... }`
  factory UploadedMedia.fromJson(
    Map<String, dynamic> json, {
    String? baseUrl,
    String? fallbackCategory,
    String? fallbackMimeType,
  }) {
    Map<String, dynamic> data = json;

    // Unwrap if wrapped under 'media' or 'data'
    if (data['media'] is Map<String, dynamic>) {
      data = data['media'] as Map<String, dynamic>;
    } else if (data['data'] is Map<String, dynamic>) {
      final innerData = data['data'] as Map<String, dynamic>;
      if (innerData['media'] is Map<String, dynamic>) {
        data = innerData['media'] as Map<String, dynamic>;
      } else {
        data = innerData;
      }
    }

    final rawUrl = (data['url'] ?? data['fileUrl'] ?? '').toString();
    final normalizedUrl = normalizeUrl(rawUrl, baseUrl: baseUrl);

    final rawFileId = (data['fileId'] ?? data['id'] ?? data['_id'] ?? '').toString();
    final rawMime = (data['mimeType'] ?? data['contentType'] ?? fallbackMimeType ?? 'application/octet-stream').toString();

    int? parseInt(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString());
    }

    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString());
    }

    return UploadedMedia(
      fileId: rawFileId.isNotEmpty ? rawFileId : normalizedUrl,
      url: normalizedUrl,
      mimeType: rawMime,
      sizeBytes: parseInt(data['sizeBytes'] ?? data['size']),
      width: parseInt(data['width']),
      height: parseInt(data['height']),
      category: data['category']?.toString() ?? fallbackCategory,
      appId: data['appId']?.toString() ?? MediaServerConfig.appId,
      createdAt: parseDate(data['createdAt'] ?? data['uploadedAt']),
    );
  }

  /// Normalizes raw server URLs to ensure complete, valid absolute URLs.
  static String normalizeUrl(String rawUrl, {String? baseUrl}) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return '';

    // Already an absolute HTTP/HTTPS URL
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    // Protocol-relative URL (e.g. //media.stayfix.co/...)
    if (trimmed.startsWith('//')) {
      return 'https:$trimmed';
    }

    final effectiveBase = (baseUrl ?? MediaServerConfig.baseUrl).replaceAll(RegExp(r'/+$'), '');

    // Relative path with leading slash
    if (trimmed.startsWith('/')) {
      return '$effectiveBase$trimmed';
    }

    // Relative path without leading slash
    return '$effectiveBase/$trimmed';
  }

  Map<String, dynamic> toJson() {
    return {
      'fileId': fileId,
      'url': url,
      'mimeType': mimeType,
      if (sizeBytes != null) 'sizeBytes': sizeBytes,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (category != null) 'category': category,
      if (appId != null) 'appId': appId,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  /// Returns true if the media is an image.
  bool get isImage =>
      mimeType.startsWith('image/') ||
      url.toLowerCase().endsWith('.png') ||
      url.toLowerCase().endsWith('.jpg') ||
      url.toLowerCase().endsWith('.jpeg') ||
      url.toLowerCase().endsWith('.webp') ||
      url.toLowerCase().endsWith('.gif');

  /// Returns true if the media is a video.
  bool get isVideo =>
      mimeType.startsWith('video/') ||
      url.toLowerCase().endsWith('.mp4') ||
      url.toLowerCase().endsWith('.mov') ||
      url.toLowerCase().endsWith('.webm');

  /// Returns true if the media is an audio file.
  bool get isAudio =>
      mimeType.startsWith('audio/') ||
      url.toLowerCase().endsWith('.mp3') ||
      url.toLowerCase().endsWith('.m4a') ||
      url.toLowerCase().endsWith('.wav');

  /// Returns true if the media is a document/attachment.
  bool get isDocument =>
      mimeType.startsWith('application/') ||
      mimeType.startsWith('text/') ||
      url.toLowerCase().endsWith('.pdf') ||
      url.toLowerCase().endsWith('.docx') ||
      url.toLowerCase().endsWith('.doc');

  @override
  String toString() {
    return 'UploadedMedia(fileId: $fileId, url: $url, mimeType: $mimeType, category: $category, sizeBytes: $sizeBytes)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UploadedMedia && other.fileId == fileId && other.url == url;
  }

  @override
  int get hashCode => fileId.hashCode ^ url.hashCode;
}
