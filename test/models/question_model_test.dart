import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manbar_almasjid/features/questions/domain/islamic_field.dart';
import 'package:manbar_almasjid/features/questions/domain/question_model.dart';

void main() {
  group('IslamicField Tests', () {
    test('Matches both Arabic and English identifiers', () {
      expect(IslamicField.matches('fiqh', 'fiqh'), isTrue);
      expect(IslamicField.matches('الفقه', 'fiqh'), isTrue);
      expect(IslamicField.matches('fiqh', 'الفقه'), isTrue);
      expect(IslamicField.matches('فتاوى', 'fiqh'), isTrue);
      expect(IslamicField.matches('العقيدة', 'aqeedah'), isTrue);
      expect(IslamicField.matches('التفسير وعلومه', 'tafsir'), isTrue);
      expect(IslamicField.matches('الحديث الشريف', 'hadith'), isTrue);
      expect(IslamicField.matches('any', 'all'), isTrue);
      expect(IslamicField.matches('fiqh', 'aqeedah'), isFalse);
    });

    test('labelForId returns appropriate localized label', () {
      expect(IslamicField.labelForId('fiqh', isArabic: true), 'الفقه');
      expect(IslamicField.labelForId('الفقه', isArabic: true), 'الفقه');
      expect(IslamicField.labelForId('fiqh', isArabic: false), 'Fiqh');
      expect(IslamicField.labelForId(null, isArabic: true), 'عام');
    });
  });

  group('QuestionStatus Tests', () {
    test('Parses multiple string representations', () {
      expect(QuestionStatus.fromString('pending'), QuestionStatus.pending);
      expect(QuestionStatus.fromString('open'), QuestionStatus.pending);
      expect(QuestionStatus.fromString('new'), QuestionStatus.pending);
      expect(QuestionStatus.fromString('قيد الانتظار'), QuestionStatus.pending);
      expect(QuestionStatus.fromString('answered'), QuestionStatus.answered);
      expect(QuestionStatus.fromString('resolved'), QuestionStatus.answered);
      expect(QuestionStatus.fromString('تمت الإجابة'), QuestionStatus.answered);
      expect(QuestionStatus.fromString('rejected'), QuestionStatus.rejected);
      expect(QuestionStatus.fromString(null), QuestionStatus.pending);
    });
  });

  group('QuestionModel Serialization & Robustness Tests', () {
    test('Parses doc with ISO date string and aliased fields', () {
      final data = <String, dynamic>{
        'question': 'ما هو حكم قراءة سورة الكهف يوم الجمعة؟',
        'category': 'الفقه',
        'userName': 'أحمد',
        'is_anonymous': false,
        'imam_id': 'imam_123',
        'mosque_id': 'mosque_456',
        'created_at': '2026-08-30T10:00:00.000Z',
        'status': 'open',
      };

      final doc = _MockDocSnapshot('q_1', data);
      final model = QuestionModel.fromFirestore(doc);

      expect(model.id, 'q_1');
      expect(model.title, 'ما هو حكم قراءة سورة الكهف يوم الجمعة؟');
      expect(model.body, 'ما هو حكم قراءة سورة الكهف يوم الجمعة؟');
      expect(model.userDisplayName, 'أحمد');
      expect(model.isAnonymous, isFalse);
      expect(model.imamId, 'imam_123');
      expect(model.mosqueId, 'mosque_456');
      expect(model.field, 'الفقه');
      expect(model.status, QuestionStatus.pending);
      expect(model.createdAt.year, 2026);
    });

    test('Parses doc with integer timestamp and anonymous user', () {
      final data = <String, dynamic>{
        'title': 'سؤال عن الزكاة',
        'text': 'كيف تحسب زكاة المال المدخر؟',
        'specialty': 'fiqh',
        'anonymous': true,
        'sheikhId': 'sheikh_99',
        'timestamp': 1756569600000,
        'status': 'answered',
        'reply': 'تخرج 2.5% بعد مرور الحول وبلوغ النصاب.',
        'replyDate': '2026-08-30T14:00:00.000Z',
      };

      final doc = _MockDocSnapshot('q_2', data);
      final model = QuestionModel.fromFirestore(doc);

      expect(model.id, 'q_2');
      expect(model.title, 'سؤال عن الزكاة');
      expect(model.body, 'كيف تحسب زكاة المال المدخر؟');
      expect(model.userDisplayName, 'مجهول');
      expect(model.isAnonymous, isTrue);
      expect(model.imamId, 'sheikh_99');
      expect(model.status, QuestionStatus.answered);
      expect(model.answer, 'تخرج 2.5% بعد مرور الحول وبلوغ النصاب.');
      expect(model.answeredAt, isNotNull);
    });

    test('Parses doc with Firestore Timestamp and standard fields', () {
      final now = DateTime.now();
      final data = <String, dynamic>{
        'title': 'استشارة أسرية',
        'body': 'نص الاستشارة...',
        'userId': 'user_1',
        'userDisplayName': 'خالد',
        'isAnonymous': false,
        'imamId': 'imam_1',
        'field': 'fiqh',
        'createdAt': Timestamp.fromDate(now),
        'status': 'pending',
      };

      final doc = _MockDocSnapshot('q_3', data);
      final model = QuestionModel.fromFirestore(doc);

      expect(model.id, 'q_3');
      expect(model.title, 'استشارة أسرية');
      expect(model.body, 'نص الاستشارة...');
      expect(model.userId, 'user_1');
      expect(model.userDisplayName, 'خالد');
      expect(model.isAnonymous, isFalse);
      expect(model.status, QuestionStatus.pending);
    });

    test('toFirestore outputs expected fields', () {
      final model = QuestionModel(
        id: 'q_4',
        userId: 'u_1',
        userDisplayName: 'عمر',
        isAnonymous: false,
        imamId: 'i_1',
        mosqueId: 'm_1',
        imamName: 'الشيخ عمر',
        field: 'fiqh',
        title: 'عنوان السؤال',
        body: 'تفاصيل السؤال',
        status: QuestionStatus.pending,
        createdAt: DateTime(2026, 8, 30),
      );

      final map = model.toFirestore();
      expect(map['userId'], 'u_1');
      expect(map['imamId'], 'i_1');
      expect(map['mosqueId'], 'm_1');
      expect(map['status'], 'pending');
      expect(map['createdAt'], isA<Timestamp>());
    });

    test('Follow-up thread and QuestionReply parsing & helpers', () {
      final replyUser = <String, dynamic>{
        'id': 'rep_1',
        'senderId': 'user_1',
        'senderRole': 'user',
        'senderName': 'أحمد',
        'message': 'هل يشمل ذلك الذهب المعد للاستعمال الشخصي؟',
        'createdAt': '2026-08-30T15:00:00.000Z',
      };

      final replyImam = <String, dynamic>{
        'id': 'rep_2',
        'senderId': 'imam_1',
        'senderRole': 'imam',
        'senderName': 'الشيخ',
        'message': 'ذهب الزينة المعد للاستعمال لا تجب فيه الزكاة عند الجمهور.',
        'createdAt': '2026-08-30T15:30:00.000Z',
      };

      final data = <String, dynamic>{
        'title': 'سؤال عن زكاة الذهب',
        'body': 'ما حكم زكاة حلي المرأة؟',
        'userId': 'user_1',
        'userDisplayName': 'أحمد',
        'isAnonymous': false,
        'imamId': 'imam_1',
        'field': 'fiqh',
        'createdAt': '2026-08-30T12:00:00.000Z',
        'status': 'answered',
        'answer': 'تجب الزكاة إذا بلغ النصاب وحال عليه الحول.',
        'answeredAt': '2026-08-30T13:00:00.000Z',
        'replies': [replyUser, replyImam],
      };

      final doc = _MockDocSnapshot('q_follow_up', data);
      final model = QuestionModel.fromFirestore(doc);

      expect(model.hasFollowUps, isTrue);
      expect(model.replies.length, 2);
      expect(model.replies.first.isFromUser, isTrue);
      expect(model.replies.last.isFromImam, isTrue);
      expect(model.isFollowUpPending, isFalse);
      expect(model.canUserAskFollowUp, isTrue);

      // Now test when user asks another follow-up and status becomes pending
      final pendingFollowUpData = Map<String, dynamic>.from(data);
      pendingFollowUpData['status'] = 'pending';
      pendingFollowUpData['replies'] = [
        replyUser,
        replyImam,
        <String, dynamic>{
          'id': 'rep_3',
          'senderId': 'user_1',
          'senderRole': 'user',
          'senderName': 'أحمد',
          'message': 'وماذا عن الذهب المدخر للتجارة؟',
          'createdAt': '2026-08-30T16:00:00.000Z',
        },
      ];

      final docPending = _MockDocSnapshot('q_pending_follow_up', pendingFollowUpData);
      final modelPending = QuestionModel.fromFirestore(docPending);

      expect(modelPending.hasFollowUps, isTrue);
      expect(modelPending.isFollowUpPending, isTrue);
      expect(modelPending.canUserAskFollowUp, isFalse);
      expect(modelPending.latestUserInquiry?.message, 'وماذا عن الذهب المدخر للتجارة؟');
      expect(modelPending.latestReply?.senderRole, 'user');
    });
  });
}

class _MockDocSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  _MockDocSnapshot(this._id, this._data);

  final String _id;
  final Map<String, dynamic> _data;

  @override
  String get id => _id;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  bool get exists => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
