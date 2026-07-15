import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/admin_repository.dart';
import '../data/report_model.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(reportsProvider);

    return reportsAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: Color(0xFF0F766E))),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (reports) {
        if (reports.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_rounded, size: 64, color: Colors.green.shade400),
                const SizedBox(height: 12),
                const Text(
                  'لا توجد بلاغات مفتوحة',
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          color: const Color(0xFF0F766E),
          onRefresh: () async => ref.invalidate(reportsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: reports.length,
            itemBuilder: (context, i) => _ReportCard(report: reports[i]),
          ),
        );
      },
    );
  }
}

class _ReportCard extends ConsumerStatefulWidget {
  final ReportModel report;
  const _ReportCard({required this.report});

  @override
  ConsumerState<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends ConsumerState<_ReportCard> {
  bool _isLoading = false;

  void _showSnackBar(String msg, {Color color = const Color(0xFF0F766E)}) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<void> _deleteContent() async {
    final confirmed = await _confirm(
      context,
      title: 'حذف المحتوى',
      message:
          'هل تريد حذف هذا المحتوى نهائياً؟ لا يمكن التراجع عن هذا الإجراء.',
      confirmLabel: 'حذف',
      confirmColor: Colors.red,
    );
    if (confirmed != true) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(adminRepositoryProvider).deleteReportedContent(widget.report);
      _showSnackBar('تم حذف المحتوى بنجاح');
    } catch (e) {
      _showSnackBar('فشل حذف المحتوى: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _dismiss() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(adminRepositoryProvider).dismissReport(widget.report.id);
      _showSnackBar('تم تجاهل البلاغ');
    } catch (e) {
      _showSnackBar('فشل التجاهل: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final isReviewed = report.status == 'reviewed';
    final dateStr = DateFormat('dd/MM/yyyy – HH:mm').format(report.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: report.type == 'post'
                        ? Colors.blue.withValues(alpha: 0.12)
                        : Colors.purple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    report.type == 'post' ? 'منشور' : 'تعليق',
                    style: TextStyle(
                      color: report.type == 'post' ? Colors.blue : Colors.purple,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(dateStr,
                      style: const TextStyle(
                          color: Colors.black45, fontSize: 11)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isReviewed
                        ? Colors.green.withValues(alpha: 0.12)
                        : Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isReviewed ? 'تمت المراجعة' : 'مفتوح',
                    style: TextStyle(
                      color: isReviewed ? Colors.green : Colors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Reason
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.flag_rounded,
                    color: Colors.orange, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'السبب: ${report.reason}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Reported content snapshot
            if (report.snapshot.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  report.snapshot,
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      fontStyle: FontStyle.italic),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 6),
            ],

            Text(
              'أُبلغ بواسطة: ${report.reportedBy}',
              style: const TextStyle(fontSize: 11, color: Colors.black45),
            ),

            const SizedBox(height: 14),

            // Actions
            if (!isReviewed)
              if (_isLoading)
                const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF0F766E)))
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _dismiss,
                        icon: const Icon(Icons.visibility_off_rounded,
                            size: 16, color: Colors.grey),
                        label: const Text('تجاهل',
                            style: TextStyle(color: Colors.grey)),
                        style: OutlinedButton.styleFrom(
                          side:
                              const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _deleteContent,
                        icon: const Icon(Icons.delete_forever_rounded,
                            size: 16, color: Colors.white),
                        label: const Text('حذف المحتوى',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }
}

Future<bool?> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  Color confirmColor = const Color(0xFF0F766E),
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => Directionality(
      textDirection: ui.TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title:
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel,
                style: TextStyle(
                    color: confirmColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ),
  );
}
