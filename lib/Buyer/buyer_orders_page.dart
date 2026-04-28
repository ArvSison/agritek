import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../orders/orders_hub_content.dart';
import '../orders/people_discovery_tab.dart';
import 'buyer_following_page.dart';

/// Bottom tab: Farmers directory + Orders (keeps class name `BuyerListPage` for existing imports).
class BuyerListPage extends StatefulWidget {
  const BuyerListPage({super.key});

  @override
  State<BuyerListPage> createState() => _BuyerListPageState();
}

class _BuyerListPageState extends State<BuyerListPage> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF024E44),
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFF0FFE2),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 36, left: 12, right: 12, bottom: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF024E44),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TabBar(
                    controller: _tabs,
                    indicatorColor: const Color(0xFFF0FFE2),
                    labelColor: const Color(0xFFF0FFE2),
                    unselectedLabelColor: Colors.white70,
                    tabs: const [
                      Tab(text: 'Farmers'),
                      Tab(text: 'Orders'),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Following',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BuyerFollowingPage()),
                    );
                  },
                  icon: const Icon(Icons.person_pin_circle, color: Color(0xFFF0FFE2)),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: const [
                PeopleDiscoveryTab(listRole: 'farmer'),
                OrdersHubContent(role: 'buyer'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
