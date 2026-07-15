import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../posts/data/comment_model.dart';
import '../../posts/data/post_model.dart';
import '../../registration/domain/imam_model.dart';
import '../../registration/domain/mosque_model.dart';
import 'report_model.dart';

class AdminRepository {
  final FirebaseFirestore _db;

  AdminRepository(this._db);

  // ── Pending Imams ──────────────────────────────────────────
  Stream<List<ImamModel>> watchPendingImams() {
    return _db
        .collection('imams')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ImamModel.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>))
            .toList());
  }

  Future<void> approveImam(String imamId, String? mosqueId) async {
    final batch = _db.batch();
    batch.update(_db.collection('imams').doc(imamId), {'status': 'verified'});
    if (mosqueId != null && mosqueId.isNotEmpty) {
      batch.update(_db.collection('mosques').doc(mosqueId), {'verified': true});
    }
    await batch.commit();
  }

  Future<void> rejectImam(String imamId, {String? reason}) async {
    await _db.collection('imams').doc(imamId).update({
      'status': 'rejected',
      if (reason != null && reason.isNotEmpty) 'rejectionReason': reason,
    });
  }

  // ── All Imams ──────────────────────────────────────────────
  Stream<List<ImamModel>> watchAllImams() {
    return _db
        .collection('imams')
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => ImamModel.fromFirestore(
                  doc as DocumentSnapshot<Map<String, dynamic>>))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<void> blockImam(String imamId) async {
    await _db.collection('imams').doc(imamId).update({'status': 'blocked'});
  }

  Future<void> unblockImam(String imamId) async {
    await _db.collection('imams').doc(imamId).update({'status': 'verified'});
  }

  Future<void> deleteImam(String imamId) async {
    await _db.collection('imams').doc(imamId).delete();
  }

  // ── Reports ───────────────────────────────────────────────
  Stream<List<ReportModel>> watchReports() {
    return _db
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => ReportModel.fromFirestore(doc)).toList());
  }

  Future<void> dismissReport(String reportId) async {
    await _db
        .collection('reports')
        .doc(reportId)
        .update({'status': 'reviewed'});
  }

  Future<void> deleteReportedContent(ReportModel report) async {
    final batch = _db.batch();
    if (report.type == 'comment' &&
        report.commentId != null &&
        report.commentId!.isNotEmpty) {
      batch.delete(_db
          .collection('posts')
          .doc(report.postId)
          .collection('comments')
          .doc(report.commentId!));
    } else {
      batch.delete(_db.collection('posts').doc(report.postId));
    }
    // Mark report as reviewed
    batch.update(_db.collection('reports').doc(report.id),
        {'status': 'reviewed'});
    await batch.commit();
  }

  // ── All Mosques ───────────────────────────────────────────
  Stream<List<MosqueModel>> watchAllMosques() {
    return _db
        .collection('mosques')
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => MosqueModel.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>))
            .toList());
  }

  Future<void> revokeVerification(String mosqueId) async {
    await _db
        .collection('mosques')
        .doc(mosqueId)
        .update({'verified': false});
  }

  Future<void> deleteMosqueAsAdmin(String mosqueId) async {
    await _db.collection('mosques').doc(mosqueId).delete();
  }

  // ── Dashboard Stats ───────────────────────────────────────
  Future<Map<String, int>> getDashboardStats() async {
    final results = await Future.wait([
      _db
          .collection('imams')
          .where('status', isEqualTo: 'pending')
          .count()
          .get(),
      _db
          .collection('reports')
          .where('status', isEqualTo: 'open')
          .count()
          .get(),
      _db.collection('mosques').count().get(),
      _db.collection('posts').count().get(),
    ]);
    return {
      'pendingImams': results[0].count ?? 0,
      'openReports': results[1].count ?? 0,
      'totalMosques': results[2].count ?? 0,
      'totalPosts': results[3].count ?? 0,
    };
  }
  // ── All Posts (admin) ─────────────────────────────────────
  /// Fetches the first [limit] posts, newest first, optionally filtered by category.
  Future<List<PostModel>> fetchAllPosts({
    String? category,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    Query<Map<String, dynamic>> query = _db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (category != null && category != 'الكل') {
      query = query.where('category', isEqualTo: category);
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snap = await query.get();
    return snap.docs
        .map((doc) => PostModel.fromFirestore(
            doc as DocumentSnapshot<Map<String, dynamic>>))
        .toList();
  }

  /// Returns the raw [DocumentSnapshot] for a post (needed for pagination cursor).
  Future<DocumentSnapshot?> getPostSnapshot(String postId) async {
    final doc = await _db.collection('posts').doc(postId).get();
    return doc.exists ? doc : null;
  }

  Future<void> deletePostAsAdmin(String postId) async {
    await _db.collection('posts').doc(postId).delete();
  }

  Stream<List<CommentModel>> watchCommentsForPost(String postId) {
    return _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => CommentModel.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>))
            .toList());
  }

  Future<void> deleteCommentAsAdmin(String postId, String commentId) async {
    await _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .delete();
  }
}

// ── Provider ─────────────────────────────────────────────────
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(FirebaseFirestore.instance);
});

final pendingImamsProvider = StreamProvider<List<ImamModel>>((ref) {
  return ref.watch(adminRepositoryProvider).watchPendingImams();
});

final allImamsProvider = StreamProvider<List<ImamModel>>((ref) {
  final isAdmin = ref.watch(isAdminProvider).value ?? false;
  if (!isAdmin) {
    return const Stream.empty();
  }
  return ref.watch(adminRepositoryProvider).watchAllImams();
});

final reportsProvider = StreamProvider<List<ReportModel>>((ref) {
  final isAdmin = ref.watch(isAdminProvider).value ?? false;
  if (!isAdmin) {
    return const Stream.empty();
  }
  return ref.watch(adminRepositoryProvider).watchReports();
});

final allMosquesProvider = StreamProvider<List<MosqueModel>>((ref) {
  return ref.watch(adminRepositoryProvider).watchAllMosques();
});

final adminStatsProvider = FutureProvider<Map<String, int>>((ref) {
  return ref.watch(adminRepositoryProvider).getDashboardStats();
});
