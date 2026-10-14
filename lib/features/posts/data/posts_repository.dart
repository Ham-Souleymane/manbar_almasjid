import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../../../core/providers/firebase_providers.dart';
import '../../../core/providers/media_upload_provider.dart';
import '../../../core/services/media_upload_service.dart';
import 'post_model.dart';
import 'comment_model.dart';
import 'like_model.dart';

class PostsRepository {
  PostsRepository({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
    MediaUploadService? mediaUploadService,
  })  : _firestore = firestore,
        _storage = storage,
        _mediaUploadService = mediaUploadService ?? MediaUploadService();

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final MediaUploadService _mediaUploadService;

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

  /// Uploads media to Media VPS server (primary and sole upload target).
  Future<String> uploadPostMedia({
    required File file,
    required String imamId,
    required String mediaType,
  }) async {
    final uploaded = await _mediaUploadService.uploadFile(
      file: file,
      category: 'posts',
      userId: imamId,
    );
    return uploaded.url;
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
    mediaUploadService: ref.watch(mediaUploadServiceProvider),
  );
});

final postCommentsProvider = StreamProvider.family<List<CommentModel>, String>((ref, postId) {
  return ref.watch(postsRepositoryProvider).watchComments(postId);
});

final postLikesProvider = StreamProvider.family<List<LikeModel>, String>((ref, postId) {
  return ref.watch(postsRepositoryProvider).watchLikes(postId);
});
