import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';

class ManbarBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// When true, an extra "لوحة الإدارة" tab is appended at the end.
  final bool showAdmin;

  const ManbarBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.showAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = <BottomNavigationBarItem>[
      BottomNavigationBarItem(
        icon: const Icon(Icons.home_rounded),
        label: l10n.navHome,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.article_rounded),
        label: l10n.navPosts,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.mosque_rounded),
        label: l10n.navPrayer,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.person_rounded),
        label: l10n.navProfile,
      ),
      if (showAdmin)
        BottomNavigationBarItem(
          icon: const Icon(Icons.admin_panel_settings_rounded),
          label: l10n.navAdmin,
        ),
    ];

    return BottomNavigationBar(
      currentIndex: currentIndex.clamp(0, items.length - 1),
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF0F766E),
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      items: items,
    );
  }
}
