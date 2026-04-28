import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/models.dart';

// ======= REUSABLE ORDER PAGE TEMPLATE =======
class OrderPage extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final String status; // to_pay | to_ship | to_receive | completed

  const OrderPage({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.status,
    super.key,
  });

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final ApiClient _api = ApiClient();
  bool _loading = true;
  String? _error;
  List<ApiOrder> _orders = [];

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
      final orders = await _api.ordersMine(); // farmer-scoped on server
      if (!mounted) return;
      setState(() => _orders = orders);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<ApiOrder> get _filtered => _orders.where((o) => o.status == widget.status).toList();

  String _itemsLabel(ApiOrder o) {
    final names = o.items.map((it) => (it['name'] ?? '').toString()).where((s) => s.isNotEmpty).toList();
    if (names.isEmpty) return '${o.items.length} item(s)';
    final head = names.take(2).join(', ');
    final more = names.length > 2 ? ' +${names.length - 2} more' : '';
    return head + more;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDCE8D2),
      body: Column(
        children: [
          // HEADER
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
                CircleAvatar(
                  radius: 35,
                  backgroundColor: widget.iconColor,
                  child: Icon(widget.icon, size: 35, color: Colors.white),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _loading
                          ? 'Loading…'
                          : (_error != null ? 'Could not load orders' : 'You have ${_filtered.length} orders'),
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                )
              ],
            ),
          ),

          const SizedBox(height: 20),

          // PAGE CONTENT
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: _loading
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
                      : _filtered.isEmpty
                          ? const Center(child: Text('No orders here yet.'))
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                itemCount: _filtered.length,
                                itemBuilder: (context, index) {
                                  final o = _filtered[index];
                                  final buyer = (o.buyerUsername ?? '').isNotEmpty ? 'Buyer: ${o.buyerUsername}' : '';
                                  return Card(
                                    child: ListTile(
                                      title: Text('Order #${o.id}'),
                                      subtitle: Text(
                                        [buyer, _itemsLabel(o), 'Total: ${o.totalPhp}'].where((s) => s.isNotEmpty).join('\n'),
                                      ),
                                      isThreeLine: true,
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ),
        ],
      ),
    );
  }
}

// ======= INDIVIDUAL ORDER PAGES =======
class ToPayPage extends StatelessWidget {
  const ToPayPage({super.key});
  @override
  Widget build(BuildContext context) => const OrderPage(
    title: "To Pay Orders",
    icon: Icons.payment,
    iconColor: Colors.orangeAccent,
    status: "to_pay",
  );
}

class ToShipPage extends StatelessWidget {
  const ToShipPage({super.key});
  @override
  Widget build(BuildContext context) => const OrderPage(
    title: "To Ship Orders",
    icon: Icons.local_shipping,
    iconColor: Colors.lightBlue,
    status: "to_ship",
  );
}

class ToReceivePage extends StatelessWidget {
  const ToReceivePage({super.key});
  @override
  Widget build(BuildContext context) => const OrderPage(
    title: "To Receive Orders",
    icon: Icons.inventory,
    iconColor: Colors.green,
    status: "to_receive",
  );
}

class CompletedPage extends StatelessWidget {
  const CompletedPage({super.key});
  @override
  Widget build(BuildContext context) => const OrderPage(
    title: "Completed Orders",
    icon: Icons.list_alt,
    iconColor: Colors.grey,
    status: "completed",
  );
}