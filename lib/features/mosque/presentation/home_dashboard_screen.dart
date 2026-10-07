import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../registration/data/registration_repository.dart';
import '../../registration/domain/imam_model.dart';
import '../../registration/domain/mosque_model.dart';
import '../widgets/action_card.dart';
import '../widgets/bottom_nav_bar.dart';
import '../../posts/presentation/create_post_screen.dart';
import '../../posts/presentation/my_posts_screen.dart';
import '../../questions/presentation/incoming_questions_screen.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/router/app_router.dart';
import '../../admin/presentation/admin_panel_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../profile/presentation/profile_settings_screen.dart';
import '../../forum/presentation/discover_groups_screen.dart';
import '../../admin/data/admin_repository.dart';
import '../../suggestions/presentation/suggest_to_admin_sheet.dart';
import 'mosque_profile_screen.dart';

class HomeDashboardScreen extends ConsumerStatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  ConsumerState<HomeDashboardScreen> createState() =>
      _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends ConsumerState<HomeDashboardScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isAdmin = ref.watch(isAdminProvider).asData?.value ?? false;
    if (isAdmin) {
      return const AdminPanelScreen();
    }

    final imamAsync = ref.watch(currentImamProvider);
    final mosqueAsync = ref.watch(currentMosqueProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: SafeArea(
        child: imamAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('${l10n.errorLoadingProfile}: $e')),
          data: (imam) {
            if (imam == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_navIndex == 1) {
              return IncomingQuestionsScreen(
                imamId: imam.id,
                mosqueId: mosqueAsync.asData?.value?.id,
              );
            } else if (_navIndex == 2) {
              return const DiscoverGroupsScreen();
            } else if (_navIndex == 4) {
              return const ProfileSettingsScreen();
            } else if (_navIndex == 5) {
              return const AdminPanelScreen();
            }

            return mosqueAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text('${l10n.errorLoadingMosque}: $e')),
              data: (mosque) {
                return RefreshIndicator(
                  onRefresh: () async {},
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildGreeting(imam, l10n),
                      const SizedBox(height: 16),
                      
                      // Only show Mosque Profile if they have one,
                      // otherwise show a prompt to add one
                      if (mosque != null) ...[
                        _buildMosqueProfileCard(mosque, l10n),
                        const SizedBox(height: 16),
                      ] else ...[
                        _buildAddMosqueBanner(l10n),
                        const SizedBox(height: 16),
                      ],

                      _buildImamForumBanner(l10n),
                      const SizedBox(height: 20),
                      _buildActionGrid(false, l10n), // Never disable action grid
                      const SizedBox(height: 24),
                      _buildStatsSection(mosque?.id, imam.id, l10n),
                      const SizedBox(height: 18),
                      _buildSuggestionsCard(imam.id),
                      const SizedBox(height: 16),
                      _buildWhatsAppBanner(),
                      const SizedBox(height: 12),
                      _buildTelegramBanner(),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: ManbarBottomNavBar(
        currentIndex: _navIndex,
        showAdmin: isAdmin,
        onTap: (i) {
          if (i == 3) {
            // Prayer times tab — push route, don't change body index
            final mosque = mosqueAsync.asData?.value;
            if (mosque != null) {
              context.push(AppRoutes.prayerTimes, extra: mosque.id);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.mosqueDataNotFound),
                  backgroundColor: const Color(0xFF0F766E),
                ),
              );
            }
            return;
          }
          setState(() => _navIndex = i);
        },
      ),
    );
  }


  Widget _buildGreeting(ImamModel imam, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.greeting,
                style: const TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.imamName(imam.fullName.isNotEmpty ? imam.fullName : ''),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('imams')
              .doc(imam.id)
              .collection('notifications')
              .where('read', isEqualTo: false)
              .snapshots(),
          builder: (context, snapshot) {
            final unreadCount = snapshot.data?.docs.length ?? 0;
            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const NotificationsScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text('$unreadCount'),
                  backgroundColor: const Color(0xFFE11D48),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: Color(0xFF0F766E),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }



  Widget _buildAddMosqueBanner(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mosque_rounded, color: Color(0xFF9CA3AF), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.mosqueDataNotFound,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.addMosqueLater,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              setState(() => _navIndex = 4); // Switch to Profile Tab
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(
              'الإعدادات',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMosqueProfileCard(MosqueModel mosque, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MosqueProfileScreen(mosqueId: mosque.id),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: mosque.photo != null && mosque.photo!.isNotEmpty
                  ? Image.network(
                      mosque.photo!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 64,
                      height: 64,
                      color: const Color(0xFFE5F3F1),
                      child: const Icon(Icons.mosque_rounded,
                          color: Color(0xFF0F766E)),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          mosque.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (mosque.verified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded,
                            color: Color(0xFF0F766E), size: 18),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 14, color: Colors.black45),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          mosque.city.isNotEmpty
                              ? mosque.city
                              : l10n.locationUnset,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.black38),
          ],
        ),
      ),
    );
  }

  Widget _buildImamForumBanner(AppLocalizations l10n) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const DiscoverGroupsScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF003527), Color(0xFF065F46)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF003527).withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.forum_rounded,
                color: Color(0xFFB0F0D6),
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Flexible(
                        child: Text(
                          'ملتقى الأئمة والمجموعات التخصصية',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB7922E),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'جديد',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'غرف نقاش تخصصية (فقه، حديث، قضايا معاصرة...) وشات مباشر بين الأئمة',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFD1FAE5),
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionGrid(bool isPending, AppLocalizations l10n) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.15,
      children: [
        ActionCard(
          icon: Icons.campaign_rounded,
          title: l10n.publishAnnouncement,
          color: const Color(0xFF0F766E),
          disabled: isPending,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const CreatePostScreen(),
              ),
            );
          },
        ),
        ActionCard(
          icon: Icons.access_time_filled_rounded,
          title: l10n.managePrayerTimes,
          color: const Color(0xFF2563EB),
          disabled: isPending,
          onTap: () {
            final mosque = ref.read(currentMosqueProvider).asData?.value;
            if (mosque != null) {
              context.push(AppRoutes.prayerTimes, extra: mosque.id);
            }
          },
        ),
        ActionCard(
          icon: Icons.grid_view_rounded,
          title: l10n.viewPosts,
          color: const Color(0xFF9333EA),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const MyPostsScreen(),
              ),
            );
          },
        ),
        ActionCard(
          icon: Icons.notifications_active_rounded,
          title: l10n.notificationsAlerts,
          color: const Color(0xFFDB6A26),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatsSection(String? mosqueId, String imamId, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.todayStats,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: mosqueId != null 
              ? FirebaseFirestore.instance
                  .collection('posts')
                  .where('mosqueId', isEqualTo: mosqueId)
                  .snapshots()
              : FirebaseFirestore.instance
                  .collection('posts')
                  .where('imamId', isEqualTo: imamId)
                  .snapshots(),
          builder: (context, postsSnapshot) {
            final posts = postsSnapshot.data?.docs ?? [];
            final totalViews = posts.fold<int>(
                0, (acc, doc) => acc + ((doc.data()['viewCount'] as int?) ?? 0));

            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: mosqueId != null 
                  ? FirebaseFirestore.instance
                      .collection('mosques')
                      .doc(mosqueId)
                      .collection('stats')
                      .doc('today')
                      .snapshots()
                  : const Stream.empty(),
              builder: (context, snapshot) {
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: mosqueId != null 
                      ? FirebaseFirestore.instance
                          .collection('mosques')
                          .doc(mosqueId)
                          .collection('followers')
                          .snapshots()
                      : const Stream.empty(),
                  builder: (context, mosqueFollowersSnapshot) {
                    final mosqueFollowers = mosqueFollowersSnapshot.data?.size ?? 0;

                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('imams')
                          .doc(imamId)
                          .collection('followers')
                          .snapshots(),
                      builder: (context, followersSnapshot) {
                        final directImamFollowers = followersSnapshot.data?.size ?? 0;
                        final totalFollowers = mosqueFollowers + directImamFollowers;

                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('imams')
                          .doc(imamId)
                          .collection('notifications')
                          .where('read', isEqualTo: false)
                          .snapshots(),
                      builder: (context, notifSnapshot) {
                        final unreadNotifications = notifSnapshot.data?.size ?? 0;

                        return Row(
                          children: [
                            _statTile(l10n.views, totalViews.toString(),
                                Icons.remove_red_eye_rounded, const Color(0xFF0F766E)),
                            const SizedBox(width: 10),
                            _statTile(l10n.followers, totalFollowers.toString(),
                                Icons.people_alt_rounded, const Color(0xFF2563EB)),
                            const SizedBox(width: 10),
                            _statTile(l10n.alerts, unreadNotifications.toString(),
                                Icons.notifications_rounded, const Color(0xFFDB6A26)),
                          ],
                        );
                      },
                    );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _statTile(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsCard(String imamId) {
    final mySuggestionsAsync = ref.watch(mySuggestionsProvider(imamId));
    final suggestions = mySuggestionsAsync.asData?.value ?? [];
    final hasReplied = suggestions.any((s) => s.adminResponse != null && s.adminResponse!.isNotEmpty);
    final pendingCount = suggestions.where((s) => s.status == 'pending').length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF0F766E).withValues(alpha: 0.12),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => showSuggestToAdminSheet(context),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.tips_and_updates_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Flexible(
                                child: Text(
                                  'صندوق المقترحات والتطوير',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF111827),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'صوتك مسموع',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F766E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'اقترح ميزات جديدة أو تحسينات تساهم في تطوير التطبيق',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Live status chips if user has submitted suggestions
                if (suggestions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: hasReplied
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: hasReplied
                            ? const Color(0xFFA7F3D0)
                            : const Color(0xFFFDE68A),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasReplied
                              ? Icons.mark_email_unread_rounded
                              : Icons.schedule_rounded,
                          size: 14,
                          color: hasReplied
                              ? const Color(0xFF047857)
                              : const Color(0xFFB45309),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            hasReplied
                                ? 'يوجد ردود وملاحظات جديدة من الإدارة على مقترحاتك!'
                                : 'لديك $pendingCount اقتراح قيد المراجعة والدراسة',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: hasReplied
                                  ? const Color(0xFF047857)
                                  : const Color(0xFFB45309),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Action Buttons Row (HCI: Clear Primary & Secondary CTAs)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => showSuggestToAdminSheet(context, initialTab: 0),
                        icon: const Icon(Icons.add_comment_rounded, size: 16),
                        label: const Text(
                          'تقديم اقتراح جديد',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (suggestions.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F766E),
                          side: const BorderSide(color: Color(0xFF0F766E)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () =>
                            showSuggestToAdminSheet(context, initialTab: 1),
                        icon: const Icon(Icons.history_rounded, size: 16),
                        label: Text(
                          'سجل مقترحاتي (${suggestions.length})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWhatsAppBanner() {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse('https://whatsapp.com/channel/0029VbDitEW9MF8usnUyMI0y');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF25D366), Color(0xFF128C7E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF25D366).withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.campaign_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'قناتنا على الواتساب',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'تابعنا للحصول على آخر الأخبار والتحديثات',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelegramBanner() {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse('https://t.me/+HFTrU_Fs5QBhZjk0');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF229ED9), Color(0xFF1D86B9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF229ED9).withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.telegram_rounded, // or telegram/send
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'قناتنا على تيليجرام',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'انضم إلينا للحصول على التحديثات والنقاشات',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
