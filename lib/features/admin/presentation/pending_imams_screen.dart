import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_localizations.dart';
import '../data/admin_repository.dart';
import '../../registration/domain/imam_model.dart';
import '../../registration/domain/imam_status.dart';

class PendingImamsScreen extends ConsumerStatefulWidget {
  const PendingImamsScreen({super.key});

  @override
  ConsumerState<PendingImamsScreen> createState() => _PendingImamsScreenState();
}

class _PendingImamsScreenState extends ConsumerState<PendingImamsScreen> {
  String _query = '';
  String _selectedStatus = 'الكل'; // 'الكل', 'pending', 'verified', 'blocked', 'rejected'

  @override
  Widget build(BuildContext context) {
    final imamsAsync = ref.watch(allImamsProvider);
    final l10n = context.l10n;

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            decoration: InputDecoration(
              hintText: l10n.searchImamHint,
              prefixIcon: const Icon(Icons.search_rounded,
                  color: Color(0xFF0F766E)),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          ),
        ),
        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _buildFilterChip(l10n.allCategories, 'الكل'),
              const SizedBox(width: 8),
              _buildFilterChip(l10n.statusPending, 'pending'),
              const SizedBox(width: 8),
              _buildFilterChip(l10n.statusVerified, 'verified'),
              const SizedBox(width: 8),
              _buildFilterChip(l10n.statusBlocked, 'blocked'),
              const SizedBox(width: 8),
              _buildFilterChip(l10n.statusRejected, 'rejected'),
            ],
          ),
        ),
        Expanded(
          child: imamsAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator(color: Color(0xFF0F766E))),
            error: (e, _) => Center(child: Text('${l10n.error}: $e')),
            data: (imams) {
              final filtered = imams.where((imam) {
                // Search query matching
                final matchQuery = _query.isEmpty ||
                    imam.fullName.toLowerCase().contains(_query) ||
                    imam.email.toLowerCase().contains(_query) ||
                    imam.phone.toLowerCase().contains(_query);

                // Status filter matching
                final matchStatus = _selectedStatus == 'الكل' ||
                    imam.status.value == _selectedStatus;

                return matchQuery && matchStatus;
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Text(
                    l10n.noMatchingImams,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                );
              }
              return RefreshIndicator(
                color: const Color(0xFF0F766E),
                onRefresh: () async => ref.invalidate(allImamsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => _ImamCard(imam: filtered[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedStatus == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedStatus = value);
        }
      },
      selectedColor: const Color(0xFF0F766E),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFF0F766E) : Colors.grey.shade300,
        ),
      ),
      showCheckmark: false,
    );
  }
}

class _ImamCard extends ConsumerStatefulWidget {
  final ImamModel imam;
  const _ImamCard({required this.imam});

  @override
  ConsumerState<_ImamCard> createState() => _ImamCardState();
}

class _ImamCardState extends ConsumerState<_ImamCard> {
  bool _isLoading = false;

