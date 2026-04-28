import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/api_client.dart';
import '../api/models.dart';

class BuyerNotificationsPage extends StatefulWidget {
  const BuyerNotificationsPage({super.key});

  @override
  State<BuyerNotificationsPage> createState() => _BuyerNotificationsPageState();
}

class _BuyerNotificationsPageState extends State<BuyerNotificationsPage> {
  final ApiClient _api = ApiClient();
  bool _loading = true;
  String? _error;
  List<ApiNotification> _items = [];

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
      _items = await _api.notificationsMine();
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _loading = false);
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
            padding: const EdgeInsets.only(top: 40, left: 20, right: 20, bottom: 25),
            decoration: BoxDecoration(
              color: const Color(0xFF024E44),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(25)),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
              ],
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Notifications',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
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
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final n = _items[index];
                            final unread = n.readAt == null || n.readAt!.isEmpty;
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(1, 3)),
                                ],
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: unread ? Colors.green : Colors.grey,
                                  child: const Icon(Icons.notifications, color: Colors.white),
                                ),
                                title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(n.body ?? ''),
                                trailing: unread
                                    ? TextButton(
                                        onPressed: () async {
                                          await _api.notificationMarkRead(n.id);
                                          await _load();
                                        },
                                        child: const Text('Read'),
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
