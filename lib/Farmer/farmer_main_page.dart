import 'package:flutter/material.dart';
import 'farmer_home_page.dart';
import 'farmer_messages_page.dart';
import 'farmer_orders_page.dart';
import 'farmer_notifications_page.dart';
import 'farmer_me_page.dart';
import '../api/api_client.dart';
import '../widgets/notification_badge_icon.dart';

class FarmerMainPage extends StatefulWidget {
  const FarmerMainPage({super.key});

  @override
  State<FarmerMainPage> createState() => _FarmerMainPageState();
}

class _FarmerMainPageState extends State<FarmerMainPage> {
  int _currentIndex = 0;
  int _unreadNotifs = 0;
  final ApiClient _api = ApiClient();

  final List<Widget> _pages = [
    const FarmerHomePage(),
    const FarmerMessagesPage(),
    const BuyerListPage(),
    const FarmerNotificationsPage(),
    const FarmerMePage(),
  ];

  @override
  void initState() {
    super.initState();
    _refreshUnread();
  }

  Future<void> _refreshUnread() async {
    try {
      final list = await _api.notificationsMine();
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
              icon: Icon(Icons.groups),
              label: "Buyers",
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