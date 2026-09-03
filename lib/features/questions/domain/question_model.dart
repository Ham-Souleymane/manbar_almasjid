import 'package:cloud_firestore/cloud_firestore.dart';

enum QuestionStatus {
  pending,
  answered,
  rejected;

  static QuestionStatus fromString(String? s) {
    if (s == null) return pending;
    final clean = s.trim().toLowerCase();
    switch (clean) {
      case 'answered':
      case 'resolved':
      case 'closed':
      case 'done':
      case 'مُجاب':
      case 'مجاب':
      case 'تمت الإجابة':
      case 'تم الرد':
        return answered;
      case 'rejected':
      case 'declined':
      case 'cancelled':
      case 'مرفوض':
      case 'ملغى':
        return rejected;
      case 'pending':
      case 'open':
      case 'new':
      case 'waiting':
      case 'قيد الانتظار':
      case 'جديد':
      default:
        return pending;
    }
  }

  String get value {
    switch (this) {
      case pending:
        return 'pending';
      case answered:
        return 'answered';
      case rejected:
        return 'rejected';
    }
  }

  String labelAr() {
    switch (this) {
      case pending:
        return 'قيد الانتظار';
      case answered:
        return 'تمت الإجابة';
      case rejected:
        return 'مرفوض';
    }
  }
}