  void _showSnackBar(String msg, {Color color = const Color(0xFF0F766E)}) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<void> _approve() async {
    final l10n = context.l10n;
    final confirmed = await _confirm(
      context,
      title: l10n.approveImam,
      message: l10n.approveImamConfirm(widget.imam.fullName),
      confirmLabel: l10n.approve,
      confirmColor: Colors.green,
    );
    if (confirmed != true) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .approveImam(widget.imam.id, widget.imam.mosqueId);
      if (mounted) _showSnackBar(l10n.imamApproved);
    } catch (e) {
      if (mounted) _showSnackBar('${l10n.approveFailed}: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _reject() async {
    final l10n = context.l10n;
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.rejectImamTitle(widget.imam.fullName),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.rejectReasonOptional),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: l10n.rejectReasonHint,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.reject,
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(adminRepositoryProvider).rejectImam(
            widget.imam.id,
            reason: reasonController.text.trim(),
          );
      if (mounted) _showSnackBar(l10n.imamRejected);
    } catch (e) {
      if (mounted) _showSnackBar('${l10n.rejectFailed}: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _block() async {
    final l10n = context.l10n;
    final confirmed = await _confirm(
      context,
      title: l10n.blockImam,
      message: l10n.blockImamConfirm(widget.imam.fullName),
      confirmLabel: l10n.block,
      confirmColor: Colors.red,
    );
    if (confirmed != true) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(adminRepositoryProvider).blockImam(widget.imam.id);
      if (mounted) _showSnackBar(l10n.imamBlocked);
    } catch (e) {
      if (mounted) _showSnackBar('${l10n.blockFailed}: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _unblock() async {
    final l10n = context.l10n;
    final confirmed = await _confirm(
      context,
      title: l10n.unblockImam,
      message: l10n.unblockImamConfirm(widget.imam.fullName),
      confirmLabel: l10n.unblock,
      confirmColor: Colors.green,
    );
    if (confirmed != true) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(adminRepositoryProvider).unblockImam(widget.imam.id);
      if (mounted) _showSnackBar(l10n.imamUnblocked);
    } catch (e) {
      if (mounted) _showSnackBar('${l10n.unblockFailed}: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final confirmed = await _confirm(
      context,
      title: l10n.deleteImam,
      message: l10n.deleteImamConfirm(widget.imam.fullName),
      confirmLabel: l10n.delete,
      confirmColor: Colors.red,
    );
    if (confirmed != true) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(adminRepositoryProvider).deleteImam(widget.imam.id);
      if (mounted) _showSnackBar(l10n.imamDeleted);
    } catch (e) {
      if (mounted) _showSnackBar('${l10n.deleteFailed}: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imam = widget.imam;
    final l10n = context.l10n;
    final dateStr = DateFormat('dd/MM/yyyy').format(imam.createdAt);

    Color statusColor;
    String statusText;
    switch (imam.status) {
      case ImamStatus.verified:
        statusColor = const Color(0xFF0F766E);
        statusText = l10n.statusVerified;
        break;
      case ImamStatus.pending:
        statusColor = Colors.orange;
        statusText = l10n.statusPending;
        break;
      case ImamStatus.blocked:
        statusColor = Colors.red;
        statusText = l10n.statusBlocked;
        break;
      case ImamStatus.rejected:
        statusColor = Colors.grey;
        statusText = l10n.statusRejected;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + Name + Status Badge
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFFE5F3F1),
                  backgroundImage: imam.photo != null
                      ? NetworkImage(imam.photo!)
                      : null,
                  child: imam.photo == null
                      ? const Icon(Icons.person_rounded,
                          color: Color(0xFF0F766E))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        imam.fullName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(imam.email,
                          style: const TextStyle(
                              color: Colors.black45, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            // Details
            _InfoRow(icon: Icons.phone_rounded, text: imam.phone),
            const SizedBox(height: 6),
            _InfoRow(
                icon: Icons.calendar_today_rounded,
                text: '${l10n.registrationDate}: $dateStr'),
            if (imam.mosqueId != null && imam.mosqueId!.isNotEmpty) ...[
              const SizedBox(height: 6),
              _InfoRow(
                  icon: Icons.mosque_rounded,
                  text: '${l10n.mosqueIdLabel}: ${imam.mosqueId}'),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            // Action buttons
            if (_isLoading)
              const Center(
                  child: CircularProgressIndicator(color: Color(0xFF0F766E)))
            else
              Row(
                children: [
                  IconButton(
                    tooltip: l10n.delete,
                    icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                    onPressed: _delete,
                  ),
                  const SizedBox(width: 8),
                  if (imam.isPending) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _reject,
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.red, size: 18),
                        label: Text(l10n.reject,
                            style: const TextStyle(
                                color: Colors.red, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _approve,
                        icon: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 18),
                        label: Text(l10n.approve,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ] else if (imam.isVerified) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _block,
                        icon: const Icon(Icons.block_rounded,
                            color: Colors.red, size: 18),
                        label: Text(l10n.blockAccount,
                            style: const TextStyle(
                                color: Colors.red, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ] else if (imam.isBlocked) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _unblock,
                        icon: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 18),
                        label: Text(l10n.activateAccount,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ] else if (imam.isRejected) ...[
                    const Spacer(),
                    Text(l10n.previouslyRejected,
                        style: const TextStyle(color: Colors.black38, fontSize: 13)),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF0F766E)),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis)),
      ],
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
  final l10n = context.l10n;
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title:
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel)),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel,
              style: TextStyle(
                  color: confirmColor, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}
