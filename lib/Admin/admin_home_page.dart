import 'package:flutter/material.dart';

import '../api/api_client.dart';
import 'admin_orders_list_page.dart';
import 'Aproduct_details_page.dart' as admin_details;

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final ApiClient _api = ApiClient();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _products = [];

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
      _products = await _api.adminProductsRaw();
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _loading = false);
    }
  }

  Map<String, String> _displayRow(Map<String, dynamic> r) {
    final price = r['price_php'];
    final unit = (r['unit'] ?? 'kg').toString();
    final p = price is num ? price.toDouble() : double.tryParse(price.toString()) ?? 0;
    final fmt = p.toStringAsFixed(2);
    final stock = r['stock_kg'];
    final stockNum = stock is num ? stock.toDouble() : double.tryParse(stock?.toString() ?? '');
    final stockOut = stockNum == null ? '' : stockNum.toString();
    return {
      'name': (r['name'] ?? '').toString(),
      'price': '₱$fmt/$unit',
      // Details pages use legacy keys: harvest + weight.
      'harvest': (r['harvest_date'] ?? '').toString(),
      'image': (r['image_url'] ?? '').toString(),
      'status': (r['status'] ?? '').toString(),
      'id': (r['id'] ?? '').toString(),
      if (stockOut.isNotEmpty) 'weight': stockOut,
      if ((r['description'] ?? '').toString().isNotEmpty) 'description': (r['description'] ?? '').toString(),
      if ((r['farmer_name'] ?? '').toString().isNotEmpty) 'farmerName': (r['farmer_name'] ?? '').toString(),
      if ((r['farmer_location'] ?? '').toString().isNotEmpty) 'farmerLocation': (r['farmer_location'] ?? '').toString(),
    };
  }

  Future<void> _action(int id, String action) async {
    try {
      await _api.adminProductAction(id: id, action: action);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _openActions(Map<String, dynamic> raw) {
    final id = (raw['id'] as num).toInt();
    final st = (raw['status'] ?? '').toString();
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text('Product #$id ($st)')),
            if (st == 'pending') ...[
              ListTile(
                leading: const Icon(Icons.check),
                title: const Text('Approve'),
                onTap: () {
                  Navigator.pop(ctx);
                  _action(id, 'approve');
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Reject'),
                onTap: () {
                  Navigator.pop(ctx);
                  _action(id, 'reject');
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(ctx);
                _action(id, 'delete');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FFE2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0FFE2),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: const Padding(
          padding: EdgeInsets.all(6),
          child: CircleAvatar(
            radius: 18,
            backgroundImage: AssetImage('logos/area51.jpg'),
            backgroundColor: Colors.transparent,
          ),
        ),
        title: const Text(
          'Admin — Products',
          style: TextStyle(
            color: Color(0xFF024E44),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Orders',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminOrdersListPage()),
              );
            },
            icon: const Icon(Icons.receipt_long, color: Color(0xFF024E44)),
          ),
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh, color: Color(0xFF024E44)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Material(
                elevation: 3,
                borderRadius: BorderRadius.circular(15),
                child: TextField(
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: 'Tap a product for approve / reject / delete',
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: const Icon(Icons.info_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!)))
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: GridView.builder(
                            itemCount: _products.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.72,
                            ),
                            itemBuilder: (context, index) {
                              final raw = _products[index];
                              final product = _displayRow(raw);
                              return InkWell(
                                onTap: () {
                                  Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => admin_details.ProductDetailsPage(product: product),
                                    ),
                                  ).then((deleted) {
                                    if (deleted == true) _load();
                                  });
                                },
                                onLongPress: () => _openActions(raw),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDDEACF),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                          child: Image.network(
                                            product['image']!,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return const Center(child: CircularProgressIndicator());
                                            },
                                            errorBuilder: (context, error, stackTrace) {
                                              return const Center(child: Icon(Icons.broken_image, size: 40));
                                            },
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 4,
                                        child: Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                product['name']!,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: Color(0xFF024E44),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                product['price']!,
                                                style: const TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                product['status']!,
                                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                              const Spacer(),
                                              const Row(
                                                children: [
                                                  Icon(Icons.touch_app, size: 14, color: Color(0xFF024E44)),
                                                  SizedBox(width: 4),
                                                  Text('Actions', style: TextStyle(fontSize: 10)),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
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
        ),
      ),
    );
  }
}
