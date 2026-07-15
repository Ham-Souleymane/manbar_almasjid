import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_localizations.dart';
import '../data/admin_repository.dart';
import '../../posts/data/post_model.dart';
import '../../posts/data/comment_model.dart';

// ── Enriched post (post + resolved names) ────────────────────
class _EnrichedPost {
  final PostModel post;
  final String mosqueName;
  final String imamName;

  const _EnrichedPost({
    required this.post,
    required this.mosqueName,
    required this.imamName,
  });
}

// ── All Posts Admin Screen ────────────────────────────────────
class AllPostsScreen extends ConsumerStatefulWidget {
  const AllPostsScreen({super.key});

  @override
  ConsumerState<AllPostsScreen> createState() => _AllPostsScreenState();
}

class _AllPostsScreenState extends ConsumerState<AllPostsScreen> {
  static const _pageSize = 20;
  // Internal Firestore category values (Arabic) – keep as-is for DB filtering
  static const _categories = [
    'الكل',
    'درس',
    'خطبة',
    'إعلان',
    'نشاط',
    'تنبيه',
  ];

  // Map internal Arabic category value → localized display label
  String _localizedCategory(String cat, AppLocalizations l10n) {
    switch (cat) {
      case 'درس':
        return l10n.categoryLesson;
      case 'خطبة':
        return l10n.categoryKhutbah;
      case 'إعلان':
        return l10n.categoryAnnouncement;
      case 'نشاط':
        return l10n.categoryActivity;
      case 'تنبيه':
        return l10n.categoryAlert;
      case 'الكل':
        return l10n.allCategories;
      default:
        return cat;
    }
  }

  String _selectedCategory = 'الكل';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  final List<PostModel> _rawPosts = [];
  DocumentSnapshot? _lastDoc;

  // Cache: mosqueId → name, imamId → name
  final Map<String, String> _mosqueNames = {};
  final Map<String, String> _imamNames = {};

  List<_EnrichedPost> get _enriched => _rawPosts
      .map((p) => _EnrichedPost(
            post: p,
            mosqueName: _mosqueNames[p.mosqueId] ?? p.mosqueId,
            imamName: _imamNames[p.imamId] ?? p.imamId,
          ))
      .toList();

