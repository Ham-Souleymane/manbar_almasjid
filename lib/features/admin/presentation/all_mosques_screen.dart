import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../data/admin_repository.dart';
import '../../registration/domain/mosque_model.dart';

class AllMosquesScreen extends ConsumerStatefulWidget {
  const AllMosquesScreen({super.key});

  @override
  ConsumerState<AllMosquesScreen> createState() => _AllMosquesScreenState();
}

class _AllMosquesScreenState extends ConsumerState<AllMosquesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final mosquesAsync = ref.watch(allMosquesProvider);
    final l10n = context.l10n;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            decoration: InputDecoration(
              hintText: l10n.searchMosqueHint,
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
        Expanded(
          child: mosquesAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF0F766E))),
            error: (e, _) => Center(child: Text('${l10n.error}: $e')),
            data: (mosques) {
              final filtered = _query.isEmpty
                  ? mosques
                  : mosques
                      .where((m) =>
                          m.name.toLowerCase().contains(_query) ||
                          m.city.toLowerCase().contains(_query) ||
                          m.country.toLowerCase().contains(_query))
                      .toList();

              if (filtered.isEmpty) {
                return Center(
                    child: Text(l10n.noMatchingMosques,
                        style: const TextStyle(color: Colors.black45)));
              }
              return RefreshIndicator(
                color: const Color(0xFF0F766E),
                onRefresh: () async => ref.invalidate(allMosquesProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) =>
                      _MosqueCard(mosque: filtered[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MosqueCard extends ConsumerStatefulWidget {
  final MosqueModel mosque;
  const _MosqueCard({required this.mosque});

  @override
  ConsumerState<_MosqueCard> createState() => _MosqueCardState();
}

class _MosqueCardState extends ConsumerState<_MosqueCard> {
  bool _isLoading = false;

  void _showSnackBar(String msg, {Color color = const Color(0xFF0F766E)}) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<void> _deleteMosque() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.deleteMosqueConfirmTitle,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text(l10n.deleteMosqueConfirmBody(widget.mosque.name)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete,
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .deleteMosqueAsAdmin(widget.mosque.id);
      if (mounted) _showSnackBar(l10n.mosquePermanentlyDeleted);
    } catch (e) {
      if (mounted) _showSnackBar('${l10n.deleteMosque}: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mosque = widget.mosque;
    final l10n = context.l10n;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Mosque photo or icon
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: mosque.photo != null
                  ? Image.network(
                      mosque.photo!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderIcon(),
                    )
                  : _placeholderIcon(),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          mosque.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (mosque.verified)
                        const Icon(Icons.verified_rounded,
                            color: Color(0xFF0F766E), size: 18)
                      
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${mosque.city}، ${mosque.country}',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Actions (Delete / Loading)
            if (_isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF0F766E),
                ),
              )
            else
              IconButton(
                tooltip: l10n.deleteMosque,
                icon: const Icon(Icons.delete_forever_rounded,
                    color: Colors.red),
                onPressed: _deleteMosque,
              ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderIcon() {
    return Container(
      width: 56,
      height: 56,
      color: const Color(0xFFE5F3F1),
      child:
          const Icon(Icons.mosque_rounded, color: Color(0xFF0F766E), size: 28),
    );
  }
}
