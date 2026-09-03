import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../registration/data/registration_repository.dart';
import '../data/questions_repository.dart';
import '../domain/islamic_field.dart';
import '../domain/question_model.dart';
import 'answer_question_screen.dart';

class IncomingQuestionsScreen extends ConsumerStatefulWidget {
  final String? imamId;
  final String? mosqueId;

  const IncomingQuestionsScreen({
    super.key,
    this.imamId,
    this.mosqueId,
  });

  @override
  ConsumerState<IncomingQuestionsScreen> createState() =>
      _IncomingQuestionsScreenState();
}

class _IncomingQuestionsScreenState
    extends ConsumerState<IncomingQuestionsScreen> {
  String? _selectedField;

  static const _filterFields = [
    {'id': 'all', 'label': 'الكل'},
    {'id': 'fiqh', 'label': 'الفقه'},
    {'id': 'aqeedah', 'label': 'العقيدة'},
    {'id': 'tafsir', 'label': 'التفسير'},
    {'id': 'history', 'label': 'السيرة'},
    {'id': 'muamalat', 'label': 'المعاملات'},
    {'id': 'hadith', 'label': 'علم الحديث'},
    {'id': 'usul', 'label': 'أصول الفقه'},
    {'id': 'language', 'label': 'اللغة'},
  ];

  @override
  Widget build(BuildContext context) {
    final currentImamAsync = ref.watch(currentImamProvider);
    final imam = currentImamAsync.asData?.value;

    final resolvedImamId = (widget.imamId != null && widget.imamId!.isNotEmpty)
        ? widget.imamId!
        : (imam?.id ?? '');

    final questionsAsync = (widget.imamId != null && widget.imamId!.isNotEmpty)
        ? ref.watch(imamQuestionsStreamProvider(resolvedImamId))
        : ref.watch(currentImamQuestionsStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF003527),
        iconTheme: const IconThemeData(color: Color(0xFF003527)),
        elevation: 0.5,
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Color(0xFF003527),
                  size: 20,
                ),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF064E3B),
              ),
              child: ClipOval(
                child: (imam?.photo != null && imam!.photo!.isNotEmpty)
                    ? Image.network(
                        imam.photo!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      )
                    : const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'منبر - الأسئلة الواردة',
              style: GoogleFonts.tajawal(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF003527),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF404944)),
            onPressed: () {
              ref.invalidate(currentImamQuestionsStreamProvider);
              if (resolvedImamId.isNotEmpty) {
                ref.invalidate(imamQuestionsStreamProvider(resolvedImamId));
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF003527),
        onRefresh: () async {
          ref.invalidate(currentImamQuestionsStreamProvider);
          if (resolvedImamId.isNotEmpty) {
            ref.invalidate(imamQuestionsStreamProvider(resolvedImamId));
          }
          await Future.delayed(const Duration(milliseconds: 300));
        },
        child: Column(
          children: [
            if (imam != null && !imam.acceptingQuestions)
              Container(
                color: const Color(0xFFFEF3C7),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: Color(0xFFD97706), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'استقبال الأسئلة موقوف حالياً من الإعدادات.',
                        style: GoogleFonts.tajawal(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final batch = FirebaseFirestore.instance.batch();
                        batch.update(
                          FirebaseFirestore.instance
                              .collection('imams')
                              .doc(imam.id),
                          {'acceptingQuestions': true},
                        );
                        if (imam.mosqueId != null &&
                            imam.mosqueId!.isNotEmpty) {
                          batch.update(
                            FirebaseFirestore.instance
                                .collection('mosques')
                                .doc(imam.mosqueId!),
                            {'acceptingQuestions': true},
                          );
                        }
                        await batch.commit();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFB45309),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'تفعيل الآن',
                        style: GoogleFonts.tajawal(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Horizontal Categories Filter Row ────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _filterFields.map((cat) {
                    final id = cat['id']!;
                    final label = cat['label']!;
                    final isSelected =
                        (_selectedField == null && id == 'all') ||
                            (_selectedField == id);

                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedField = id == 'all' ? null : id;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF003527)
                                : const Color(0xFFE2E8F8),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            label,
                            style: GoogleFonts.tajawal(
                              fontSize: 13,
                              fontWeight: isSelected
                                 ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF404944),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // ── Questions Feed ──────────────────────────────────────
            Expanded(
              child: questionsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF003527)),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: Colors.red, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'حدث خطأ في تحميل الأسئلة',
                          style: GoogleFonts.tajawal(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF151C27),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$e',
                          style: GoogleFonts.tajawal(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            ref.invalidate(currentImamQuestionsStreamProvider);
                            if (resolvedImamId.isNotEmpty) {
                              ref.invalidate(
                                  imamQuestionsStreamProvider(resolvedImamId));
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF003527),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: Text(
                            'إعادة المحاولة',
                            style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (questions) {
                  final filtered = (_selectedField == null || _selectedField == 'all')
                      ? questions
                      : questions
                          .where((q) => IslamicField.matches(q.field, _selectedField))
                          .toList();

                  final answeredCount =
                      questions.where((q) => q.isAnswered).length;

                  if (filtered.isEmpty) {
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        _WeeklyStatsCard(answeredCount: answeredCount),
                        const SizedBox(height: 32),
                        _EmptyIncomingState(selectedField: _selectedField),
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: filtered.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _WeeklyStatsCard(answeredCount: answeredCount);
                      }

                      final q = filtered[index - 1];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _MinbarQuestionCard(
                          question: q,
                          onAnswerTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AnswerQuestionScreen(
                                  question: q,
                                  imamId: resolvedImamId,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Weekly Stats Card
// ─────────────────────────────────────────────────────────────────────────────

class _WeeklyStatsCard extends StatelessWidget {
  final int answeredCount;

  const _WeeklyStatsCard({required this.answeredCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFC3ECD7),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.task_alt_rounded,
              color: Color(0xFF003527),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$answeredCount سؤالاً مُجاباً',
                  style: GoogleFonts.tajawal(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF003527),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'هذا الأسبوع. بارك الله في علمكم ووقتكم.',
                  style: GoogleFonts.tajawal(
                    fontSize: 13,
                    color: const Color(0xFF404944),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Question Card matching the HTML template
// ─────────────────────────────────────────────────────────────────────────────

class _MinbarQuestionCard extends StatelessWidget {
  final QuestionModel question;
  final VoidCallback onAnswerTap;

  const _MinbarQuestionCard({
    required this.question,
    required this.onAnswerTap,
  });

  String _formatRelativeDate(DateTime dt) {
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

  @override
  Widget build(BuildContext context) {
    final field = IslamicField.fromId(question.field);
    final isAnswered = question.isAnswered;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFC9C3), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Right side color bar indicator
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: 5,
              child: Container(
                color: question.isFollowUpPending
                    ? const Color(0xFFF59E0B)
                    : (isAnswered
                        ? const Color(0xFFDCE2F3)
                        : const Color(0xFF003527)),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Status badge + Field tag + Date
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: question.isFollowUpPending
                              ? const Color(0xFFFEF3C7)
                              : (isAnswered
                                  ? const Color(0xFFDCE2F3)
                                  : const Color(0xFF003527)),
                          borderRadius: BorderRadius.circular(9999),
                          border: question.isFollowUpPending
                              ? Border.all(color: const Color(0xFFF59E0B))
                              : null,
                        ),
                        child: Text(
                          question.isFollowUpPending
                              ? 'استفسار إضافي 💬'
                              : (isAnswered ? 'تمت الإجابة' : 'سؤال جديد'),
                          style: GoogleFonts.tajawal(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: question.isFollowUpPending
                                ? const Color(0xFFB45309)
                                : (isAnswered
                                    ? const Color(0xFF404944)
                                    : Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE7EEFE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          field != null
                              ? '${field.icon} ${field.labelAr}'
                              : IslamicField.labelForId(question.field,
                                  isArabic: true),
                          style: GoogleFonts.tajawal(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF404944),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatRelativeDate(
                          question.lastActivityAt ?? question.createdAt,
                        ),
                        style: GoogleFonts.tajawal(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Question Title
                  Text(
                    question.title,
                    style: GoogleFonts.tajawal(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF151C27),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 6),

                  // Question Body or Follow-Up snippet
                  if (question.isFollowUpPending &&
                      question.latestUserInquiry != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.help_outline_rounded,
                              size: 16, color: Color(0xFFB45309)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'استفسار المصلّي: ${question.latestUserInquiry!.message}',
                              style: GoogleFonts.tajawal(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF78350F),
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Text(
                      question.body,
                      style: GoogleFonts.tajawal(
                        fontSize: 13,
                        color: const Color(0xFF404944),
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 14),

                  const Divider(color: Color(0xFFBFC9C3), height: 1),

                  const SizedBox(height: 12),

                  // Footer: Asker avatar/name + Action button
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDCE2F3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          question.isAnonymous
                              ? Icons.visibility_off_rounded
                              : Icons.person_rounded,
                          size: 16,
                          color: const Color(0xFF404944),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          question.isAnonymous
                              ? 'مجهول'
                              : (question.userDisplayName.isNotEmpty
                                  ? question.userDisplayName
                                  : 'مُصلٍّ'),
                          style: GoogleFonts.tajawal(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF404944),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: onAnswerTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: question.isFollowUpPending
                              ? const Color(0xFFB45309)
                              : const Color(0xFF003527),
                          foregroundColor: Colors.white,
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: Icon(
                          question.isFollowUpPending
                              ? Icons.reply_rounded
                              : Icons.edit_document,
                          size: 16,
                        ),
                        label: Text(
                          question.isFollowUpPending
                              ? 'رد على الاستفسار'
                              : (isAnswered ? 'عرض الإجابة والردود' : 'أجب الآن'),
                          style: GoogleFonts.tajawal(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyIncomingState extends StatelessWidget {
  final String? selectedField;

  const _EmptyIncomingState({this.selectedField});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.inbox_outlined,
            size: 56,
            color: Color(0xFFBFC9C3),
          ),
          const SizedBox(height: 12),
          Text(
            'لا توجد أسئلة واردة حالياً',
            style: GoogleFonts.tajawal(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF404944),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ستظهر هنا الأسئلة الموجهة إليكم من المصلين عبر تطبيق صلاتي.',
            style: GoogleFonts.tajawal(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

