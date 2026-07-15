import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../registration/data/registration_repository.dart';
import '../../registration/domain/imam_model.dart';
import '../../registration/domain/mosque_model.dart';
import '../widgets/action_card.dart';
import '../widgets/bottom_nav_bar.dart';
import '../../posts/presentation/create_post_screen.dart';
import '../../posts/presentation/my_posts_screen.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/router/app_router.dart';
import '../../admin/presentation/admin_panel_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../profile/presentation/profile_settings_screen.dart';
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
            return mosqueAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text('${l10n.errorLoadingMosque}: $e')),
              data: (mosque) {
                if (mosque == null) {
                  return Center(
                    child: Text(l10n.mosqueDataNotFound),
                  );
                }
                Widget body;
                if (_navIndex == 1) {
                  body = const MyPostsScreen();
                } else if (_navIndex == 3) {
                  body = const ProfileSettingsScreen();
                } else if (_navIndex == 4) {
                  body = const AdminPanelScreen();
                } else {
                  body = RefreshIndicator(
                    onRefresh: () async {},
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildGreeting(imam, l10n),
                        const SizedBox(height: 16),
                        if (imam.isPending) _buildPendingBanner(l10n),
                        if (imam.isPending) const SizedBox(height: 16),
                        _buildMosqueProfileCard(mosque, l10n),
                        const SizedBox(height: 20),
                        _buildActionGrid(imam.isPending, l10n),
                        const SizedBox(height: 24),
                        _buildStatsSection(mosque.id, imam.id, l10n),
                        const SizedBox(height: 12),
                      ],
                    ),
                  );
                }
                return body;
              },
            );
          },
        ),
      ),
      bottomNavigationBar: ManbarBottomNavBar(
        currentIndex: _navIndex,
        showAdmin: isAdmin,
        onTap: (i) {
          if (i == 2) {
            // Prayer times tab — push route, don't change body index
            final mosque = mosqueAsync.asData?.value;
            if (mosque != null) {
              context.push(AppRoutes.prayerTimes, extra: mosque.id);
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
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
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
            child: const Icon(Icons.notifications_none_rounded,
                color: Color(0xFF0F766E)),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingBanner(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD98E)),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_top_rounded, color: Color(0xFFB7791F)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.pendingBanner,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF7C5A16),
                height: 1.5,
              ),
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

  Widget _buildStatsSection(String mosqueId, String imamId, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.todayStats,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .where('mosqueId', isEqualTo: mosqueId)
              .snapshots(),
          builder: (context, postsSnapshot) {
            final posts = postsSnapshot.data?.docs ?? [];
            final totalViews = posts.fold<int>(
                0, (acc, doc) => acc + ((doc.data()['viewCount'] as int?) ?? 0));

            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('mosques')
                  .doc(mosqueId)
                  .collection('stats')
                  .doc('today')
                  .snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data();
                final notifications = data?['notifications'] ?? 0;

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('mosques')
                      .doc(mosqueId)
                      .collection('followers')
                      .snapshots(),
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

                        return Row(
                          children: [
                            _statTile(l10n.views, totalViews.toString(),
                                Icons.remove_red_eye_rounded, const Color(0xFF0F766E)),
                            const SizedBox(width: 10),
                            _statTile(l10n.followers, totalFollowers.toString(),
                                Icons.people_alt_rounded, const Color(0xFF2563EB)),
                            const SizedBox(width: 10),
                            _statTile(l10n.alerts, notifications.toString(),
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
}
