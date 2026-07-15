import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import '../../../core/l10n/app_localizations.dart';
import '../data/post_model.dart';
import '../data/posts_repository.dart';
import '../data/comment_model.dart';
import '../data/like_model.dart';
import '../../../core/providers/firebase_providers.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    // Increment view count on open
    Future.microtask(() {
      ref.read(postsRepositoryProvider).incrementViewCount(widget.postId);
    });
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'درس':
        return const Color(0xFF2563EB);
      case 'خطبة':
        return const Color(0xFF9333EA);
      case 'نشاط':
        return const Color(0xFFD97706);
      case 'تنبيه':
        return const Color(0xFFDC2626);
      case 'إعلان':
      default:
        return const Color(0xFF0F766E);
    }
  }

  String _getCategoryDisplayName(String category, AppLocalizations l10n) {
    switch (category) {
      case 'درس':
        return l10n.categoryLesson;
      case 'خطبة':
        return l10n.categoryKhutbah;
      case 'نشاط':
        return l10n.categoryActivity;
      case 'تنبيه':
        return l10n.categoryAlert;
      case 'إعلان':
      default:
        return l10n.categoryAnnouncement;
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF0F766E),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = context.l10n;
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.deletePostConfirmTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(l10n.deletePostConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isDeleting = true);
      try {
        await ref.read(postsRepositoryProvider).deletePost(widget.postId);
        _showSnackBar(l10n.postDeletedSuccessfully);
        navigator.pop(); // Close details screen
      } catch (e) {
        _showSnackBar('${l10n.deleteFailed}: $e');
      } finally {
        if (mounted) setState(() => _isDeleting = false);
      }
    }
  }

  Future<void> _openEditSheet(PostModel post) async {
    final l10n = context.l10n;
    final textController = TextEditingController(text: post.text);
    String selectedCategory = post.category;
    final categories = ['درس', 'خطبة', 'إعلان', 'نشاط', 'تنبيه'];
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.all(Radius.circular(2)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.edit,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: textController,
                        maxLines: 5,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return l10n.enterPostContent;
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.postCategory,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: categories.map((cat) {
                          final isSelected = selectedCategory == cat;
                          return ChoiceChip(
                            label: Text(_getCategoryDisplayName(cat, l10n)),
                            selected: isSelected,
                            selectedColor: const Color(0xFF0F766E),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() {
                                  selectedCategory = cat;
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            final updated = post.copyWith(
                              text: textController.text.trim(),
                              category: selectedCategory,
                            );
                            final navigator = Navigator.of(context);
                            await ref.read(postsRepositoryProvider).updatePost(updated);
                            navigator.pop();
                            _showSnackBar(l10n.postUpdatedSuccessfully);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F766E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            l10n.saveChanges,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final postStream = ref.watch(postsRepositoryProvider).watchPost(widget.postId);
    final commentsAsync = ref.watch(postCommentsProvider(widget.postId));
    final likesAsync = ref.watch(postLikesProvider(widget.postId));
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: Text(
          l10n.postDetails,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0.5,
        centerTitle: true,
      ),
      body: StreamBuilder<PostModel?>(
        stream: postStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0F766E)));
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(child: Text(l10n.postNotFound));
          }

          final post = snapshot.data!;
          final catColor = _getCategoryColor(post.category);
          final catName = _getCategoryDisplayName(post.category, l10n);
          final formattedDate = intl.DateFormat('yyyy/MM/dd hh:mm a').format(post.createdAt);

          final commentCount = commentsAsync.maybeWhen(
            data: (list) => list.length,
            orElse: () => post.commentCount,
          );
          final likeCount = likesAsync.maybeWhen(
            data: (list) => list.length,
            orElse: () => post.likeCount,
          );

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Post Details Card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header row: category, views, date
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: catColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    catName,
                                    style: TextStyle(
                                      color: catColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.remove_red_eye_rounded, size: 16, color: Colors.black38),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${post.viewCount}',
                                      style: const TextStyle(fontSize: 13, color: Colors.black45),
                                    ),
                                    const SizedBox(width: 12),
                                    InkWell(
                                      onTap: () => _showLikesSheet(context, post.id, l10n),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.favorite_rounded, size: 16, color: Colors.redAccent),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$likeCount',
                                              style: const TextStyle(fontSize: 13, color: Colors.black45),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.comment_rounded, size: 16, color: Color(0xFF0F766E)),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$commentCount',
                                      style: const TextStyle(fontSize: 13, color: Colors.black45),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Post text
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              post.text,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF1F2937),
                                height: 1.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Media attachment preview
                          if (post.mediaUrls.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: _buildMediaWidget(post, l10n),
                            ),
                            const SizedBox(height: 16),
                          ],

                          const Divider(height: 1, color: Color(0xFFF3F4F6)),

                          // Info details
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                _infoRow(Icons.calendar_today_rounded, l10n.creationDate, formattedDate),
                                if (post.eventDate != null) ...[
                                  const SizedBox(height: 10),
                                  _infoRow(
                                    Icons.event_rounded,
                                    l10n.eventDateLabel,
                                    intl.DateFormat('yyyy/MM/dd hh:mm a').format(post.eventDate!),
                                  ),
                                ],
                                if (post.scheduledFor != null) ...[
                                  const SizedBox(height: 10),
                                  _infoRow(
                                    Icons.schedule_rounded,
                                    l10n.scheduledPublishDate,
                                    intl.DateFormat('yyyy/MM/dd hh:mm a').format(post.scheduledFor!),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Actions panel
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _openEditSheet(post),
                            icon: const Icon(Icons.edit_rounded, color: Color(0xFF0F766E), size: 20),
                            label: Text(l10n.edit, style: const TextStyle(fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0F766E),
                              side: const BorderSide(color: Color(0xFF0F766E)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isDeleting ? null : () => _confirmDelete(context),
                            icon: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 20),
                            label: Text(l10n.delete, style: const TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildCommentsSection(context, post, commentCount, l10n),
                  ],
                ),
              ),
              if (_isDeleting)
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0F766E)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black38),
        const SizedBox(width: 10),
        Text(
          '$label:',
          style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
        ),
      ],
    );
  }

  Widget _buildMediaWidget(PostModel post, AppLocalizations l10n) {
    if (post.mediaType == 'image') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          post.mediaUrls.first,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    } else {
      // For video/file, render a premium action file tile
      final isVideo = post.mediaType == 'video';
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE5F3F1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isVideo ? Icons.video_collection_rounded : Icons.insert_drive_file_rounded,
                color: const Color(0xFF0F766E),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isVideo ? l10n.attachedVideoFile : l10n.attachedDocumentFile,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    post.mediaUrls.first.split('?').first.split('/').last,
                    style: const TextStyle(fontSize: 11, color: Colors.black38),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildCommentsSection(BuildContext context, PostModel post, int commentCount, AppLocalizations l10n) {
    final currentUserId = ref.watch(firebaseAuthProvider).currentUser?.uid;
    final isOwner = post.imamId == currentUserId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.comment_rounded, color: Color(0xFF0F766E), size: 20),
            const SizedBox(width: 8),
            Text(
              '${l10n.commentsLabel} ($commentCount)',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<CommentModel>>(
          stream: ref.watch(postsRepositoryProvider).watchComments(post.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(color: Color(0xFF0F766E)),
                ),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  '${l10n.errorLoadingData}: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }
            final comments = snapshot.data ?? [];
            if (comments.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    l10n.noCommentsYet,
                    style: const TextStyle(color: Colors.black45, fontSize: 14),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final comment = comments[index];
                return _buildCommentTile(context, post.id, comment, isOwner, l10n);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCommentTile(
    BuildContext context,
    String postId,
    CommentModel comment,
    bool isOwner,
    AppLocalizations l10n,
  ) {
    final formattedTime = intl.DateFormat('yyyy/MM/dd hh:mm a').format(comment.timestamp);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: comment.photo != null && comment.photo!.isNotEmpty
                ? Image.network(
                    comment.photo!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholderAvatar(),
                  )
                : _buildPlaceholderAvatar(),
          ),
          const SizedBox(width: 12),

          // Content Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: name + time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      comment.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      formattedTime,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black38,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Text
                Text(
                  comment.text,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF374151),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // Delete button (only visible to post owner)
          if (isOwner) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 20),
              onPressed: () => _confirmDeleteComment(context, postId, comment.id, l10n),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceholderAvatar() {
    return Container(
      width: 40,
      height: 40,
      color: const Color(0xFFE5F3F1),
      child: const Icon(Icons.person_rounded, color: Color(0xFF0F766E), size: 22),
    );
  }

  Future<void> _confirmDeleteComment(
    BuildContext context,
    String postId,
    String commentId,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.deleteComment, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(l10n.deleteCommentConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(postsRepositoryProvider).deleteComment(postId, commentId);
        _showSnackBar(l10n.commentDeleted);
      } catch (e) {
        _showSnackBar('${l10n.deleteFailed}: $e');
      }
    }
  }

  void _showLikesSheet(BuildContext context, String postId, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    l10n.likesLabel,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: StreamBuilder<List<LikeModel>>(
                  stream: ref.watch(postsRepositoryProvider).watchLikes(postId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(color: Color(0xFF0F766E)),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          '${l10n.errorLoadingData}: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }
                    final likes = snapshot.data ?? [];
                    if (likes.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                          child: Text(
                            l10n.noLikesYet,
                            style: const TextStyle(color: Colors.black45, fontSize: 14),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: likes.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
                      itemBuilder: (context, index) {
                        final like = likes[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: like.photo != null && like.photo!.isNotEmpty
                                    ? Image.network(
                                        like.photo!,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _buildPlaceholderAvatar(),
                                      )
                                    : _buildPlaceholderAvatar(),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  like.userName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
