import 'package:flutter/material.dart';
import 'buyer_chat_page.dart';
import 'checkout_page.dart';
import '../api/api_client.dart';

class ProductDetailsPage extends StatefulWidget {
  final Map<String, String> product;
  final List<Map<String, String>>? farmerProducts;

  const ProductDetailsPage({
    super.key,
    required this.product,
    this.farmerProducts,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  bool _followLoading = false;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _loadFollowing();
  }

  Future<void> _loadFollowing() async {
    final fid = int.tryParse(widget.product['farmerId'] ?? '') ?? 0;
    if (fid <= 0) return;
    try {
      final list = await ApiClient().followingList();
      final yes = list.any((u) => u.id == fid);
      if (!mounted) return;
      setState(() => _isFollowing = yes);
    } catch (_) {}
  }

  Future<void> _toggleFollow() async {
    final fid = int.tryParse(widget.product['farmerId'] ?? '') ?? 0;
    if (fid <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Farmer not linked to this product')),
      );
      return;
    }
    if (_followLoading) return;
    setState(() => _followLoading = true);
    try {
      if (_isFollowing) {
        await ApiClient().unfollowUser(fid);
        if (!mounted) return;
        setState(() => _isFollowing = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unfollowed farmer')));
      } else {
        await ApiClient().followUser(fid);
        if (!mounted) return;
        setState(() => _isFollowing = true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Followed farmer')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _followLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      /// ✅ BOTTOM BAR
      bottomNavigationBar: Container(
        height: 65,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: const BoxDecoration(
          color: Color(0xFF024E44),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _bottomItem(
              context,
              icon: Icons.shopping_cart,
              label: "Add to Cart",
              onTap: () async {
                final id = int.tryParse(product['id'] ?? '') ?? 0;
                if (id <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Missing product id')),
                  );
                  return;
                }
                try {
                  await ApiClient().cartAdd(productId: id, qty: 1);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Added to cart')),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightGreen,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              onPressed: () async {
                final id = int.tryParse(product['id'] ?? '') ?? 0;
                if (id <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Missing product id')),
                  );
                  return;
                }
                try {
                  await ApiClient().cartAdd(productId: id, qty: 1);
                  if (!context.mounted) return;
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CheckoutPage(),
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              child: const Text("BUY NOW", style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),

      /// ✅ BODY
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            automaticallyImplyLeading: false,
            expandedHeight: 320,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  SizedBox(
                    height: 320,
                    width: double.infinity,
                    child: Image.network(
                      product['image']!,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 40,
                    left: 16,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF0FFE2),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? "No Name",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    product['price'] ?? '0',
                    style: const TextStyle(
                        fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 6),
                      Text("Harvest Date: ${product['harvest'] ?? 'N/A'}"),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(Icons.scale, size: 16),
                      const SizedBox(width: 6),
                      Text("Available: ${product['weight'] ?? '0'} kg"),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Text(
                    product['description'] ?? "No description available",
                    style: const TextStyle(fontSize: 14),
                  ),

                  const SizedBox(height: 20),

                  /// 👨‍🌾 FARMER CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7F1BE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.green,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.product['farmerName'] ?? "Farmer Name",
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.product['farmerLocation'] ?? "Location",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),

                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isFollowing ? Colors.grey : Colors.green,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                              onPressed: _followLoading ? null : _toggleFollow,
                              icon: Icon(
                                _isFollowing ? Icons.check : Icons.person_add,
                                size: 16,
                                color: Colors.white,
                              ),
                              label: Text(
                                _isFollowing ? "Following" : "Follow",
                                style: const TextStyle(fontSize: 12, color: Colors.white),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              final fid = int.tryParse(widget.product['farmerId'] ?? '') ?? 0;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BuyerChatPage(
                                    contactName: widget.product['farmerName'] ?? "Farmer",
                                    peerUserId: fid > 0 ? fid : null,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.chat, size: 18),
                            label: const Text("Message Farmer"),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// ✅ MORE PRODUCTS (FIXED)
                  if (widget.farmerProducts != null && widget.farmerProducts!.isNotEmpty) ...[
                    const Text(
                      "More from this Farmer",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      height: 170,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.farmerProducts!.length,
                        itemBuilder: (context, index) {
                          final item = widget.farmerProducts![index];

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductDetailsPage(
                                    product: item,
                                    farmerProducts: widget.farmerProducts,
                                  ),
                                ),
                              );
                            },

                            child: Container(
                              width: 140,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),

                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(15),
                                    ),
                                    child: (item['image'] ?? '').isEmpty
                                        ? Container(
                                            height: 80,
                                            color: Colors.grey.shade200,
                                            child: const Icon(Icons.image_not_supported),
                                          )
                                        : Image.network(
                                            item['image']!,
                                            height: 80,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              height: 80,
                                              color: Colors.grey.shade200,
                                              child: const Icon(Icons.broken_image),
                                            ),
                                          ),
                                  ),

                                  Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name'] ?? "Product",
                                          style: const TextStyle(
                                              fontSize: 12, fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),

                                        const SizedBox(height: 4),

                                        Text(
                                          item['price'] ?? '0',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),

                                        const SizedBox(height: 6),

                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_today, size: 10),
                                            const SizedBox(width: 2),
                                            Expanded(
                                              child: Text(
                                                item['harvest'] ?? "N/A",
                                                style:
                                                const TextStyle(fontSize: 10),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomItem(
      BuildContext context, {
        required IconData icon,
        required String label,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 10)),
        ],
      ),
    );
  }
}