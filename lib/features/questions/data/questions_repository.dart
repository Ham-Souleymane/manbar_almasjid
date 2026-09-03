import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../registration/data/registration_repository.dart';
import '../domain/islamic_field.dart';
import '../domain/question_model.dart';

class QuestionsRepository {
  QuestionsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _questions =>
      _firestore.collection('questions');

  CollectionReference<Map<String, dynamic>> get _imams =>
      _firestore.collection('imams');

  List<QuestionModel> _processSnapshots(
    List<QuerySnapshot<Map<String, dynamic>>> snapshots, {
    String? field,
    QuestionStatus? status,
  }) {
    final map = <String, QuestionModel>{};

    for (final snap in snapshots) {
      for (final doc in snap.docs) {
        if (!doc.exists) continue;
        try {
          final model = QuestionModel.fromFirestore(doc);
          map[doc.id] = model;
        } catch (_) {
          // Ignore malformed doc rather than breaking the entire stream
        }
      }
    }

    final list = map.values.toList();
    list.sort((a, b) {
      final timeA = a.lastActivityAt ?? a.createdAt;
      final timeB = b.lastActivityAt ?? b.createdAt;
      return timeB.compareTo(timeA);
    });

    return list.where((q) {
      if (status != null && q.status != status) {
        return false;
      }
      if (field != null && field.isNotEmpty && field != 'all') {
        return IslamicField.matches(q.field, field);
      }
      return true;
    }).toList();
  }

  /// Watches all questions assigned to a given imam and/or their mosque, newest first.
  Stream<List<QuestionModel>> watchImamQuestions(
    String imamId, {
    String? mosqueId,
    String? field,
    QuestionStatus? status,
  }) {
    final validImamId = imamId.trim();
    final validMosqueId = (mosqueId != null && mosqueId.trim().isNotEmpty && mosqueId.trim() != validImamId)
        ? mosqueId.trim()
        : null;

    if (validImamId.isEmpty && validMosqueId == null) {
      return Stream.value([]);
    }

    if (validImamId.isNotEmpty && validMosqueId == null) {
      return _questions
          .where('imamId', isEqualTo: validImamId)
          .snapshots()
          .map((snap) => _processSnapshots([snap], field: field, status: status));
    }

    if (validImamId.isEmpty && validMosqueId != null) {
      return _questions
          .where('mosqueId', isEqualTo: validMosqueId)
          .snapshots()
          .map((snap) => _processSnapshots([snap], field: field, status: status));
    }

    // Both validImamId and validMosqueId are available -> listen to both streams
    final imamStream = _questions.where('imamId', isEqualTo: validImamId).snapshots();
    final mosqueStream = _questions.where('mosqueId', isEqualTo: validMosqueId).snapshots();

    QuerySnapshot<Map<String, dynamic>>? latestImamSnap;
    QuerySnapshot<Map<String, dynamic>>? latestMosqueSnap;

    late StreamController<List<QuestionModel>> controller;
    StreamSubscription? sub1;
    StreamSubscription? sub2;

    void emitLatest() {
      if (controller.isClosed) return;
      final snaps = <QuerySnapshot<Map<String, dynamic>>>[];
      if (latestImamSnap != null) snaps.add(latestImamSnap!);
      if (latestMosqueSnap != null) snaps.add(latestMosqueSnap!);
      controller.add(_processSnapshots(snaps, field: field, status: status));
    }

    controller = StreamController<List<QuestionModel>>.broadcast(
      onListen: () {
        sub1 = imamStream.listen(
          (snap) {
            latestImamSnap = snap;
            emitLatest();
          },
          onError: (e) {
            emitLatest();
          },
        );
        sub2 = mosqueStream.listen(
          (snap) {
            latestMosqueSnap = snap;
            emitLatest();
          },
          onError: (e) {
            emitLatest();
          },
        );
      },
      onCancel: () {
        sub1?.cancel();
        sub2?.cancel();
      },
    );

    return controller.stream;
  }

  /// Count of pending questions for an imam and/or mosque.
  Stream<int> watchPendingQuestionsCount(
    String imamId, {
    String? mosqueId,
  }) {
    return watchImamQuestions(
      imamId,
      mosqueId: mosqueId,
      status: QuestionStatus.pending,
    ).map((list) => list.length);
  }

