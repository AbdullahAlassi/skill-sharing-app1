import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../models/skill_model.dart';
import '../../providers/user_provider.dart';
import '../../services/event_service.dart';
import '../../services/skill_service.dart';
import '../../theme/app_theme.dart';
import 'package:frontend/widget/event_card.dart';
import 'package:frontend/widget/skill_card.dart';
import '../skills/skill_detail_screen.dart';
import 'dashboard_screen.dart';
import '../profile/profile_screen.dart';
import '../skills/skills_screen.dart';
import '../events/events_screen.dart';
import '../../utils/token_storage.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const DashboardScreen(),
    const SkillsScreen(),
    const EventsScreen(),
    const ProfileScreen(),
  ];

  Future<void> _handleLogout() async {
    // Clear the token
    await TokenStorage.clearToken();

    // Navigate to login screen
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skill Sharing App'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout();
              }
            },
            itemBuilder:
                (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Skills'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
