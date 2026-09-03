import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../suggestions/data/suggestion_model.dart';
import '../data/admin_repository.dart';

class SuggestionsScreen extends ConsumerStatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  ConsumerState<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends ConsumerState<SuggestionsScreen> {
  String? _selectedFilter; // null = all, or 'pending', 'in_progress', 'implemented', 'rejected'

  final List<(String? key, String label, IconData icon)> _filters = const [
    (null, 'الكل', Icons.all_inclusive_rounded),
    ('pending', 'قيد المراجعة', Icons.hourglass_top_rounded),
    ('in_progress', 'قيد الدراسة', Icons.engineering_rounded),
    ('implemented', 'تم التنفيذ', Icons.check_circle_rounded),
    ('rejected', 'مرفوض', Icons.cancel_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final suggestionsAsync = ref.watch(suggestionsProvider(_selectedFilter));

    return Column(
      children: [
        // Filter bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((f) {
                final isSelected = _selectedFilter == f.$1;
                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: FilterChip(
                    avatar: Icon(
                      f.$3,
                      size: 16,
                      color: isSelected ? Colors.white : const Color(0xFF0F766E),
                    ),
                    label: Text(f.$2),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedFilter = f.$1);
                    },
                    selectedColor: const Color(0xFF0F766E),
                    backgroundColor: const Color(0xFFF4F6F8),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : const Color(0xFF374151),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF0F766E)
                            : Colors.transparent,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // List
        Expanded(
          child: suggestionsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Color(0xFF0F766E)),
            ),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('خطأ في تحميل الاقتراحات: $e'),
              ),
            ),
            data: (suggestions) {
              if (suggestions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _selectedFilter == null
                            ? 'لا توجد اقتراحات أو طلبات من الأئمة حتى الآن'
                            : 'لا توجد عناصر في هذه الفئة',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: const Color(0xFF0F766E),
                onRefresh: () async =>
                    ref.invalidate(suggestionsProvider(_selectedFilter)),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: suggestions.length,
                  itemBuilder: (context, i) =>
                      _SuggestionCard(suggestion: suggestions[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SuggestionCard extends ConsumerStatefulWidget {
  final SuggestionModel suggestion;
  const _SuggestionCard({required this.suggestion});

  @override
  ConsumerState<_SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends ConsumerState<_SuggestionCard> {
  bool _isLoading = false;

  Color _getStatusColor(String status) {
    switch (status) {
      case 'in_progress':
        return Colors.blue.shade700;
      case 'implemented':
        return const Color(0xFF0F766E);
      case 'rejected':
        return Colors.red.shade600;
      case 'pending':
      default:
        return Colors.orange.shade800;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'in_progress':
        return 'قيد الدراسة والتنفيذ';
      case 'implemented':
        return 'تم التنفيذ';
      case 'rejected':
        return 'مرفوض';
      case 'pending':
      default:
        return 'قيد المراجعة';
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isLoading = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .updateSuggestionStatus(widget.suggestion.id, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تحديث حالة الاقتراح إلى ${_getStatusLabel(newStatus)}'),
            backgroundColor: const Color(0xFF0F766E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addAdminReply() async {
    final controller =
        TextEditingController(text: widget.suggestion.adminResponse ?? '');

    final reply = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('الرد على الاقتراح'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'اكتب ملاحظة أو رد الإدارة ليتم توثيقه:',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'ملاحظات الإدارة...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('حفظ الرد'),
          ),
        ],
      ),
    );

    if (reply == null) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(adminRepositoryProvider).updateSuggestionStatus(
            widget.suggestion.id,
            widget.suggestion.status,
            adminResponse: reply,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ رد الإدارة بنجاح'),
            backgroundColor: Color(0xFF0F766E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSuggestion() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الاقتراح'),
        content: const Text('هل أنت متأكد من حذف هذا الاقتراح نهائياً؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .deleteSuggestion(widget.suggestion.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف الاقتراح'),
            backgroundColor: Color(0xFF0F766E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.suggestion;
    final formattedDate =
        DateFormat('yyyy/MM/dd - hh:mm a', 'ar').format(s.createdAt);

    final statusColor = _getStatusColor(s.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                // Type badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lightbulb_rounded,
                          size: 14, color: Color(0xFF0F766E)),
                      const SizedBox(width: 4),
                      Text(
                        s.type,
                        style: const TextStyle(
                          color: Color(0xFF0F766E),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getStatusLabel(s.status),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Submitter Info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.1),
                      child: const Icon(Icons.person_rounded,
                          size: 18, color: Color(0xFF0F766E)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.imamName.isNotEmpty
                                ? s.imamName
                                : 'إمام / داعية',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF111827),
                            ),
                          ),
                          if (s.mosqueName.isNotEmpty)
                            Text(
                              s.mosqueName,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.black54),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.black45),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Title
                Text(
                  s.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),

                // Content
                Text(
                  s.content,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF374151),
                  ),
                ),

                // Admin Response if present
                if (s.adminResponse != null && s.adminResponse!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.admin_panel_settings_rounded,
                                size: 14, color: Color(0xFF0F766E)),
                            SizedBox(width: 6),
                            Text(
                              'رد الإدارة:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Color(0xFF0F766E),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.adminResponse!,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF4B5563)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1),

          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Change status menu
                PopupMenuButton<String>(
                  enabled: !_isLoading,
                  icon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.tune_rounded,
                          size: 16, color: Color(0xFF0F766E)),
                      const SizedBox(width: 4),
                      const Text(
                        'تغيير الحالة',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                    ],
                  ),
                  onSelected: _updateStatus,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'pending',
                      child: Text('قيد المراجعة'),
                    ),
                    const PopupMenuItem(
                      value: 'in_progress',
                      child: Text('قيد الدراسة والتنفيذ'),
                    ),
                    const PopupMenuItem(
                      value: 'implemented',
                      child: Text('تم التنفيذ ✓'),
                    ),
                    const PopupMenuItem(
                      value: 'rejected',
                      child: Text('مرفوض ✗'),
                    ),
                  ],
                ),

                const Spacer(),

                // Add Reply button
                TextButton.icon(
                  onPressed: _isLoading ? null : _addAdminReply,
                  icon: const Icon(Icons.reply_rounded, size: 16),
                  label: Text(
                    s.adminResponse == null ? 'إضافة رد' : 'تعديل الرد',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),

                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 18, color: Colors.red),
                  onPressed: _isLoading ? null : _deleteSuggestion,
                  tooltip: 'حذف',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
