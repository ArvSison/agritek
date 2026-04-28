import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/api_client.dart';
import 'user_profile_page.dart';

class AllListPage extends StatefulWidget {
  const AllListPage({super.key});

  @override
  State<AllListPage> createState() => _AllListPageState();
}

class _AllListPageState extends State<AllListPage> {
  final TextEditingController _searchController = TextEditingController();
  final ApiClient _api = ApiClient();
  String _searchQuery = '';
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _users = await _api.adminUsers();
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _approve(int id) async {
    try {
      await _api.adminUserApprove(id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _reject(int id) async {
    try {
      await _api.adminUserReject(id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _delete(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete user?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _api.adminUserDelete(id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _message(int userId) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Message user'),
        content: TextField(controller: ctrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Message')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send')),
        ],
      ),
    );
    if (ok != true) return;
    final body = ctrl.text.trim();
    if (body.isEmpty) return;
    try {
      await _api.adminSendMessage(toUserId: userId, body: body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message sent')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _searchQuery.toLowerCase();
    final filtered = _users.where((u) {
      final name = (u['username'] ?? '').toString().toLowerCase();
      final role = (u['role'] ?? '').toString().toLowerCase();
      return name.contains(q) || role.contains(q);
    }).toList();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF024E44),
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFF0FFE2),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 40, left: 20, right: 20, bottom: 25),
            decoration: const BoxDecoration(
              color: Color(0xFF024E44),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 55,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: const InputDecoration(
                        hintText: 'Search users',
                        prefixIcon: Icon(Icons.search),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _loading ? null : _load,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final u = filtered[index];
                          final id = (u['id'] as num).toInt();
                          final username = (u['username'] ?? '').toString();
                          final role = (u['role'] ?? '').toString();
                          final status = (u['status'] ?? '').toString();
                          final email = (u['email'] ?? '').toString();
                          final displayName = (u['display_name'] ?? '').toString();
                          final address = (u['address'] ?? '').toString();
                          final phone = (u['phone'] ?? '').toString();
                          final gender = (u['gender'] ?? '').toString();
                          final birth = (u['birth_date'] ?? '').toString();
                          final fullName = displayName.isNotEmpty ? displayName : username;
                          return Card(
                            child: ListTile(
                              title: Text(fullName),
                              subtitle: Text('@$username\n$role • $status\n$email'),
                              isThreeLine: true,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => UserProfilePage(
                                      profile: {
                                        'name': displayName.isNotEmpty ? displayName : username,
                                        'businessType': role,
                                        'username': username,
                                        'email': email,
                                        'address': address,
                                        'phone': phone,
                                        'gender': gender,
                                        'birth': birth,
                                        'id': id.toString(),
                                      },
                                    ),
                                  ),
                                );
                              },
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'approve') _approve(id);
                                  if (v == 'reject') _reject(id);
                                  if (v == 'delete') _delete(id);
                                  if (v == 'msg') _message(id);
                                },
                                itemBuilder: (_) => [
                                  if (status == 'pending') const PopupMenuItem(value: 'approve', child: Text('Approve')),
                                  if (status == 'pending') const PopupMenuItem(value: 'reject', child: Text('Reject')),
                                  const PopupMenuItem(value: 'msg', child: Text('Message')),
                                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                ],
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
