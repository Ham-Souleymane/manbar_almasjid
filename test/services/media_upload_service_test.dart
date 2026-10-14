import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manbar_almasjid/core/config/media_server_config.dart';
import 'package:manbar_almasjid/core/models/uploaded_media.dart';
import 'package:manbar_almasjid/core/services/media_upload_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MediaServerConfig', () {
    tearDown(() {
      MediaServerConfig.reset();
    });

    test('default configuration provides default values', () {
      expect(MediaServerConfig.baseUrl, 'https://media.stayfix.co');
      expect(MediaServerConfig.appId, 'manbar_almasjid');
      expect(MediaServerConfig.apiKey, '');
    });

    test('runtime overrides take precedence and reset restores defaults', () {
      MediaServerConfig.setOverrides(
        baseUrl: 'https://media.custom.com/',
        appId: 'custom_mosque_app',
        apiKey: 'test-api-key',
      );

      // Trailing slash should be stripped
      expect(MediaServerConfig.baseUrl, 'https://media.custom.com');
      expect(MediaServerConfig.appId, 'custom_mosque_app');
      expect(MediaServerConfig.apiKey, 'test-api-key');

      MediaServerConfig.reset();
      expect(MediaServerConfig.baseUrl, 'https://media.stayfix.co');
      expect(MediaServerConfig.appId, 'manbar_almasjid');
    });
  });

  group('detectMimeType', () {
    test('accurately detects various file extensions', () {
      expect(MediaUploadService.detectMimeType('photo.png'), 'image/png');
      expect(MediaUploadService.detectMimeType('image.jpg'), 'image/jpeg');
      expect(MediaUploadService.detectMimeType('image.jpeg'), 'image/jpeg');
      expect(MediaUploadService.detectMimeType('graphic.webp'), 'image/webp');
      expect(MediaUploadService.detectMimeType('audio.mp3'), 'audio/mpeg');
      expect(MediaUploadService.detectMimeType('recording.m4a'), 'audio/mp4');
      expect(MediaUploadService.detectMimeType('khutbah.mp4'), 'video/mp4');
      expect(MediaUploadService.detectMimeType('document.pdf'), 'application/pdf');
      expect(MediaUploadService.detectMimeType('document.docx'),
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document');
      expect(MediaUploadService.detectMimeType('unknown_file'), 'application/octet-stream');
    });
  });

  group('UploadedMedia URL normalization and helpers', () {
    test('normalizes relative, protocol-relative, and absolute URLs', () {
      expect(
        UploadedMedia.normalizeUrl('https://media.stayfix.co/files/img.jpg'),
        'https://media.stayfix.co/files/img.jpg',
      );

      expect(
        UploadedMedia.normalizeUrl('//media.stayfix.co/files/img.jpg'),
        'https://media.stayfix.co/files/img.jpg',
      );

      expect(
        UploadedMedia.normalizeUrl('/uploads/manbar_almasjid/photo.png',
            baseUrl: 'https://media.stayfix.co'),
        'https://media.stayfix.co/uploads/manbar_almasjid/photo.png',
      );

      expect(
        UploadedMedia.normalizeUrl('uploads/photo.png',
            baseUrl: 'https://media.stayfix.co/'),
        'https://media.stayfix.co/uploads/photo.png',
      );
    });

    test('parses server response wrapped in media object correctly', () {
      final json = {
        'media': {
          'fileId': 'file-123',
          'url': 'https://media.stayfix.co/manbar_almasjid/image.png',
          'mimeType': 'image/png',
          'sizeBytes': 20480,
          'width': 1920,
          'height': 1080,
        }
      };

      final media = UploadedMedia.fromJson(json);
      expect(media.fileId, 'file-123');
      expect(media.url, 'https://media.stayfix.co/manbar_almasjid/image.png');
      expect(media.mimeType, 'image/png');
      expect(media.sizeBytes, 20480);
      expect(media.width, 1920);
      expect(media.height, 1080);
      expect(media.isImage, isTrue);
      expect(media.isVideo, isFalse);
    });

    test('parses relative url and unwrap nested response', () {
      final json = {
        'data': {
          'media': {
            'fileId': 'abc-999',
            'url': '/uploads/manbar_almasjid/video.mp4',
            'mimeType': 'video/mp4',
          }
        }
      };

      final media = UploadedMedia.fromJson(json, baseUrl: 'https://media.stayfix.co');
      expect(media.fileId, 'abc-999');
      expect(media.url, 'https://media.stayfix.co/uploads/manbar_almasjid/video.mp4');
      expect(media.isVideo, isTrue);
      expect(media.isImage, isFalse);
    });
  });

  group('MediaUploadService', () {
    late Directory tempDir;
    late File dummyFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('media_service_test_');
      dummyFile = File('${tempDir.path}/test_image.png');
      await dummyFile.writeAsBytes([0, 1, 2, 3, 4, 5]);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
      MediaServerConfig.reset();
    });

    test('uploadFile sends proper multipart fields, auth, and appId for isolation', () async {
      late http.Request inspectedRequest;
      final mockClient = MockClient((request) async {
        inspectedRequest = request;
        return http.Response(
          jsonEncode({
            'media': {
              'fileId': 'uploaded-id-456',
              'url': 'https://media.stayfix.co/manbar_almasjid/test_image.png',
              'mimeType': 'image/png',
              'sizeBytes': 6,
              'width': 800,
              'height': 600,
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = MediaUploadService(
        client: mockClient,
        baseUrl: 'https://media.stayfix.co',
        appId: 'manbar_almasjid',
      );

      final result = await service.uploadFile(
        file: dummyFile,
        category: 'posts',
        authToken: 'jwt-auth-token-xyz',
        userId: 'imam-user-123',
      );

      expect(result.fileId, 'uploaded-id-456');
      expect(result.url, 'https://media.stayfix.co/manbar_almasjid/test_image.png');
      expect(result.sizeBytes, 6);
      expect(result.category, 'posts');

      // Verify request metadata
      expect(inspectedRequest.method, 'POST');
      expect(inspectedRequest.url.path, '/api/media/upload');
      expect(inspectedRequest.headers['authorization'], 'Bearer jwt-auth-token-xyz');
      expect(inspectedRequest.headers['x-user-id'], 'imam-user-123');
    });

    test('uploadFile throws MediaUploadException on server error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'Server disk full'}),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = MediaUploadService(client: mockClient);

      expect(
        () => service.uploadFile(file: dummyFile, category: 'profile'),
        throwsA(isA<MediaUploadException>().having(
          (e) => e.statusCode,
          'statusCode',
          500,
        )),
      );
    });

    test('deleteFiles sends POST to /api/media/delete-many with fileIds and appId', () async {
      late http.Request inspectedRequest;
      String? requestBody;

      final mockClient = MockClient((request) async {
        inspectedRequest = request;
        requestBody = request.body;
        return http.Response(
          jsonEncode({'deletedCount': 2}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = MediaUploadService(
        client: mockClient,
        baseUrl: 'https://media.stayfix.co',
        appId: 'manbar_almasjid',
      );

      final success = await service.deleteFiles(
        ['file-1', 'file-2'],
        authToken: 'admin-token',
        userId: 'admin-user',
      );

      expect(success, isTrue);
      expect(inspectedRequest.method, 'POST');
      expect(inspectedRequest.url.path, '/api/media/delete-many');
      expect(inspectedRequest.headers['authorization'], 'Bearer admin-token');
      expect(inspectedRequest.headers['x-user-id'], 'admin-user');

      final decoded = jsonDecode(requestBody!);
      expect(decoded['fileIds'], ['file-1', 'file-2']);
      expect(decoded['appId'], 'manbar_almasjid');
    });
  });
}
