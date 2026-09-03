import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../registration/data/registration_repository.dart';
import '../data/questions_repository.dart';
import '../domain/islamic_field.dart';
import '../domain/question_model.dart';

class AnswerQuestionScreen extends ConsumerStatefulWidget {
  final QuestionModel question;
  final String imamId;

  const AnswerQuestionScreen({
    super.key,
    required this.question,
    required this.imamId,
  });

  @override
  ConsumerState<AnswerQuestionScreen> createState() =>
      _AnswerQuestionScreenState();
}

class _AnswerQuestionScreenState extends ConsumerState<AnswerQuestionScreen> {
  final _answerController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    // If it's an initial question that was answered (editing) and no pending follow-up:
    if (!widget.question.isFollowUpPending &&
        widget.question.answer != null &&
        widget.question.answer!.isNotEmpty) {
      _answerController.text = widget.question.answer!;
    }
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) {
      return 'الآن';
    } else if (diff.inMinutes < 60) {
      return 'منذ ${diff.inMinutes} د';
    } else if (diff.inHours < 24) {
      return 'منذ ${diff.inHours} س';
    } else if (diff.inDays == 1) {
      return 'أمس';
    } else if (diff.inDays < 7) {
      return 'منذ ${diff.inDays} أيام';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  Future<void> _publishAnswer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isPublishing = true);

    try {
      final answerText = _answerController.text.trim();
      final imam = ref.read(currentImamProvider).asData?.value;
      final imamName = imam?.fullName ?? widget.question.imamName;
      final imamPhoto = imam?.photo ?? widget.question.imamPhotoUrl;
      final imamId = widget.imamId.isNotEmpty ? widget.imamId : (imam?.id ?? '');

      if (widget.question.isFollowUpPending) {
        // Submit follow-up response
        await ref.read(questionsRepositoryProvider).submitFollowUpAnswer(
              questionId: widget.question.id,
              answer: answerText,
              imamId: imamId,
              imamName: imamName,
              imamPhotoUrl: imamPhoto,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم نشر الرد على استفسار المصلّي بنجاح ✅'),
              backgroundColor: Color(0xFF003527),
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        // Submit initial answer
        await ref.read(questionsRepositoryProvider).submitAnswer(
              questionId: widget.question.id,
              answer: answerText,
              imamId: imamId,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم نشر الإجابة وإشعار السائل بنجاح ✅'),
              backgroundColor: Color(0xFF003527),
            ),
          );
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل النشر: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final field = IslamicField.fromId(q.field);
    final isFollowUp = q.isFollowUpPending;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF003527),
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        title: Text(
          isFollowUp ? 'الرد على استفسار المصلّي' : 'الإجابة على السؤال',
          style: GoogleFonts.tajawal(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
          children: [
            // ── Top Header Notice if follow-up pending ──────────────
            if (isFollowUp) ...[
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mark_chat_unread_rounded,
                        color: Color(0xFFB45309), size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'استفسار إضافي جديد من السائل',
                            style: GoogleFonts.tajawal(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF92400E),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'قام السائل بطلب توضيح إضافي على إجابتكم السابقة.',
                            style: GoogleFonts.tajawal(
                              fontSize: 12,
                              color: const Color(0xFF78350F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── 1. Initial Question Overview Card ───────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDCE2F3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC3ECD7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          field != null
                              ? '${field.icon} ${field.labelAr}'
                              : IslamicField.labelForId(q.field, isArabic: true),
                          style: GoogleFonts.tajawal(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0B513D),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(
                            q.isAnonymous
                                ? Icons.visibility_off_rounded
                                : Icons.person_outline_rounded,
                            size: 14,
                            color: const Color(0xFF404944),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            q.isAnonymous
                                ? 'سؤال مجهول'
                                : (q.userDisplayName.isNotEmpty
                                    ? q.userDisplayName
                                    : 'مُصلٍّ'),
                            style: GoogleFonts.tajawal(
                              fontSize: 12,
                              color: const Color(0xFF404944),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '• ${_formatDate(q.createdAt)}',
                            style: GoogleFonts.tajawal(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    q.title,
                    style: GoogleFonts.tajawal(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF151C27),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    q.body,
                    style: GoogleFonts.tajawal(
                      fontSize: 14,
                      color: const Color(0xFF404944),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            // ── 2. Initial Answer Card (if exists) ───────────────────
            if (q.answer != null && q.answer!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_rounded,
                            color: Color(0xFF16A34A), size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'إجابتكم الأساسية',
                          style: GoogleFonts.tajawal(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF15803D),
                          ),
                        ),
                        const Spacer(),
                        if (q.answeredAt != null)
                          Text(
                            _formatDate(q.answeredAt!),
                            style: GoogleFonts.tajawal(
                              fontSize: 11,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      q.answer!,
                      style: GoogleFonts.tajawal(
                        fontSize: 14,
                        color: const Color(0xFF14532D),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── 3. Chronological Follow-Up Replies Thread ────────────
            if (q.replies.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.forum_rounded,
                      size: 18, color: Color(0xFF003527)),
                  const SizedBox(width: 8),
                  Text(
                    'سجل الاستفسارات والردود',
                    style: GoogleFonts.tajawal(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF003527),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...q.replies.asMap().entries.map((entry) {
                final index = entry.key;
                final reply = entry.value;
                final isLastUserInquiry =
                    reply.isFromUser && index == q.replies.length - 1 && isFollowUp;

                if (reply.isFromUser) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isLastUserInquiry
                          ? const Color(0xFFFFFBEB)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isLastUserInquiry
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFFDCE2F3),
                        width: isLastUserInquiry ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isLastUserInquiry
                                    ? const Color(0xFFFDE68A)
                                    : const Color(0xFFE2E8F8),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.help_outline_rounded,
                                size: 14,
                                color: isLastUserInquiry
                                    ? const Color(0xFFB45309)
                                    : const Color(0xFF404944),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isLastUserInquiry
                                  ? 'استفسار جديد من السائل ⏳'
                                  : 'استفسار من السائل (${reply.senderName})',
                              style: GoogleFonts.tajawal(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isLastUserInquiry
                                    ? const Color(0xFFB45309)
                                    : const Color(0xFF404944),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _formatDate(reply.createdAt),
                              style: GoogleFonts.tajawal(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          reply.message,
                          style: GoogleFonts.tajawal(
                            fontSize: 13,
                            color: const Color(0xFF151C27),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                size: 16, color: Color(0xFF16A34A)),
                            const SizedBox(width: 6),
                            Text(
                              'ردكم على الاستفسار',
                              style: GoogleFonts.tajawal(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF15803D),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _formatDate(reply.createdAt),
                              style: GoogleFonts.tajawal(
                                fontSize: 11,
                                color: const Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          reply.message,
                          style: GoogleFonts.tajawal(
                            fontSize: 13,
                            color: const Color(0xFF14532D),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                }
              }),
            ],

            const SizedBox(height: 16),

            // ── 4. Answer Compose Box ──────────────────────────────
            Text(
              isFollowUp
                  ? 'نص الرد على الاستفسار الإضافي'
                  : 'نص الإجابة والفتوى',
              style: GoogleFonts.tajawal(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF151C27),
              ),
            ),
            const SizedBox(height: 8),

            TextFormField(
              controller: _answerController,
              style: GoogleFonts.tajawal(fontSize: 15, height: 1.6),
              textDirection: TextDirection.rtl,
              maxLines: 8,
              maxLength: 4000,
              decoration: InputDecoration(
                hintText: isFollowUp
                    ? 'اكتب التوضيح والرد على استفسار المصلّي هنا...'
                    : 'اكتب الإجابة الشافية والموثقة هنا مع ذكر الأدلة عند الحاجة...',
                hintStyle: GoogleFonts.tajawal(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFDCE2F3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFDCE2F3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: Color(0xFF003527), width: 2),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              validator: (v) => (v == null || v.trim().length < 3)
                  ? 'يرجى كتابة إجابة واضحة'
                  : null,
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFC3ECD7).withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF003527).withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded,
                      color: Color(0xFF003527), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'سيتم إشعار السائل فور نشر الإجابة أو الرد في تطبيق صلاتي.',
                      style: GoogleFonts.tajawal(
                        fontSize: 12,
                        color: const Color(0xFF003527),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.of(context).padding.bottom + 12,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFDCE2F3))),
        ),
        child: ElevatedButton.icon(
          onPressed: _isPublishing ? null : _publishAnswer,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF003527),
            disabledBackgroundColor: Colors.grey,
            foregroundColor: Colors.white,
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          icon: _isPublishing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.send_rounded),
          label: Text(
            _isPublishing
                ? 'جارٍ النشر...'
                : (isFollowUp ? 'نشر الرد على الاستفسار' : 'نشر الإجابة'),
            style: GoogleFonts.tajawal(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