  List<_EnrichedPost> get _filtered {
    final q = _searchQuery.toLowerCase();
    if (q.isEmpty) return _enriched;
    return _enriched
        .where((e) =>
            e.mosqueName.toLowerCase().contains(q) ||
            e.imamName.toLowerCase().contains(q))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _load(refresh: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool refresh = false}) async {
    if (_isLoading) return;
    setState(() => _isLoading = refresh);

    if (refresh) {
      _rawPosts.clear();
      _lastDoc = null;
      _hasMore = true;
    }

    try {
      final repo = ref.read(adminRepositoryProvider);

      // When changing category with pagination, the cursor from the previous
      // category page is not valid. Always reset on category change.
      final posts = await repo.fetchAllPosts(
        category: _selectedCategory == 'الكل' ? null : _selectedCategory,
        limit: _pageSize,
        startAfter: refresh ? null : _lastDoc,
      );

      if (posts.isNotEmpty) {
        // Fetch the last document snapshot for the pagination cursor
        _lastDoc =
            await repo.getPostSnapshot(posts.last.id);
      }

      if (posts.length < _pageSize) _hasMore = false;

      // Collect IDs that aren't cached yet
      final newMosqueIds =
          posts.map((p) => p.mosqueId).where((id) => !_mosqueNames.containsKey(id)).toSet();
      final newImamIds =
          posts.map((p) => p.imamId).where((id) => !_imamNames.containsKey(id)).toSet();

      await _resolveNames(newMosqueIds, newImamIds);

      if (mounted) {
        setState(() {
          if (refresh) _rawPosts.clear();
          _rawPosts.addAll(posts);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _lastDoc == null) return;
    setState(() => _isLoadingMore = true);

    try {
      final repo = ref.read(adminRepositoryProvider);
      final posts = await repo.fetchAllPosts(
        category: _selectedCategory == 'الكل' ? null : _selectedCategory,
        limit: _pageSize,
        startAfter: _lastDoc,
      );

      if (posts.isNotEmpty) {
        _lastDoc = await repo.getPostSnapshot(posts.last.id);
      }
      if (posts.length < _pageSize) _hasMore = false;

      final newMosqueIds =
          posts.map((p) => p.mosqueId).where((id) => !_mosqueNames.containsKey(id)).toSet();
      final newImamIds =
          posts.map((p) => p.imamId).where((id) => !_imamNames.containsKey(id)).toSet();
      await _resolveNames(newMosqueIds, newImamIds);

      if (mounted) {
        setState(() {
          _rawPosts.addAll(posts);
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _resolveNames(
      Set<String> mosqueIds, Set<String> imamIds) async {
    final db = FirebaseFirestore.instance;

    // Firestore `whereIn` accepts max 30 IDs per query
    Future<void> fetchMosques(List<String> ids) async {
      if (ids.isEmpty) return;
      final snap =
          await db.collection('mosques').where(FieldPath.documentId, whereIn: ids).get();
      for (final doc in snap.docs) {
        _mosqueNames[doc.id] = (doc.data()['name'] as String?) ?? doc.id;
      }
    }

    Future<void> fetchImams(List<String> ids) async {
      if (ids.isEmpty) return;
      final snap =
          await db.collection('imams').where(FieldPath.documentId, whereIn: ids).get();
      for (final doc in snap.docs) {
        _imamNames[doc.id] = (doc.data()['fullName'] as String?) ?? doc.id;
      }
    }

    final mIds = mosqueIds.toList();
    final iIds = imamIds.toList();

    // Chunk into 30
    for (var i = 0; i < mIds.length; i += 30) {
      await fetchMosques(mIds.sublist(i, (i + 30).clamp(0, mIds.length)));
    }
    for (var i = 0; i < iIds.length; i += 30) {
      await fetchImams(iIds.sublist(i, (i + 30).clamp(0, iIds.length)));
    }
  }

  void _onCategoryTap(String cat) {
    if (cat == _selectedCategory) return;
    setState(() => _selectedCategory = cat);
    _load(refresh: true);
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'درس':
        return const Color(0xFF2563EB);
      case 'خطبة':
        return const Color(0xFF9333EA);
      case 'نشاط':
        return const Color(0xFFD97706);
      case 'تنبيه':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF0F766E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        // ── Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.searchMosqueImamHint,
              prefixIcon:
                  const Icon(Icons.search_rounded, color: Color(0xFF0F766E)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
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
            onChanged: (v) => setState(() => _searchQuery = v.trim()),
          ),
        ),

        // ── Category filter chips
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final cat = _categories[i];
              final selected = cat == _selectedCategory;
              final color = cat == 'الكل'
                  ? const Color(0xFF0F766E)
                  : _categoryColor(cat);
              return ChoiceChip(
                label: Text(_localizedCategory(cat, l10n)),
                selected: selected,
                onSelected: (_) => _onCategoryTap(cat),
                selectedColor: color,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                      color: selected ? color : Colors.grey.shade300),
                ),
                showCheckmark: false,
              );
            },
          ),
        ),
        const SizedBox(height: 6),

        // ── Post list
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF0F766E)))
              : _filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.article_outlined,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(l10n.noMatchingPosts,
                              style: const TextStyle(
                                  color: Colors.black45, fontSize: 14)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: const Color(0xFF0F766E),
                      onRefresh: () => _load(refresh: true),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                        itemCount: _filtered.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (i == _filtered.length) {
                            return _LoadMoreButton(
                              isLoading: _isLoadingMore,
                              onTap: _loadMore,
                            );
                          }
                          return _AdminPostCard(
                            enriched: _filtered[i],
                            categoryColor: _categoryColor(
                                _filtered[i].post.category),
                            onDeleted: () => setState(() {
                              _rawPosts.removeWhere(
                                  (p) => p.id == _filtered[i].post.id);
                            }),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

// ── Load More Button ──────────────────────────────────────────
class _LoadMoreButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _LoadMoreButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: isLoading
            ? const CircularProgressIndicator(color: Color(0xFF0F766E))
            : OutlinedButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.expand_more_rounded,
                    color: Color(0xFF0F766E)),
                label: Text(l10n.loadMore,
                    style: const TextStyle(color: Color(0xFF0F766E))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF0F766E)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                ),
              ),
      ),
    );
  }
}