  /// Posts the imam's initial answer. Updates status -> answered.
  Future<void> submitAnswer({
    required String questionId,
    required String answer,
    required String imamId,
  }) async {
    final batch = _firestore.batch();

    batch.set(
      _questions.doc(questionId),
      {
        'answer': answer,
        'status': QuestionStatus.answered.value,
        'answeredAt': FieldValue.serverTimestamp(),
        'lastActivityAt': FieldValue.serverTimestamp(),
        'isReadByAsker': false,
      },
      SetOptions(merge: true),
    );

    if (imamId.isNotEmpty) {
      batch.set(
        _imams.doc(imamId),
        {
          'answeredCount': FieldValue.increment(1),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  /// Submits the imam's response to a worshipper's follow-up inquiry.
  Future<void> submitFollowUpAnswer({
    required String questionId,
    required String answer,
    required String imamId,
    String? imamName,
    String? imamPhotoUrl,
  }) async {
    final reply = QuestionReply(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: imamId,
      senderRole: 'imam',
      senderName: (imamName != null && imamName.isNotEmpty) ? imamName : 'الشيخ',
      senderPhotoUrl: imamPhotoUrl,
      message: answer,
      createdAt: DateTime.now(),
    );

    final batch = _firestore.batch();

    batch.set(
      _questions.doc(questionId),
      {
        'status': QuestionStatus.answered.value,
        'isReadByAsker': false,
        'lastActivityAt': FieldValue.serverTimestamp(),
        'replies': FieldValue.arrayUnion([reply.toMap()]),
      },
      SetOptions(merge: true),
    );

    if (imamId.isNotEmpty) {
      batch.set(
        _imams.doc(imamId),
        {
          'answeredCount': FieldValue.increment(1),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  /// Updates imam specialization fields in Firestore.
  Future<void> updateImamSpecializationFields({
    required String imamId,
    required List<String> fields,
  }) async {
    await _imams.doc(imamId).set(
      {
        'fields': fields,
        'specialties': fields,
      },
      SetOptions(merge: true),
    );
  }
}

// ── Providers ─────────────────────────────────────────────────

final questionsRepositoryProvider = Provider<QuestionsRepository>((ref) {
  return QuestionsRepository(ref.watch(firestoreProvider));
});

/// Automatically streams incoming questions for the currently signed-in imam and mosque.
final currentImamQuestionsStreamProvider =
    StreamProvider<List<QuestionModel>>((ref) {
  final imam = ref.watch(currentImamProvider).asData?.value;
  final mosque = ref.watch(currentMosqueProvider).asData?.value;
  final imamId = imam?.id ?? '';
  final mosqueId = imam?.mosqueId ?? mosque?.id;

  if (imamId.isEmpty && (mosqueId == null || mosqueId.isEmpty)) {
    return Stream.value([]);
  }

  return ref.watch(questionsRepositoryProvider).watchImamQuestions(
        imamId,
        mosqueId: mosqueId,
      );
});

final imamQuestionsStreamProvider =
    StreamProvider.family<List<QuestionModel>, String>((ref, imamId) {
  if (imamId.isEmpty) return Stream.value([]);
  final mosque = ref.watch(currentMosqueProvider).asData?.value;
  final imam = ref.watch(currentImamProvider).asData?.value;
  final mosqueId = imam?.mosqueId ?? mosque?.id;

  return ref
      .watch(questionsRepositoryProvider)
      .watchImamQuestions(imamId, mosqueId: mosqueId);
});

final pendingQuestionsCountProvider =
    StreamProvider.family<int, String>((ref, imamId) {
  if (imamId.isEmpty) return Stream.value(0);
  final mosque = ref.watch(currentMosqueProvider).asData?.value;
  final imam = ref.watch(currentImamProvider).asData?.value;
  final mosqueId = imam?.mosqueId ?? mosque?.id;

  return ref
      .watch(questionsRepositoryProvider)
      .watchPendingQuestionsCount(imamId, mosqueId: mosqueId);
});
