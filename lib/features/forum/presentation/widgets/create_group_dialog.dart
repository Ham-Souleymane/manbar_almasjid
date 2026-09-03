import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../application/forum_providers.dart';
import '../../domain/imam_group_model.dart';

class CreateOrEditGroupDialog extends ConsumerStatefulWidget {
  const CreateOrEditGroupDialog({
    super.key,
    this.existingGroup,
    required this.adminId,
  });

  final ImamGroupModel? existingGroup;
  final String adminId;

  @override
  ConsumerState<CreateOrEditGroupDialog> createState() =>
      _CreateOrEditGroupDialogState();
}

class _CreateOrEditGroupDialogState
    extends ConsumerState<CreateOrEditGroupDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _nameEnController;
  late final TextEditingController _descController;
  late final TextEditingController _rulesController;

  String _selectedCategory = 'الفقه';
  String _selectedIcon = 'menu_book';
  String _selectedColor = 'emerald';
  bool _isPrivate = false;
  bool _isLoading = false;

  static const List<String> _categories = [
    'الفقه',
    'الحديث الشريف',
    'قضايا معاصرة',
    'إدارة المساجد',
    'القرآن والتجويد',
    'الخطابة والدعوة',
    'العقيدة وأصول الدين',
    'الاستشارات الأسرية',
    'عام',
  ];

  static const List<Map<String, dynamic>> _iconOptions = [
    {'name': 'menu_book', 'icon': Icons.menu_book_rounded, 'label': 'كتاب'},
    {'name': 'library_books', 'icon': Icons.library_books_rounded, 'label': 'مكتبة'},
    {'name': 'public', 'icon': Icons.public_rounded, 'label': 'عالمي'},
    {'name': 'mosque', 'icon': Icons.mosque_rounded, 'label': 'مسجد'},
    {'name': 'auto_stories', 'icon': Icons.auto_stories_rounded, 'label': 'قرآن'},
    {'name': 'record_voice_over', 'icon': Icons.record_voice_over_rounded, 'label': 'خطابة'},
    {'name': 'school', 'icon': Icons.school_rounded, 'label': 'تعليم'},
    {'name': 'psychology', 'icon': Icons.psychology_rounded, 'label': 'فكر'},
  ];

  static const List<Map<String, dynamic>> _colorOptions = [
    {'key': 'emerald', 'color': Color(0xFF064E3B), 'bg': Color(0xFFC3ECD7), 'label': 'زمردي'},
    {'key': 'amber', 'color': Color(0xFF623C00), 'bg': Color(0xFFFFDDB8), 'label': 'كهرماني'},
    {'key': 'teal', 'color': Color(0xFF2B6954), 'bg': Color(0xFFD4EFE5), 'label': 'تركواز'},
    {'key': 'green', 'color': Color(0xFF1E5B3A), 'bg': Color(0xFFC8F2DD), 'label': 'أخضر'},
    {'key': 'gold', 'color': Color(0xFFB7922E), 'bg': Color(0xFFFEF3C7), 'label': 'ذهبي'},
    {'key': 'purple', 'color': Color(0xFF581C87), 'bg': Color(0xFFF3E8FF), 'label': 'بنفسجي'},
  ];

  @override
  void initState() {
    super.initState();
    final g = widget.existingGroup;
    _nameController = TextEditingController(text: g?.name ?? '');
    _nameEnController = TextEditingController(text: g?.nameEn ?? '');
    _descController = TextEditingController(text: g?.description ?? '');
    _rulesController = TextEditingController(text: g?.rules.join('\n') ?? '');

    if (g != null) {
      _selectedCategory = g.category;
      _selectedIcon = g.iconName;
      _selectedColor = g.colorKey;
      _isPrivate = g.isPrivate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameEnController.dispose();
    _descController.dispose();
    _rulesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final rulesList = _rulesController.text
        .split('\n')
        .map((r) => r.trim())
        .where((r) => r.isNotEmpty)
        .toList();

    final isEdit = widget.existingGroup != null;
    final group = ImamGroupModel(
      id: widget.existingGroup?.id ?? '',
      name: _nameController.text.trim(),
      nameEn: _nameEnController.text.trim(),
      category: _selectedCategory,
      description: _descController.text.trim(),
      iconName: _selectedIcon,
      colorKey: _selectedColor,
      membersCount: widget.existingGroup?.membersCount ?? 0,
      memberIds: widget.existingGroup?.memberIds ?? [],
      createdBy: widget.adminId,
      createdAt: widget.existingGroup?.createdAt ?? DateTime.now(),
      isPrivate: _isPrivate,
      rules: rulesList,
    );

    bool success;
    if (isEdit) {
      success = await ref.read(forumControllerProvider.notifier).updateGroup(group);
    } else {
      success = await ref.read(forumControllerProvider.notifier).createGroup(group);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit ? 'تم تحديث المجموعة بنجاح' : 'تم إنشاء المجموعة بنجاح',
            ),
            backgroundColor: AppColors.emerald,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء حفظ المجموعة'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEdit = widget.existingGroup != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldPale,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.group_add_rounded,
                        color: AppColors.emeraldDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEdit ? 'تعديل ملتقى الأئمة' : 'إنشاء مجموعة جديدة للأئمة',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.emeraldDark,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Name Arabic
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'اسم المجموعة (بالعربية)',
                    hintText: 'مثال: ملتقى الفقه المقارن',
                    prefixIcon: const Icon(Icons.title_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'يرجى إدخال اسم المجموعة' : null,
                ),
                const SizedBox(height: 12),

                // Name English (Optional)
                TextFormField(
                  controller: _nameEnController,
                  decoration: InputDecoration(
                    labelText: 'الاسم الإنجليزي (اختياري)',
                    hintText: 'e.g. Comparative Fiqh Forum',
                    prefixIcon: const Icon(Icons.translate_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                // Category
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'التخصص الشرعي',
                    prefixIcon: const Icon(Icons.category_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _categories.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
                const SizedBox(height: 12),

                // Description
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'وصف المجموعة ومجال النقاش',
                    hintText: 'أدخل نبذة عن أهداف الملتقى والمواضيع المطروحة...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'يرجى إدخال وصف للمجموعة' : null,
                ),
                const SizedBox(height: 16),

                // Icon Selection
                const Text(
                  'أيقونة المجموعة:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _iconOptions.map((item) {
                    final selected = _selectedIcon == item['name'];
                    return InkWell(
                      onTap: () => setState(() => _selectedIcon = item['name']),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.emeraldDark : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected ? AppColors.emeraldDark : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item['icon'] as IconData,
                              size: 18,
                              color: selected ? Colors.white : AppColors.grey700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item['label'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                color: selected ? Colors.white : AppColors.grey700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Color Theme Selection
                const Text(
                  'السمة اللونية:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: _colorOptions.map((item) {
                    final selected = _selectedColor == item['key'];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = item['key']),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: item['bg'] as Color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? AppColors.charcoal : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: item['color'] as Color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Rules
                TextFormField(
                  controller: _rulesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'ضوابط وآداب المجموعة (سطر لكل قاعدة)',
                    hintText: 'مثال:\nالالتزام بالأدب العلمي\nعزو الأقوال إلى مصادرها',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                // Private / Request Toggle
                SwitchListTile(
                  title: const Text('مجموعة تتطلب موافقة للانضمام'),
                  subtitle: const Text('يظهر للمستخدمين زر "طلب انضمام" بدل الانضمام الفوري'),
                  value: _isPrivate,
                  activeThumbColor: AppColors.emerald,
                  onChanged: (val) => setState(() => _isPrivate = val),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(l10n.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                isEdit ? l10n.save : 'إنشاء المجموعة',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
