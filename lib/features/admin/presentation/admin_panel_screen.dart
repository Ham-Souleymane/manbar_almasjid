import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../data/admin_repository.dart';
import 'all_mosques_screen.dart';
import 'all_posts_screen.dart';
import 'pending_imams_screen.dart';
import 'reports_screen.dart';
import 'suggestions_screen.dart';
import '../../forum/presentation/admin_manage_groups_screen.dart';

class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    PendingImamsScreen(),
    ReportsScreen(),
    SuggestionsScreen(),
    AllMosquesScreen(),
    AllPostsScreen(),
    AdminManageGroupsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider).asData?.value ?? false;
    final l10n = context.l10n;

    if (!isAdmin) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_rounded, size: 72, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                l10n.restrictedAccess,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.restrictedMessage,
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          l10n.adminPanel,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: l10n.logout,
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _StatsRow(),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0F766E),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.pending_actions_rounded),
            label: l10n.pendingImams,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.flag_rounded),
            label: l10n.reports,
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_rounded),
            label: 'الاقتراحات',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.mosque_rounded),
            label: l10n.mosques,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.article_rounded),
            label: l10n.posts,
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.forum_rounded),
            label: 'الملتقيات',
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(adminStatsProvider);
    final l10n = context.l10n;

    return Container(
      color: const Color(0xFF0F766E),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: stats.when(
        loading: () => const SizedBox(
          height: 60,
          child: Center(
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
        ),
        error: (_, __) => const SizedBox.shrink(),
        data: (s) => Row(
          children: [
            _StatChip(
                label: l10n.awaitingReview,
                value: s['pendingImams'] ?? 0,
                icon: Icons.pending_rounded,
                urgent: (s['pendingImams'] ?? 0) > 0),
            _StatChip(
                label: l10n.openReports,
                value: s['openReports'] ?? 0,
                icon: Icons.flag_rounded,
                urgent: (s['openReports'] ?? 0) > 0),
            _StatChip(
                label: 'الاقتراحات',
                value: s['pendingSuggestions'] ?? 0,
                icon: Icons.lightbulb_rounded,
                urgent: (s['pendingSuggestions'] ?? 0) > 0),
            _StatChip(
                label: l10n.totalMosques,
                value: s['totalMosques'] ?? 0,
                icon: Icons.mosque_rounded),
            _StatChip(
                label: l10n.totalPosts,
                value: s['totalPosts'] ?? 0,
                icon: Icons.article_rounded),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final bool urgent;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    this.urgent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: urgent ? Colors.orange.shade700 : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(height: 4),
            Text(
              '$value',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 9),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
