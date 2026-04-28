import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../Buyer/buyer_chat_page.dart';
import '../Farmer/farmer_chat_page.dart';

/// Lists farmers (for buyers) or buyers (for farmers) from API.
class PeopleDiscoveryTab extends StatefulWidget {
  /// `farmer` when the logged-in user is a buyer; `buyer` when logged-in user is a farmer.
  final String listRole;

  const PeopleDiscoveryTab({super.key, required this.listRole});

  @override
  State<PeopleDiscoveryTab> createState() => _PeopleDiscoveryTabState();
}

class _PeopleDiscoveryTabState extends State<PeopleDiscoveryTab> {
  final _api = ApiClient();
  final _search = TextEditingController();
  bool _loading = true;
  String? _error;
  List<ApiPublicUser> _users = [];
  Set<int> _followingIds = {};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

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
      final u = await _api.usersDiscovery(widget.listRole);
      final following = await _api.followingList();
      if (!mounted) return;
      setState(() {
        _users = u;
        _followingIds = following.map((e) => e.id).toSet();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
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
      );
    }

    final q = _search.text.toLowerCase();
    final filtered = _users.where((u) => u.username.toLowerCase().contains(q)).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: widget.listRole == 'farmer' ? 'Search farmers' : 'Search buyers',
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: filtered.length,
            itemBuilder: (context, i) {
              final u = filtered[i];
              final isFarmerList = widget.listRole == 'farmer';
              final isFollowing = _followingIds.contains(u.id);
              final display = u.fullName;
              return Card(
                child: ListTile(
                  title: Text(display),
                  subtitle: Text(u.role),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () async {
                          try {
                            if (isFollowing) {
                              await _api.unfollowUser(u.id);
                              if (!context.mounted) return;
                              setState(() => _followingIds.remove(u.id));
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unfollowed ${u.username}')));
                              return;
                            }
                            await _api.followUser(u.id);
                            if (!context.mounted) return;
                            setState(() => _followingIds.add(u.id));
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Followed $display')));
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                          }
                        },
                        child: Text(
                          isFollowing ? 'Following' : 'Follow',
                          style: TextStyle(color: isFollowing ? Colors.grey[700] : Colors.green),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF024E44)),
                        onPressed: () {
                          if (isFarmerList) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BuyerChatPage(contactName: display, peerUserId: u.id),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FarmerChatPage(contactName: display, peerUserId: u.id),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
