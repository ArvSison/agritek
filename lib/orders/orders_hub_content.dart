import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/models.dart';

/// Order list + status actions for buyer or farmer.
class OrdersHubContent extends StatefulWidget {
  final String role; // buyer | farmer

  const OrdersHubContent({super.key, required this.role});

  @override
  State<OrdersHubContent> createState() => _OrdersHubContentState();
}

class _OrdersHubContentState extends State<OrdersHubContent> {
  final _api = ApiClient();
  bool _loading = true;
  String? _error;
  List<ApiOrder> _orders = [];
  String _filter = 'all';

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
      final list = await _api.ordersMine();
      setState(() => _orders = list);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  List<ApiOrder> get _filtered {
    if (_filter == 'all') return _orders;
    return _orders.where((o) => o.status == _filter).toList();
  }

  Future<void> _act(ApiOrder o, String action) async {
    try {
      await _api.orderAction(id: o.id, action: action);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
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

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              for (final f in ['all', 'to_pay', 'to_ship', 'to_receive', 'completed'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f == 'all' ? 'All' : f.replaceAll('_', ' ')),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: _filtered.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 80),
                      Center(child: Text('No orders in this filter')),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _filtered.length,
                    itemBuilder: (context, i) {
                      final o = _filtered[i];
                      final items = o.items.map((it) => (it['name'] ?? '').toString()).join(', ');
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('#${o.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const Spacer(),
                                  Chip(label: Text(o.status)),
                                ],
                              ),
                              Text('Total: ₱${o.totalPhp}', style: const TextStyle(color: Colors.green)),
                              if (o.buyerUsername != null) Text('Buyer: ${o.buyerUsername}'),
                              const SizedBox(height: 6),
                              Text(items, style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                children: [
                                  if (widget.role == 'buyer' && o.status == 'to_pay')
                                    ElevatedButton(onPressed: () => _act(o, 'pay'), child: const Text('Pay')),
                                  if (widget.role == 'farmer' && o.status == 'to_ship')
                                    ElevatedButton(onPressed: () => _act(o, 'ship'), child: const Text('Ship')),
                                  if (widget.role == 'buyer' && o.status == 'to_receive')
                                    ElevatedButton(onPressed: () => _act(o, 'receive'), child: const Text('Received')),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