// ── Admin Post Card ───────────────────────────────────────────
class _AdminPostCard extends ConsumerStatefulWidget {
  final _EnrichedPost enriched;
  final Color categoryColor;
  final VoidCallback onDeleted;

  const _AdminPostCard({
    required this.enriched,
    required this.categoryColor,
    required this.onDeleted,
  });

  @override
  ConsumerState<_AdminPostCard> createState() => _AdminPostCardState();
}

class _AdminPostCardState extends ConsumerState<_AdminPostCard> {
  void _openDetail() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AdminPostDetailSheet(
        enriched: widget.enriched,
        onPostDeleted: () {
          Navigator.of(context).pop();
          widget.onDeleted();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.enriched.post;
    final dateStr =
        DateFormat('dd/MM/yyyy – HH:mm').format(post.createdAt);
    final hasMedia =
        post.mediaUrls.isNotEmpty && post.mediaType != 'none';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0.5,
      child: InkWell(
        onTap: _openDetail,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category badge + date
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color:
                          widget.categoryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      post.category,
                      style: TextStyle(
                          color: widget.categoryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  Text(dateStr,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.black45)),
                ],
              ),
              const SizedBox(height: 10),

              // Mosque + imam
              Row(
                children: [
                  const Icon(Icons.mosque_rounded,
                      size: 14, color: Color(0xFF0F766E)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.enriched.mosqueName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.person_rounded,
                      size: 14, color: Colors.black38),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      widget.enriched.imamName,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Text preview + optional thumbnail
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      post.text,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black87, height: 1.45),
                    ),
                  ),
                  if (hasMedia && post.mediaType == 'image') ...[
                    const SizedBox(width: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        post.mediaUrls.first,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),

              // Stats row
              Row(
                children: [
                  const Icon(Icons.thumb_up_outlined,
                      size: 14, color: Colors.black38),
                  const SizedBox(width: 4),
                  Text('${post.likeCount}',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54)),
                  const SizedBox(width: 14),
                  const Icon(Icons.comment_outlined,
                      size: 14, color: Colors.black38),
                  const SizedBox(width: 4),
                  Text('${post.commentCount}',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54)),
                  const Spacer(),
                  const Icon(Icons.chevron_left_rounded,
                      color: Colors.black26, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Admin Post Detail Bottom Sheet ────────────────────────────
class _AdminPostDetailSheet extends ConsumerStatefulWidget {
  final _EnrichedPost enriched;
  final VoidCallback onPostDeleted;

  const _AdminPostDetailSheet({
    required this.enriched,
    required this.onPostDeleted,
  });

  @override
  ConsumerState<_AdminPostDetailSheet> createState() =>
      _AdminPostDetailSheetState();
}

class _AdminPostDetailSheetState
    extends ConsumerState<_AdminPostDetailSheet> {
  bool _isDeletingPost = false;

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red : const Color(0xFF0F766E),
    ));
  }

