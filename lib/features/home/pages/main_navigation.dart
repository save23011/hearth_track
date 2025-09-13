import 'package:flutter/material.dart';
import 'widgets/custom_bottom_nav_bar.dart';
import '../../dashboard/pages/dashboard_screen.dart';
import '../../questionnaire/pages/questionnaire_list_screen.dart';
import '../../exercise/pages/exercise_screen.dart';
import '../../journal/pages/journal_screen.dart';
import '../../profile/pages/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const QuestionnaireListScreen(),
    const ExerciseScreen(),
    const JournalScreen(),
    const ProfileScreen(),
  ];

  final List<BottomNavItem> _navItems = [
    BottomNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
    ),
    BottomNavItem(
      icon: Icons.quiz_outlined,
      activeIcon: Icons.quiz,
      label: 'Assess',
    ),
    BottomNavItem(
      icon: Icons.fitness_center_outlined,
      activeIcon: Icons.fitness_center,
      label: 'Exercise',
    ),
    BottomNavItem(
      icon: Icons.book_outlined,
      activeIcon: Icons.book,
      label: 'Journal',
    ),
    BottomNavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        items: _navItems,
        onTap: _onTabTapped,
      ),
    );
  }
}

class BottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
