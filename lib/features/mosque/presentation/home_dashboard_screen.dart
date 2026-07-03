import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/mosque_model.dart';
import '../widgets/action_card.dart';
import '../widgets/bottom_nav_bar.dart';
import 'mosque_profile_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  int _navIndex = 0;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        body: SafeArea(
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('mosques')
                .doc(_uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.data!.exists) {
                return const Center(
                  child: Text('لم يتم العثور على بيانات المسجد'),
                );
              }

              final mosque =
                  MosqueModel.fromMap(snapshot.data!.id, snapshot.data!.data()!);
              final isPending = mosque.imamStatus == 'pending';

              return RefreshIndicator(
                onRefresh: () async {},
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildGreeting(mosque),
                    const SizedBox(height: 16),
                    if (isPending) _buildPendingBanner(),
                    if (isPending) const SizedBox(height: 16),
                    _buildMosqueProfileCard(mosque),
                    const SizedBox(height: 20),
                    _buildActionGrid(isPending),
                    const SizedBox(height: 24),
                    _buildStatsSection(),
                    const SizedBox(height: 12),
                  ],
                ),
              );
            },
          ),
        ),
        bottomNavigationBar: ManbarBottomNavBar(
          currentIndex: _navIndex,
          onTap: (i) => setState(() => _navIndex = i),
        ),
      ),
    );
  }

  Widget _buildGreeting(MosqueModel mosque) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'السلام عليكم',
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(height: 2),
              Text(
                'الإمام ${mosque.imamName.isNotEmpty ? mosque.imamName : ''}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Icon(Icons.notifications_none_rounded,
              color: Color(0xFF0F766E)),
        ),
      ],
    );
  }

  Widget _buildPendingBanner() {
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
          const Expanded(
            child: Text(
              'حسابك قيد المراجعة من الإدارة. لن تتمكن من النشر أو استخدام بعض الميزات حتى تتم الموافقة على حسابك.',
              style: TextStyle(
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

  Widget _buildMosqueProfileCard(MosqueModel mosque) {
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
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: mosque.logoUrl.isNotEmpty
                  ? Image.network(
                      mosque.logoUrl,
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
                      if (mosque.isVerified) ...[
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
                              : 'الموقع غير محدد',
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
            const Icon(Icons.chevron_left_rounded, color: Colors.black38),
          ],
        ),
      ),
    );
  }

  Widget _buildActionGrid(bool isPending) {
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
          title: 'نشر إعلان',
          color: const Color(0xFF0F766E),
          disabled: isPending,
          onTap: () {
            // TODO: navigate to create-post screen
          },
        ),
        ActionCard(
          icon: Icons.access_time_filled_rounded,
          title: 'إدارة أوقات الصلاة',
          color: const Color(0xFF2563EB),
          disabled: isPending,
          onTap: () {
            // TODO: navigate to prayer times management screen
          },
        ),
        ActionCard(
          icon: Icons.grid_view_rounded,
          title: 'عرض المنشورات',
          color: const Color(0xFF9333EA),
          onTap: () {
            // TODO: navigate to posts list screen
          },
        ),
        ActionCard(
          icon: Icons.notifications_active_rounded,
          title: 'رسائل وتنبيهات',
          color: const Color(0xFFDB6A26),
          onTap: () {
            // TODO: navigate to messages/notifications screen
          },
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'إحصائيات اليوم',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('mosques')
              .doc(_uid)
              .collection('stats')
              .doc('today')
              .snapshots(),
          builder: (context, snapshot) {
            final data = snapshot.data?.data();
            final views = data?['views'] ?? 0;
            final followers = data?['followers'] ?? 0;
            final notifications = data?['notifications'] ?? 0;

            return Row(
              children: [
                _statTile('مشاهدات', views.toString(),
                    Icons.remove_red_eye_rounded, const Color(0xFF0F766E)),
                const SizedBox(width: 10),
                _statTile('متابعون', followers.toString(),
                    Icons.people_alt_rounded, const Color(0xFF2563EB)),
                const SizedBox(width: 10),
                _statTile('تنبيهات', notifications.toString(),
                    Icons.notifications_rounded, const Color(0xFFDB6A26)),
              ],
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
              color: Colors.black.withOpacity(0.05),
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
