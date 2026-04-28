import 'package:flutter/material.dart';

import '../api/api_client.dart';

class AdminOrdersListPage extends StatefulWidget {
  const AdminOrdersListPage({super.key});

  @override
  State<AdminOrdersListPage> createState() => _AdminOrdersListPageState();
}

class _AdminOrdersListPageState extends State<AdminOrdersListPage> {
  final _api = ApiClient();
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
      _rows = await _api.adminOrdersRaw();
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _setStatus(int id, String status) async {
    try {
      await _api.adminOrderSetStatus(id: id, status: status);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All orders'),
        backgroundColor: const Color(0xFF024E44),
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _rows.length,
                  itemBuilder: (context, i) {
                    final o = _rows[i];
                    final id = (o['id'] as num).toInt();
                    final st = (o['status'] ?? '').toString();
                    final buyer = (o['buyer_username'] ?? '').toString();
                    final total = (o['total_php'] ?? '').toString();
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('#$id — $st', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('Buyer: $buyer'),
                            Text('Total: ₱$total'),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                for (final s in ['to_pay', 'to_ship', 'to_receive', 'completed'])
                                  OutlinedButton(
                                    onPressed: () => _setStatus(id, s),
                                    child: Text(s.replaceAll('_', ' ')),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
