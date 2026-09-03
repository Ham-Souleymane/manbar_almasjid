import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../admin/data/admin_repository.dart';
import '../../registration/data/registration_repository.dart';
import '../data/suggestion_model.dart';

Future<void> showSuggestToAdminSheet(BuildContext context, {int initialTab = 0}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => SuggestToAdminSheet(initialTab: initialTab),
  );
}

class SuggestToAdminSheet extends ConsumerStatefulWidget {
  final int initialTab;
  const SuggestToAdminSheet({super.key, this.initialTab = 0});

  @override
  ConsumerState<SuggestToAdminSheet> createState() =>
      _SuggestToAdminSheetState();
}

class _SuggestToAdminSheetState extends ConsumerState<SuggestToAdminSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  String _selectedType = 'اقتراح ميزة جديدة';
  bool _isSubmitting = false;

  final List<(String label, IconData icon)> _types = const [
    ('اقتراح ميزة جديدة', Icons.lightbulb_rounded),
    ('تعديل أو تحسين', Icons.auto_fix_high_rounded),
    ('طلب إضافة تصنيف', Icons.category_rounded),
    ('ملاحظة أو خلل فني', Icons.bug_report_rounded),
    ('أخرى', Icons.edit_note_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(firebaseAuthProvider).currentUser;
    final imam = ref.read(currentImamProvider).asData?.value;
    final mosque = ref.read(currentMosqueProvider).asData?.value;

    final senderId = imam?.id ?? user?.uid ?? '';
    final senderName = (imam?.fullName.isNotEmpty == true)
        ? imam!.fullName
        : (user?.displayName ?? 'إمام / داعية');
    final senderPhone = imam?.phone ?? user?.phoneNumber ?? '';

    setState(() => _isSubmitting = true);

    try {
      final suggestion = SuggestionModel(
        id: '',
        imamId: senderId,
        imamName: senderName,
        imamPhone: senderPhone,
        mosqueId: mosque?.id ?? '',
        mosqueName: mosque?.name ?? '',
        type: _selectedType,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await ref.read(adminRepositoryProvider).submitSuggestion(suggestion);

      if (!mounted) return;

      _titleController.clear();
      _contentController.clear();
      _tabController.animateTo(1); // Switch to My Suggestions tab

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'تم إرسال اقتراحك بنجاح! يمكنك متابعة حالته ورد الإدارة هنا.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0F766E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء إرسال الاقتراح: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

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
        return const Color(0xFFD97706);
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'in_progress':
        return 'قيد الدراسة والتنفيذ';
      case 'implemented':
        return 'تم التنفيذ بنجاح ✓';
      case 'rejected':
        return 'معتذر عنه';
      case 'pending':
      default:
        return 'قيد المراجعة ⏳';
    }
  }

  @override
  Widget build(BuildContext context) {
    final imam = ref.watch(currentImamProvider).asData?.value;
    final user = ref.watch(firebaseAuthProvider).currentUser;
    final senderId = imam?.id ?? user?.uid ?? '';
    final mySuggestionsAsync = ref.watch(mySuggestionsProvider(senderId));

    final count = mySuggestionsAsync.asData?.value.length ?? 0;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.tips_and_updates_rounded,
                    color: Color(0xFF0F766E),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'صندوق المقترحات والتطوير',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'صوتك مسموع، ساهم معنا في تطوير المنصة',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.black45),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Segmented Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xFF0F766E),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F766E).withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF4B5563),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  fontFamily: 'Tajawal',
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  fontFamily: 'Tajawal',
                ),
                dividerColor: Colors.transparent,
                tabs: [
                  const Tab(
                    icon: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_comment_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('تقديم اقتراح جديد'),
                      ],
                    ),
                  ),
                  Tab(
                    icon: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.history_rounded, size: 16),
                        const SizedBox(width: 6),
                        Text('اقتراحاتي السابقة ${count > 0 ? "($count)" : ""}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSubmitTab(context),
                _buildMySuggestionsTab(senderId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitTab(BuildContext context) {
    final imam = ref.watch(currentImamProvider).asData?.value;
    final mosque = ref.watch(currentMosqueProvider).asData?.value;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imam / Mosque Badge
            if (imam != null || mosque != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_circle_rounded,
                        size: 18, color: Color(0xFF0F766E)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'مُرسل الاقتراح: ${imam?.fullName ?? "إمام"} ${mosque != null ? "(${mosque.name})" : ""}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 14),

            // Suggestion Type Selector
            const Text(
              'نوع الاقتراح أو الطلب',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _types.map((t) {
                final isSelected = _selectedType == t.$1;
                return ChoiceChip(
                  avatar: Icon(
                    t.$2,
                    size: 16,
                    color: isSelected ? Colors.white : const Color(0xFF0F766E),
                  ),
                  label: Text(t.$1),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedType = t.$1);
                    }
                  },
                  selectedColor: const Color(0xFF0F766E),
                  backgroundColor: Colors.white,
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
                          : Colors.grey.shade300,
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Title field
            TextFormField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'عنوان الاقتراح أو الفكرة *',
                hintText: 'مثال: إضافة ميزة البث المباشر للدروس والمحاضرات',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: Color(0xFF0F766E), width: 1.5),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'يرجى إدخال عنوان الاقتراح';
                }
                if (v.trim().length < 3) {
                  return 'العنوان قصير جداً';
                }
                return null;
              },
            ),

            const SizedBox(height: 14),

            // Content / Details field
            TextFormField(
              controller: _contentController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'تفاصيل الاقتراح والشرح *',
                hintText:
                    'اشرح فكرتك أو التعديل الذي ترغب بوجوده في التطبيق بالتفصيل لمساعدة الإدارة...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: Color(0xFF0F766E), width: 1.5),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'يرجى كتابة تفاصيل الاقتراح';
                }
                if (v.trim().length < 8) {
                  return 'يرجى تقديم شرح أوضح للاقتراح';
                }
                return null;
              },
            ),

            const SizedBox(height: 12),

            // Helpful note / HCI reassurance
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: Color(0xFFD97706), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'تتم مراجعة المقترحات دورياً وتحديث حالتها مباشرة. ستتمكن من قراءة ردود الإدارة وملاحظاتها عبر تبويب "اقتراحاتي السابقة".',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF92400E),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Buttons
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('إلغاء'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      _isSubmitting ? 'جاري الإرسال...' : 'إرسال الاقتراح',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
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

  Widget _buildMySuggestionsTab(String senderId) {
    if (senderId.isEmpty) {
      return const Center(child: Text('يرجى تسجيل الدخول لعرض المقترحات'));
    }

    final mySuggestionsAsync = ref.watch(mySuggestionsProvider(senderId));

    return mySuggestionsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF0F766E)),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('تعذر تحميل الاقتراحات: $e'),
        ),
      ),
      data: (suggestions) {
        if (suggestions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 48,
                      color: Color(0xFF0F766E),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'لم تقم بتقديم أي اقتراحات بعد',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'شاركنا أفكارك وملاحظاتك وساهم في بناء منصة منبر المسجد',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    onPressed: () => _tabController.animateTo(0),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('تقديم أول اقتراح'),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: suggestions.length,
          itemBuilder: (context, i) {
            final s = suggestions[i];
            final statusColor = _getStatusColor(s.status);
            final formattedDate =
                DateFormat('yyyy/MM/dd - hh:mm a', 'ar').format(s.createdAt);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type & Status Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF0F766E).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          s.type,
                          style: const TextStyle(
                            color: Color(0xFF0F766E),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
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
                  const SizedBox(height: 10),

                  // Title
                  Text(
                    s.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Content
                  Text(
                    s.content,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4B5563),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Date
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black45,
                    ),
                  ),

                  // Admin Reply if present
                  if (s.adminResponse != null &&
                      s.adminResponse!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.admin_panel_settings_rounded,
                                size: 16,
                                color: Color(0xFF065F46),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'رد إدارة التطبيق:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF065F46),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.adminResponse!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF064E3B),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
