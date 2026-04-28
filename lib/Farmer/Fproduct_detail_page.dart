import 'package:flutter/material.dart';
import 'edit_product_page.dart';

class ProductDetailsPage extends StatefulWidget {
  final Map<String, String> product;
  final List<Map<String, String>> farmerProducts;

  const ProductDetailsPage({
    super.key,
    required this.product,
    required this.farmerProducts,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  late Map<String, String> product;

  @override
  void initState() {
    super.initState();
    product = Map.from(widget.product);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      /// ✅ UPDATED EDIT BUTTON
      bottomNavigationBar: Container(
        height: 65,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          color: Color(0xFF024E44),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Center(
          child: ElevatedButton(
            onPressed: () async {
              final updatedProduct =
              await Navigator.push<Map<String, String>>(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProductPage(product: product),
                ),
              );

              if (updatedProduct != null) {
                setState(() {
                  product = updatedProduct;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Product updated successfully!")),
                );
                  // Tell the previous screen to reload from API.
                  if (context.mounted) {
                    Navigator.pop(context, true);
                  }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF024E44),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 5,
            ),
            child: const Text(
              "Edit Product",
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFFF0FFE2),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),

      /// BODY
      body: Column(
        children: [
          /// IMAGE
          Stack(
            children: [
              SizedBox(
                height: 320,
                width: double.infinity,
                child: (product['image'] ?? '').isEmpty
                    ? Container(
                        color: Colors.grey.shade300,
                        child: const Center(child: Icon(Icons.image_not_supported, size: 64)),
                      )
                    : Image.network(
                        product['image']!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade300,
                          child: const Center(child: Icon(Icons.broken_image, size: 64)),
                        ),
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

          /// DETAILS
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF0FFE2),
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product['name'] ?? "No Name",
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),

                    Text("${product['price'] ?? '0'}",
                        style: const TextStyle(
                            fontSize: 18,
                            color: Colors.green,
                            fontWeight: FontWeight.bold)),

                    const SizedBox(height: 12),

                    /// HARVEST DATE
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 6),
                        Text(
                            "Harvest Date: ${product['harvest'] ?? 'N/A'}"),
                      ],
                    ),

                    const SizedBox(height: 8),

                    /// WEIGHT
                    Row(
                      children: [
                        const Icon(Icons.scale, size: 16),
                        const SizedBox(width: 6),
                        Text(
                            "Available: ${product['weight'] ?? '0'} kg"),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Text(product['description'] ??
                        "No description available"),

                    const SizedBox(height: 20),

                    /// FARMER CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD7F1BE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.green,
                            child: Icon(Icons.person,
                                color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product['farmerName']?.isNotEmpty == true
                                      ? product['farmerName']!
                                      : '—',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  product['farmerLocation']?.isNotEmpty == true
                                      ? product['farmerLocation']!
                                      : '—',
                                  style:
                                  const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// MORE PRODUCTS
                    const Text("More from this Farmer",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    SizedBox(
                      height: 170,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.farmerProducts.length,
                        itemBuilder: (context, index) {
                          final item = widget.farmerProducts[index];

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ProductDetailsPage(
                                        product: item,
                                        farmerProducts:
                                        widget.farmerProducts,
                                      ),
                                ),
                              );
                            },
                            child: Container(
                              width: 140,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withOpacity(0.1),
                                    blurRadius: 6,
                                    offset:
                                    const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius:
                                    const BorderRadius.vertical(
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
                                    padding:
                                    const EdgeInsets.all(6.0),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                      children: [
                                        Text(
                                          item['name'] ??
                                              "Product",
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight:
                                              FontWeight.bold),
                                          maxLines: 1,
                                          overflow:
                                          TextOverflow.ellipsis,
                                        ),

                                        const SizedBox(height: 4),

                                        Text(
                                          " ${item['price'] ?? '0'}",
                                          style:
                                          const TextStyle(
                                            fontSize: 12,
                                            color: Colors.green,
                                            fontWeight:
                                            FontWeight.bold,
                                          ),
                                        ),

                                        const SizedBox(height: 6),

                                        /// 📅 HARVEST DATE
                                        Row(
                                          children: [
                                            const Icon(
                                                Icons
                                                    .calendar_today,
                                                size: 10),
                                            const SizedBox(
                                                width: 2),
                                            Expanded(
                                              child: Text(
                                                item['harvest'] ??
                                                    "N/A",
                                                style:
                                                const TextStyle(
                                                    fontSize:
                                                    10),
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}