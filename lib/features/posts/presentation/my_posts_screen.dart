import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import '../../../core/l10n/app_localizations.dart';
import '../../registration/data/registration_repository.dart';
import '../data/post_model.dart';
import '../data/posts_repository.dart';
import 'post_detail_screen.dart';

class MyPostsScreen extends ConsumerWidget {
  const MyPostsScreen({super.key});

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'درس':
        return const Color(0xFF2563EB); // Blue
      case 'خطبة':
        return const Color(0xFF9333EA); // Purple
      case 'نشاط':
        return const Color(0xFFD97706); // Orange
      case 'تنبيه':
        return const Color(0xFFDC2626); // Red
      case 'إعلان':
      default:
        return const Color(0xFF0F766E); // Teal
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imamAsync = ref.watch(currentImamProvider);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: Text(
          l10n.myPosts,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF111827),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        elevation: 0.5,
        centerTitle: true,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Color(0xFF111827),
                  size: 20,
                ),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
      ),
      body: imamAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF0F766E)),
        ),
        error: (error, _) => Center(
          child: Text('${l10n.errorLoadingData}: $error'),
        ),
        data: (imam) {
          if (imam == null) {
            return Center(
              child: Text(l10n.profileNotFound),
            );
          }

          final myPostsStream = ref.watch(postsRepositoryProvider).watchMyPosts(imam.id);

          return StreamBuilder<List<PostModel>>(
            stream: myPostsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF0F766E)),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('${l10n.errorLoadingData}: ${snapshot.error}'),
                );
              }

              final posts = snapshot.data ?? [];
              if (posts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.campaign_outlined,
                        size: 72,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noPostsYet,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.noPostsSubtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return _buildPostCard(context, ref, post, l10n);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, WidgetRef ref, PostModel post, AppLocalizations l10n) {
    final catColor = _getCategoryColor(post.category);
    final catName = _getCategoryDisplayName(post.category, l10n);
    final formattedDate = intl.DateFormat('yyyy/MM/dd').format(post.createdAt);
    final hasImage = post.mediaType == 'image' && post.mediaUrls.isNotEmpty;

    final commentsAsync = ref.watch(postCommentsProvider(post.id));
    final likesAsync = ref.watch(postLikesProvider(post.id));

    final commentCount = commentsAsync.maybeWhen(
      data: (list) => list.length,
      orElse: () => post.commentCount,
    );
    final likeCount = likesAsync.maybeWhen(
      data: (list) => list.length,
      orElse: () => post.likeCount,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PostDetailScreen(postId: post.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail image if available
                if (hasImage) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      post.mediaUrls.first,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
                // Content area
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: category chip & view count
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              catName,
                              style: TextStyle(
                                color: catColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.remove_red_eye_rounded,
                                  size: 14, color: Colors.black38),
                              const SizedBox(width: 4),
                              Text(
                                '${post.viewCount}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black45),
                              ),
                              const SizedBox(width: 10),
                              const Icon(Icons.favorite_rounded,
                                  size: 14, color: Colors.redAccent),
                              const SizedBox(width: 4),
                              Text(
                                '$likeCount',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black45),
                              ),
                              const SizedBox(width: 10),
                              const Icon(Icons.comment_rounded,
                                  size: 14, color: Color(0xFF0F766E)),
                              const SizedBox(width: 4),
                              Text(
                                '$commentCount',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black45),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Text excerpt
                      Text(
                        post.text,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1F2937),
                          height: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      // Footer: creation date & attachments count
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formattedDate,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black38),
                          ),
                          if (post.mediaType != 'none')
                            Row(
                              children: [
                                Icon(
                                  post.mediaType == 'image'
                                      ? Icons.image_rounded
                                      : post.mediaType == 'video'
                                          ? Icons.video_collection_rounded
                                          : Icons.insert_drive_file_rounded,
                                  size: 14,
                                  color: const Color(0xFF0F766E),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  post.mediaType == 'image'
                                      ? l10n.imageLabel
                                      : post.mediaType == 'video'
                                          ? l10n.videoLabel
                                          : l10n.fileLabel,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF0F766E),
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
