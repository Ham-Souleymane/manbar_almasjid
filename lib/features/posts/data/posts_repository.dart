import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../../../core/providers/firebase_providers.dart';
import 'post_model.dart';
import 'comment_model.dart';
import 'like_model.dart';

class PostsRepository {
  PostsRepository({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _firestore = firestore,
        _storage = storage;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection('posts');

  /// Streams posts filtered by imamId, ordered by createdAt descending.
  Stream<List<PostModel>> watchMyPosts(String imamId) {
    return _posts
        .where('imamId', isEqualTo: imamId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
    });
  }

  /// Fetches a single post by ID.
  Future<PostModel?> getPost(String postId) async {
    final doc = await _posts.doc(postId).get();
    if (!doc.exists) return null;
    return PostModel.fromFirestore(doc);
  }

  /// Streams a single post by ID.
  Stream<PostModel?> watchPost(String postId) {
    return _posts.doc(postId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return PostModel.fromFirestore(doc);
    });
  }

  /// Increments view count for a post.
  Future<void> incrementViewCount(String postId) async {
    await _posts.doc(postId).update({
      'viewCount': FieldValue.increment(1),
    });
  }

  /// Uploads media. Images go to Cloudinary (per user request); videos/docs go to Firebase Storage.
  Future<String> uploadPostMedia({
    required File file,
    required String imamId,
    required String mediaType,
  }) async {
    if (mediaType == 'image') {
      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      const uploadPreset = 'ml_default';
      const apiKey = '469544593144925';
      const apiSecret = 'KmhsBEK1uXT4lgbHI9WYh5ib7X8';

      // Cloudinary signature parameters must be sorted alphabetically
      final sortedParams = 'timestamp=$timestamp&upload_preset=$uploadPreset$apiSecret';
      final signature = sha1.convert(utf8.encode(sortedParams)).toString();

      final url = Uri.parse('https://api.cloudinary.com/v1_1/vbc9yur2/image/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..fields['api_key'] = apiKey
        ..fields['timestamp'] = timestamp
        ..fields['signature'] = signature
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      if (response.statusCode == 200 || response.statusCode == 201) {
        final resBytes = await response.stream.toBytes();
        final resString = String.fromCharCodes(resBytes);
        final json = jsonDecode(resString);
        return json['secure_url'] as String;
      } else {
        final resBytes = await response.stream.toBytes();
        final resString = String.fromCharCodes(resBytes);
        throw Exception('Cloudinary upload failed: ${response.statusCode} - $resString');
      }
    } else {
      // Upload to Firebase Storage for video/file
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split(Platform.pathSeparator).last}';
      final ref = _storage.ref().child('posts/$imamId/$fileName');
      await ref.putFile(file);
      return ref.getDownloadURL();
    }
  }

  /// Saves a new post to Firestore.
  Future<void> createPost(PostModel post) async {
    final docRef = _posts.doc();
    final newPost = post.copyWith(id: docRef.id);
    await docRef.set(newPost.toFirestore());
  }

  /// Updates an existing post.
  Future<void> updatePost(PostModel post) async {
    await _posts.doc(post.id).update(post.toFirestore());
  }

  /// Deletes a post.
  Future<void> deletePost(String postId) async {
    await _posts.doc(postId).delete();
  }

  /// Streams comments of a post, ordered by createdAt ascending.
  Stream<List<CommentModel>> watchComments(String postId) {
    return _posts
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CommentModel.fromFirestore(doc)).toList();
    });
  }

  /// Deletes a comment from a post.
  Future<void> deleteComment(String postId, String commentId) async {
    await _posts.doc(postId).collection('comments').doc(commentId).delete();
  }

  /// Streams likes of a post, ordered by likedAt descending.
  Stream<List<LikeModel>> watchLikes(String postId) {
    return _posts
        .doc(postId)
        .collection('likes')
        .orderBy('likedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => LikeModel.fromFirestore(doc)).toList();
    });
  }
}

final postsRepositoryProvider = Provider<PostsRepository>((ref) {
  return PostsRepository(
    firestore: ref.watch(firestoreProvider),
    storage: ref.watch(firebaseStorageProvider),
  );
});

final postCommentsProvider = StreamProvider.family<List<CommentModel>, String>((ref, postId) {
  return ref.watch(postsRepositoryProvider).watchComments(postId);
});

final postLikesProvider = StreamProvider.family<List<LikeModel>, String>((ref, postId) {
  return ref.watch(postsRepositoryProvider).watchLikes(postId);
});
