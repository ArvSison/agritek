import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../services/app_session.dart';
import 'cart_page.dart';
import 'Bproduct_details_page.dart';

class BuyerHomePage extends StatefulWidget {
  const BuyerHomePage({super.key});

  @override
  State<BuyerHomePage> createState() => _BuyerHomePage();
}

class _BuyerHomePage extends State<BuyerHomePage> {
  final ApiClient _api = ApiClient();
  bool _loading = true;
  String? _error;
  List<Map<String, String>> products = [];
  bool _followingOnly = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = _followingOnly
          ? await _api.productsFeed(mode: 'following')
          : await _api.productsFeed(mode: 'all');
      setState(() {
        products = list.map((p) => p.toLegacyMapForUi()).toList();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FFE2),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF0FFE2),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.all(6),
          child: CircleAvatar(
            radius: 18,
            backgroundImage: const AssetImage('logos/area51.jpg'),
            backgroundColor: Colors.transparent,
          ),
        ),
        title: Text(
          () {
            final n = AppSession.username;
            if (n != null && n.isNotEmpty) return 'Welcome, $n';
            return 'Welcome';
          }(),
          style: const TextStyle(
            color: Color(0xFF024E44),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Color(0xFF024E44)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartPage()),
              );
            },
          ),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: true, label: Text('Following')),
                        ButtonSegment(value: false, label: Text('All')),
                      ],
                      selected: {_followingOnly},
                      onSelectionChanged: (v) async {
                        final next = v.first;
                        if (next == _followingOnly) return;
                        setState(() => _followingOnly = next);
                        await _loadProducts();
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            /// SEARCH BAR (UI only for now)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Material(
                elevation: 3,
                borderRadius: BorderRadius.circular(15),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Expanded(
                child: Center(
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
                          onPressed: _loadProducts,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              /// PRODUCT GRID
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: products.isEmpty
                      ? Center(
                          child: Text(
                            _followingOnly
                                ? 'No products from followed farmers yet.\nFollow a farmer to see their products here.'
                                : 'No products yet.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : GridView.builder(
                          itemCount: products.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.72,
                          ),
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return _buildProductCard(product);
                          },
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// PRODUCT CARD
  Widget _buildProductCard(Map<String, String> product) {
    return InkWell(
      onTap: () {
        final fid = product['farmerId'];
        final related = products.where((p) {
          if (fid == null || fid.isEmpty) return false;
          return p['farmerId'] == fid && p['id'] != product['id'];
        }).toList();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsPage(
              product: {
                ...product,
                'harvest': product['harvestDate'] ?? 'N/A',
                'description': product['description'] ?? '',
                'weight': product['weight'] ?? '',
              },
              farmerProducts: related.isEmpty ? null : related,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFDDEACF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            /// IMAGE
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
                child: (product['image'] ?? '').isEmpty
                    ? const Center(child: Icon(Icons.image_not_supported, size: 40))
                    : Image.network(
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

            /// PRODUCT INFO
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
                    const SizedBox(height: 4),
                    Text(
                      product['price']!,
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Harvest Date',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      product['harvestDate'] ?? 'N/A',
                      style: const TextStyle(fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}