  Future<void> _deletePost() async {
    final l10n = context.l10n;
    final confirmed = await _confirmDialog(
      context,
      title: l10n.deletePostConfirmTitle,
      body: l10n.deletePostConfirmBody,
      action: l10n.delete,
      actionColor: Colors.red,
    );
    if (confirmed != true) return;

    setState(() => _isDeletingPost = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .deletePostAsAdmin(widget.enriched.post.id);
      if (mounted) widget.onPostDeleted();
    } catch (e) {
      if (mounted) _showSnack('${l10n.deleteFailed}: $e', error: true);
    } finally {
      if (mounted) setState(() => _isDeletingPost = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.enriched.post;
    final dateStr =
        DateFormat('dd/MM/yyyy – HH:mm').format(post.createdAt);

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF4F6F8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),

              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.article_rounded,
                        color: Color(0xFF0F766E)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${widget.enriched.mosqueName} · ${widget.enriched.imamName}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Delete button
                    _isDeletingPost
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.red))
                        : Builder(builder: (ctx) {
                            final l10n = ctx.l10n;
                            return IconButton(
                              tooltip: l10n.deletePost,
                              icon: const Icon(Icons.delete_forever_rounded,
                                  color: Colors.red),
                              onPressed: _deletePost,
                            );
                          }),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Body
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Post metadata
                    _MetaRow(
                        icon: Icons.category_rounded,
                        text: post.category,
                        color: _catColor(post.category)),
                    const SizedBox(height: 6),
                    _MetaRow(
                        icon: Icons.calendar_today_rounded,
                        text: dateStr),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.thumb_up_outlined,
                            size: 14, color: Colors.black38),
                        const SizedBox(width: 4),
                        Text('${post.likeCount}',
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 12),
                        const Icon(Icons.comment_outlined,
                            size: 14, color: Colors.black38),
                        const SizedBox(width: 4),
                        Text('${post.commentCount}',
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Post text
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        post.text,
                        style: const TextStyle(
                            fontSize: 14, height: 1.6),
                      ),
                    ),

                    // Media
                    if (post.mediaUrls.isNotEmpty &&
                        post.mediaType == 'image') ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          post.mediaUrls.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Comments section
                    Builder(builder: (ctx) {
                      return Text(
                        ctx.l10n.commentsLabel,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      );
                    }),
                    const SizedBox(height: 10),
                    _CommentsSection(postId: post.id),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _catColor(String cat) {
    switch (cat) {
      case 'درس':
        return const Color(0xFF2563EB);
      case 'خطبة':
        return const Color(0xFF9333EA);
      case 'نشاط':
        return const Color(0xFFD97706);
      case 'تنبيه':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF0F766E);
    }
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _MetaRow({
    required this.icon,
    required this.text,
    this.color = Colors.black45,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}

// ── Comments Section (admin can delete any) ───────────────────
class _CommentsSection extends ConsumerWidget {
  final String postId;

  const _CommentsSection({required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentsStream = ref
        .watch(adminRepositoryProvider)
        .watchCommentsForPost(postId);

    return StreamBuilder<List<CommentModel>>(
      stream: commentsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0F766E)));
        }
        final comments = snapshot.data ?? [];
        if (comments.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(context.l10n.noCommentsYet,
                  style: const TextStyle(color: Colors.black45)),
            ),
          );
        }
        return Column(
          children: comments
              .map((c) => _CommentTile(postId: postId, comment: c))
              .toList(),
        );
      },
    );
  }
}

class _CommentTile extends ConsumerStatefulWidget {
  final String postId;
  final CommentModel comment;

  const _CommentTile({required this.postId, required this.comment});

  @override
  ConsumerState<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends ConsumerState<_CommentTile> {
  bool _deleting = false;

  Future<void> _deleteComment() async {
    final l10n = context.l10n;
    final confirmed = await _confirmDialog(
      context,
      title: l10n.deleteComment,
      body: l10n.deleteCommentConfirm,
      action: l10n.delete,
      actionColor: Colors.red,
    );
    if (confirmed != true) return;
    setState(() => _deleting = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .deleteCommentAsAdmin(widget.postId, widget.comment.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${l10n.commentDeleteFailed}: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeStr =
        DateFormat('dd/MM/yyyy – HH:mm').format(widget.comment.timestamp);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 0.3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFE5F3F1),
              backgroundImage: widget.comment.photo != null
                  ? NetworkImage(widget.comment.photo!)
                  : null,
              child: widget.comment.photo == null
                  ? const Icon(Icons.person_rounded,
                      size: 18, color: Color(0xFF0F766E))
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.comment.userName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const Spacer(),
                      Text(timeStr,
                          style: const TextStyle(
                              fontSize: 10, color: Colors.black38)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(widget.comment.text,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black87)),
                ],
              ),
            ),
            const SizedBox(width: 6),
            _deleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.red))
                : IconButton(
                    tooltip: context.l10n.deleteComment,
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.red, size: 20),
                    onPressed: _deleteComment,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
          ],
        ),
      ),
    );
  }
}

// ── Shared confirm dialog (locale-aware) ────────────────────────────
Future<bool?> _confirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
  Color actionColor = Colors.red,
}) {
  final l10n = context.l10n;
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.bold)),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(action,
              style: TextStyle(
                  color: actionColor, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}
