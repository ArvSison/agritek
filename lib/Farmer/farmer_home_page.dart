import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../services/app_session.dart';
import 'add_product_page.dart';
import 'Fproduct_detail_page.dart';

class FarmerHomePage extends StatefulWidget {
  const FarmerHomePage({super.key});

  @override
  State<FarmerHomePage> createState() => _FarmerHomePageState();
}

class _FarmerHomePageState extends State<FarmerHomePage> {
  final ApiClient _api = ApiClient();
  bool _loading = true;
  String? _error;
  List<Map<String, String>> products = [];

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
      final list = await _api.farmerMyProducts();
      setState(() {
        products = list.map((p) => p.toLegacyMapForUi()).toList();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double paddingSize = screenWidth * 0.04;

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
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: paddingSize),
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
              ),
            ),
          ),
          const SizedBox(height: 10),
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
                              Text(_error!, textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              ElevatedButton(onPressed: _load, child: const Text('Retry')),
                            ],
                          ),
                        ),
                      )
                    : Padding(
                        padding: EdgeInsets.all(paddingSize),
                        child: GridView.builder(
                          itemCount: products.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 15,
                            crossAxisSpacing: 15,
                            childAspectRatio: 0.72,
                          ),
                          itemBuilder: (context, index) {
                            return _buildProductCard(products[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 65),
        child: FloatingActionButton(
          backgroundColor: const Color(0xFF024E44),
          child: const Icon(
            Icons.add,
            color: Colors.white,
          ),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AddProductPage(),
              ),
            );
            _load();
          },
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, String> product) {
    return InkWell(
      onTap: () async {
        // Filter out the current product for "More from this Farmer"
        List<Map<String, String>> otherProducts =
        products.where((p) => p != product).toList();

        final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsPage(
              product: {
                ...product,
                'harvest': product['harvestDate'] ?? 'N/A',
                'description': product['description'] ?? '',
                'weight': product['weight'] ?? '',
              },
              farmerProducts: otherProducts, // pass the rest
            ),
          ),
        );
        if (changed == true) {
          _load();
        }
      },
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
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product['price']!,
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
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
                    Text(
                      product['productStatus'] ?? '',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
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