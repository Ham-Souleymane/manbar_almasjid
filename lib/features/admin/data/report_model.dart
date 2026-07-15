import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a content report submitted by a worshipper.
class ReportModel {
  final String id;
  final String reason;
  final String reportedBy;
  final DateTime createdAt;
  final String status; // 'open' | 'reviewed'
  final String type;   // 'post' | 'comment'
  final String postId;
  final String? commentId;
  final String snapshot; // content text at time of report

  const ReportModel({
    required this.id,
    required this.reason,
    required this.reportedBy,
    required this.createdAt,
    required this.status,
    required this.type,
    required this.postId,
    this.commentId,
    required this.snapshot,
  });

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReportModel(
      id: doc.id,
      reason: data['reason'] as String? ?? '',
      reportedBy: data['reportedBy'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] as String? ?? 'open',
      type: data['type'] as String? ?? 'post',
      postId: data['postId'] as String? ?? '',
      commentId: data['commentId'] as String?,
      snapshot: data['snapshot'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'reason': reason,
        'reportedBy': reportedBy,
        'createdAt': Timestamp.fromDate(createdAt),
        'status': status,
        'type': type,
        'postId': postId,
        if (commentId != null) 'commentId': commentId,
        'snapshot': snapshot,
      };
}
