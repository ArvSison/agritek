import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/api_client.dart';
import 'buyer_chat_page.dart';

class BuyerMessagesPage extends StatefulWidget {
  const BuyerMessagesPage({super.key});

  @override
  State<BuyerMessagesPage> createState() => _BuyerMessagesPageState();
}

class _BuyerMessagesPageState extends State<BuyerMessagesPage> {
  final ApiClient _api = ApiClient();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _api.messageConversations();
      if (mounted) setState(() => _rows = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
            padding: const EdgeInsets.only(
              top: 40,
              left: 20,
              right: 20,
              bottom: 25,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF024E44),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Messages',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Material(
                  elevation: 3,
                  borderRadius: BorderRadius.circular(25),
                  child: TextField(
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search messages',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.redAccent),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _load,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _rows.isEmpty
                        ? const Center(child: Text('No conversations yet.'))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: _rows.length,
                            itemBuilder: (context, index) {
                              final row = _rows[index];
                              final username = (row['username'] ?? 'User').toString();
                              final fullName = (row['display_name'] ?? '').toString();
                              final name = fullName.isNotEmpty ? fullName : username;
                              final role = (row['role'] ?? '').toString();
                              final lastAt = (row['last_at'] ?? '').toString();
                              final peerId = int.tryParse(row['id']?.toString() ?? '') ?? 0;
                              final avatarColor =
                                  index % 2 == 0 ? Colors.green.shade300 : Colors.green.shade200;
                              final initial =
                                  name.isNotEmpty ? name[0].toUpperCase() : '?';

                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 3,
                                  shadowColor: Colors.black26,
                                  color: Colors.white,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    leading: CircleAvatar(
                                      backgroundColor: avatarColor,
                                      child: Text(
                                        initial,
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    title: Text(
                                      name,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      [if (username.isNotEmpty) '@$username', if (role.isNotEmpty) role, if (lastAt.isNotEmpty) lastAt]
                                          .join(' · '),
                                    ),
                                    trailing: const Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey,
                                    ),
                                    onTap: () {
                                      if (peerId <= 0) return;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => BuyerChatPage(
                                            contactName: name,
                                            peerUserId: peerId,
                                          ),
                                        ),
                                      ).then((_) => _load());
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
