import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import 'buyer_chat_page.dart';

class BuyerFollowingPage extends StatefulWidget {
  const BuyerFollowingPage({super.key});

  @override
  State<BuyerFollowingPage> createState() => _BuyerFollowingPageState();
}

class _BuyerFollowingPageState extends State<BuyerFollowingPage> {
  final ApiClient _api = ApiClient();
  bool _loading = true;
  String? _error;
  List<ApiPublicUser> _items = [];

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
      final list = await _api.followingList();
      if (!mounted) return;
      setState(() => _items = list.where((u) => u.role == 'farmer').toList());
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _unfollow(ApiPublicUser u) async {
    try {
      await _api.unfollowUser(u.id);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unfollowed ${u.username}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FFE2),
      appBar: AppBar(
        title: const Text('Following'),
        backgroundColor: const Color(0xFF024E44),
        foregroundColor: const Color(0xFFF0FFE2),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _items.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 80),
                            Center(child: Text('You are not following any farmers yet.')),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _items.length,
                          itemBuilder: (context, i) {
                            final u = _items[i];
                            final display = u.fullName;
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(child: Text(u.username.isNotEmpty ? u.username[0].toUpperCase() : '?')),
                                title: Text(display),
                                subtitle: Text(u.role),
                                trailing: TextButton(
                                  onPressed: () => _unfollow(u),
                                  child: const Text('Unfollow', style: TextStyle(color: Colors.red)),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BuyerChatPage(contactName: display, peerUserId: u.id),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}

