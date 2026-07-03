import 'package:flutter/material.dart';

class ManbarBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const ManbarBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF0F766E),
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded),
          label: 'الرئيسية',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.article_rounded),
          label: 'المنشورات',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.mosque_rounded),
          label: 'الصلاة',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: 'الحساب',
        ),
      ],
    );
  }
}