/// Represents a single reply or follow-up inquiry in the question's conversation thread.
class QuestionReply {
  const QuestionReply({
    required this.id,
    required this.senderId,
    required this.senderRole, // 'user' | 'imam'
    required this.senderName,
    this.senderPhotoUrl,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String senderRole;
  final String senderName;
  final String? senderPhotoUrl;
  final String message;
  final DateTime createdAt;

  bool get isFromImam => senderRole.toLowerCase() == 'imam';
  bool get isFromUser => senderRole.toLowerCase() == 'user';

  factory QuestionReply.fromMap(Map<String, dynamic> map, {String? defaultId}) {
    final role = (map['senderRole']?.toString() ?? map['role']?.toString() ?? 'user').toLowerCase();
    return QuestionReply(
      id: map['id']?.toString() ?? defaultId ?? '',
      senderId: map['senderId']?.toString() ?? map['sender_id']?.toString() ?? '',
      senderRole: role,
      senderName: map['senderName']?.toString() ??
          map['name']?.toString() ??
          (role == 'imam' ? 'الشيخ' : 'مُصلٍّ'),
      senderPhotoUrl: map['senderPhotoUrl']?.toString() ??
          map['photoUrl']?.toString() ??
          map['avatar']?.toString(),
      message: map['message']?.toString() ??
          map['content']?.toString() ??
          map['text']?.toString() ??
          map['reply']?.toString() ??
          '',
      createdAt: QuestionModel.parseDate(map['createdAt'] ?? map['timestamp'] ?? map['created_at']) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderRole': senderRole,
      'senderName': senderName,
      if (senderPhotoUrl != null && senderPhotoUrl!.isNotEmpty) 'senderPhotoUrl': senderPhotoUrl,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class QuestionModel {
  const QuestionModel({
    required this.id,
    required this.userId,
    required this.userDisplayName,
    required this.isAnonymous,
    required this.imamId,
    this.mosqueId,
    required this.imamName,
    required this.field,
    required this.title,
    required this.body,
    required this.status,
    required this.createdAt,
    this.imamPhotoUrl,
    this.answer,
    this.answeredAt,
    this.lastActivityAt,
    this.replies = const [],
    this.isReadByAsker = false,
  });

  final String id;
  final String userId;
  final String userDisplayName;
  final bool isAnonymous;
  final String imamId;
  final String? mosqueId;
  final String imamName;
  final String? imamPhotoUrl;
  final String field;
  final String title;
  final String body;
  final QuestionStatus status;
  final String? answer;
  final DateTime? answeredAt;
  final DateTime? lastActivityAt;
  final List<QuestionReply> replies;
  final DateTime createdAt;
  final bool isReadByAsker;

  bool get isAnswered => status == QuestionStatus.answered;
  bool get isPending => status == QuestionStatus.pending;
  bool get hasFollowUps => replies.isNotEmpty;
  bool get isFollowUpPending =>
      replies.isNotEmpty && replies.last.isFromUser && isPending;
  bool get canUserAskFollowUp => isAnswered && !isFollowUpPending;

  QuestionReply? get latestReply => replies.isNotEmpty ? replies.last : null;

  QuestionReply? get latestUserInquiry {
    final userReplies = replies.where((r) => r.isFromUser).toList();
    return userReplies.isNotEmpty ? userReplies.last : null;
  }

  static DateTime? parseDate(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    if (val is String) return DateTime.tryParse(val);
    return null;
  }

  static DateTime _parseCreatedAt(dynamic val) {
    return parseDate(val) ?? DateTime.now();
  }

  static bool _parseBool(dynamic val, {bool defaultValue = false}) {
    if (val == null) return defaultValue;
    if (val is bool) return val;
    if (val is num) return val != 0;
    if (val is String) {
      final s = val.trim().toLowerCase();
      if (s == 'true' || s == '1' || s == 'yes') return true;
      if (s == 'false' || s == '0' || s == 'no') return false;
    }
    return defaultValue;
  }

  factory QuestionModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};

    final rawBody = d['body']?.toString() ??
        d['question']?.toString() ??
        d['text']?.toString() ??
        d['content']?.toString() ??
        d['message']?.toString() ??
        d['details']?.toString() ??
        '';

    final rawTitle = d['title']?.toString() ??
        d['subject']?.toString() ??
        d['questionTitle']?.toString() ??
        d['header']?.toString() ??
        '';

    final resolvedTitle = rawTitle.isNotEmpty
        ? rawTitle
        : (rawBody.isNotEmpty
            ? (rawBody.length > 50 ? '${rawBody.substring(0, 50)}...' : rawBody)
            : 'استفسار شرعي');

    final resolvedBody = rawBody.isNotEmpty ? rawBody : rawTitle;

    final rawUserDisplayName = d['userDisplayName']?.toString() ??
        d['userName']?.toString() ??
        d['name']?.toString() ??
        d['askerName']?.toString() ??
        d['senderName']?.toString() ??
        d['authorName']?.toString() ??
        '';

    final resolvedUserDisplayName =
        rawUserDisplayName.isNotEmpty ? rawUserDisplayName : 'مُصلٍّ';

    final isAnon = _parseBool(
      d['isAnonymous'] ??
          d['anonymous'] ??
          d['is_anonymous'] ??
          d['isPrivate'] ??
          d['private'],
      defaultValue: false,
    );

    final rawField = d['field']?.toString() ??
        d['category']?.toString() ??
        d['specialty']?.toString() ??
        d['topic']?.toString() ??
        'fiqh';

    final rawImamId = d['imamId']?.toString() ??
        d['imam_id']?.toString() ??
        d['sheikhId']?.toString() ??
        d['targetImamId']?.toString() ??
        d['assignedImamId']?.toString() ??
        '';

    final rawMosqueId = d['mosqueId']?.toString() ??
        d['mosque_id']?.toString() ??
        d['targetMosqueId']?.toString();

    final rawAnswer = d['answer']?.toString() ??
        d['reply']?.toString() ??
        d['response']?.toString();

    final rawReplies = d['replies'];
    final List<QuestionReply> parsedReplies = [];
    if (rawReplies is List) {
      for (int i = 0; i < rawReplies.length; i++) {
        final item = rawReplies[i];
        if (item is Map<String, dynamic>) {
          parsedReplies.add(QuestionReply.fromMap(item, defaultId: 'reply_$i'));
        } else if (item is Map) {
          parsedReplies.add(QuestionReply.fromMap(
            Map<String, dynamic>.from(item),
            defaultId: 'reply_$i',
          ));
        }
      }
    }

    final createdAtDate = _parseCreatedAt(
      d['createdAt'] ?? d['timestamp'] ?? d['created_at'] ?? d['date'],
    );

    final lastActivityDate = parseDate(
      d['lastActivityAt'] ?? d['last_activity_at'] ?? d['updatedAt'],
    ) ?? (parsedReplies.isNotEmpty ? parsedReplies.last.createdAt : null);

    return QuestionModel(
      id: doc.id,
      userId: d['userId']?.toString() ??
          d['user_id']?.toString() ??
          d['askerId']?.toString() ??
          d['senderId']?.toString() ??
          d['uid']?.toString() ??
          '',
      userDisplayName: isAnon ? 'مجهول' : resolvedUserDisplayName,
      isAnonymous: isAnon,
      imamId: rawImamId,
      mosqueId: rawMosqueId,
      imamName: d['imamName']?.toString() ??
          d['sheikhName']?.toString() ??
          '',
      imamPhotoUrl: d['imamPhotoUrl']?.toString() ??
          d['imamPhoto']?.toString() ??
          d['photoUrl']?.toString(),
      field: rawField,
      title: resolvedTitle,
      body: resolvedBody,
      status: QuestionStatus.fromString(d['status']?.toString()),
      answer: rawAnswer,
      answeredAt: parseDate(
        d['answeredAt'] ?? d['answered_at'] ?? d['replyDate'],
      ),
      lastActivityAt: lastActivityDate,
      replies: parsedReplies,
      createdAt: createdAtDate,
      isReadByAsker: _parseBool(
        d['isReadByAsker'] ?? d['is_read_by_asker'] ?? d['isRead'],
        defaultValue: false,
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userDisplayName': userDisplayName,
      'isAnonymous': isAnonymous,
      'imamId': imamId,
      if (mosqueId != null && mosqueId!.isNotEmpty) 'mosqueId': mosqueId,
      'imamName': imamName,
      if (imamPhotoUrl != null) 'imamPhotoUrl': imamPhotoUrl,
      'field': field,
      'title': title,
      'body': body,
      'status': status.value,
      if (answer != null) 'answer': answer,
      if (answeredAt != null)
        'answeredAt': Timestamp.fromDate(answeredAt!),
      if (lastActivityAt != null)
        'lastActivityAt': Timestamp.fromDate(lastActivityAt!),
      if (replies.isNotEmpty)
        'replies': replies.map((r) => r.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'isReadByAsker': isReadByAsker,
    };
  }

  QuestionModel copyWith({
    String? id,
    String? userId,
    String? userDisplayName,
    bool? isAnonymous,
    String? imamId,
    String? mosqueId,
    String? imamName,
    String? imamPhotoUrl,
    String? field,
    String? title,
    String? body,
    QuestionStatus? status,
    String? answer,
    DateTime? answeredAt,
    DateTime? lastActivityAt,
    List<QuestionReply>? replies,
    DateTime? createdAt,
    bool? isReadByAsker,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      imamId: imamId ?? this.imamId,
      mosqueId: mosqueId ?? this.mosqueId,
      imamName: imamName ?? this.imamName,
      imamPhotoUrl: imamPhotoUrl ?? this.imamPhotoUrl,
      field: field ?? this.field,
      title: title ?? this.title,
      body: body ?? this.body,
      status: status ?? this.status,
      answer: answer ?? this.answer,
      answeredAt: answeredAt ?? this.answeredAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      replies: replies ?? this.replies,
      createdAt: createdAt ?? this.createdAt,
      isReadByAsker: isReadByAsker ?? this.isReadByAsker,
    );
  }
}
