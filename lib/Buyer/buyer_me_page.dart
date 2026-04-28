import 'package:flutter/material.dart';
import 'edit_profile_page.dart';
import 'orders_page.dart';
import '../api/api_client.dart';
import '../auth_page.dart';
import '../profile_display_map.dart';
import '../services/app_session.dart';

class BuyerMePage extends StatefulWidget {
  const BuyerMePage({super.key});

  @override
  State<BuyerMePage> createState() => _BuyerMePage();
}

class _BuyerMePage extends State<BuyerMePage> {
  bool _loadingProfile = true;
  String? _profileError;
  late Map<String, String> _profile;

  @override
  void initState() {
    super.initState();
    _profile = mapProfileFallbackSession();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loadingProfile = true;
      _profileError = null;
    });
    try {
      final u = await ApiClient().getProfile();
      await AppSession.applyFromProfileRow(u);
      if (!mounted) return;
      setState(() {
        _profile = mapProfileForUi(u);
        _loadingProfile = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _profileError = e.toString();
        _profile = mapProfileFallbackSession();
        _loadingProfile = false;
      });
    }
  }

  Widget _headerAvatar(String url) {
    if (url.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          url,
          width: 90,
          height: 90,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const CircleAvatar(
            radius: 45,
            backgroundColor: Colors.orange,
            child: Icon(Icons.person, size: 45, color: Colors.white),
          ),
        ),
      );
    }
    return const CircleAvatar(
      radius: 45,
      backgroundColor: Colors.orange,
      child: Icon(Icons.person, size: 45, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    String v(String? s) => (s == null || s.isEmpty) ? '—' : s;

    return Scaffold(
      backgroundColor: const Color(0xFFDCE8D2),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // APP BAR WITH PROFILE
            Container(
              height: 170,
              decoration: BoxDecoration(
                color: const Color(0xFF0F5C4A),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Row(
                children: [
                  _headerAvatar(profile['avatarUrl'] ?? ''),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        profile["name"]!,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        AppSession.userRole != null && AppSession.userRole!.isNotEmpty
                            ? 'Role: ${AppSession.userRole}'
                            : '',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (_profileError != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Could not refresh profile: $_profileError',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            if (_loadingProfile)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Center(child: CircularProgressIndicator()),
              ),

            // MY ORDERS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Material(
                elevation: 3,
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            "My Orders",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF024E44),
                            ),
                          ),
                          Text("View All →", style: TextStyle(fontSize: 12))
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          OrderIcon(
                            Icons.payment,
                            "To Pay",
                            Colors.orangeAccent,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ToPayPage(),
                                ),
                              );
                            },
                          ),
                          OrderIcon(
                            Icons.local_shipping,
                            "To Ship",
                            Colors.lightBlue,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ToShipPage(),
                                ),
                              );
                            },
                          ),
                          OrderIcon(
                            Icons.inventory,
                            "To Receive",
                            Colors.green,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ToReceivePage(),
                                ),
                              );
                            },
                          ),
                          OrderIcon(
                            Icons.list_alt,
                            "Completed",
                            Colors.grey,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CompletedPage(),
                                ),
                              );
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // PROFILE INFO
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Material(
                elevation: 3,
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "My Profile",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF024E44),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Divider(),
                      const SizedBox(height: 10),
                      ProfileRow("Username:", v(profile["username"])),
                      ProfileRow("Name:", v(profile["name"])),
                      ProfileRow("Business Type:", v(profile["businessType"])),
                      ProfileRow("Email:", v(profile["email"])),
                      ProfileRow("Address:", v(profile["address"])),
                      ProfileRow("Phone Number:", v(profile["phone"])),
                      ProfileRow("Gender:", v(profile["gender"])),
                      ProfileRow("Date of Birth:", v(profile["birth"])),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // EDIT PROFILE BUTTON
            SizedBox(
              width: 200,
              child: OutlinedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfilePage(profile: profile),
                    ),
                  );
                  await _loadProfile();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF024E44),
                  side: const BorderSide(color: Color(0xFF024E44)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 3,
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text("Edit Profile"),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // LOG OUT BUTTON
            SizedBox(
              width: 200,
              child: OutlinedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Confirm Log Out"),
                      content: const Text("Are you sure you want to log out?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await AppSession.clearAll();
                            if (!context.mounted) return;
                            Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const AuthPage()),
                              (_) => false,
                            );
                          },
                          child: const Text(
                            "Log Out",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 3,
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text("Log Out"),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class OrderIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const OrderIcon(this.icon, this.label, this.color, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            radius: 20,
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 12))
        ],
      ),
    );
  }
}

class ProfileRow extends StatelessWidget {
  final String title;
  final String value;

  const ProfileRow(this.title, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}