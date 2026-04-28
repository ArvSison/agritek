import 'package:flutter/material.dart';
import 'admin_home_page.dart';
import 'admin_messages_page.dart';
import 'All_List_page.dart';
import 'admin_notifications_page.dart';
import 'admin_me_page.dart';
import '../api/api_client.dart';
import '../widgets/notification_badge_icon.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _currentIndex = 0;
  int _unreadNotifs = 0;
  final ApiClient _api = ApiClient();

  final List<Widget> _pages = [
    const AdminHomePage(),
    const AdminMessagesPage(),
    const AllListPage(),
    const AdminNotificationsPage(),
    const AdminMePage(),
  ];

  @override
  void initState() {
    super.initState();
    _refreshUnread();
  }

  Future<void> _refreshUnread() async {
    try {
      final list = await _api.adminNotifications();
      final unread = list.where((n) => n.readAt == null || n.readAt!.isEmpty).length;
      if (!mounted) return;
      setState(() => _unreadNotifs = unread);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _pages[_currentIndex],

      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF024E44),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          currentIndex: _currentIndex,
          showUnselectedLabels: true,

          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: "Home",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.message),
              label: "Messages",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: "All Users",
            ),
            BottomNavigationBarItem(
              icon: NotificationBadgeIcon(icon: Icons.notifications, unreadCount: _unreadNotifs),
              label: "Notifications",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: "Me",
            ),
          ],

          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            if (index == 3) {
              _refreshUnread();
            }
          },
        ),
      ),
    );
  }
}