import 'package:flutter/material.dart';

import '../api/api_client.dart';

class ProductDetailsPage extends StatelessWidget {
  final Map<String, String> product;
  final List<Map<String, String>>? farmerProducts;

  const ProductDetailsPage({
    super.key,
    required this.product,
    this.farmerProducts,
  });

  @override
  Widget build(BuildContext context) {
    final status = (product['status'] ?? '').toString();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

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

                  const SizedBox(height: 6),

                  if (status.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Chip(
                        label: Text(status),
                        backgroundColor: status == 'pending'
                            ? Colors.orange.shade100
                            : (status == 'active' ? Colors.green.shade100 : Colors.grey.shade200),
                      ),
                    ),

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
                                    product['farmerName'] ?? "Farmer Name",
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    product['farmerLocation'] ?? "Location",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        if (status == 'pending') ...[
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  icon: const Icon(Icons.check, color: Colors.white),
                                  label: const Text('Approve', style: TextStyle(color: Colors.white)),
                                  onPressed: () async {
                                    final id = int.tryParse(product['id'] ?? '') ?? 0;
                                    if (id <= 0) return;
                                    try {
                                      await ApiClient().adminProductAction(id: id, action: 'approve');
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Product approved')),
                                      );
                                      Navigator.pop(context, true);
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey.shade700,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  icon: const Icon(Icons.close, color: Colors.white),
                                  label: const Text('Decline', style: TextStyle(color: Colors.white)),
                                  onPressed: () async {
                                    final id = int.tryParse(product['id'] ?? '') ?? 0;
                                    if (id <= 0) return;
                                    final ok = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Decline product'),
                                        content: const Text('Reject this product?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Decline')),
                                        ],
                                      ),
                                    );
                                    if (ok != true) return;
                                    try {
                                      await ApiClient().adminProductAction(id: id, action: 'reject');
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Product declined')),
                                      );
                                      Navigator.pop(context, true);
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.delete_outline, color: Colors.white),
                            label: const Text(
                              'Delete product',
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: () async {
                              final id = int.tryParse(product['id'] ?? '') ?? 0;
                              if (id <= 0) return;

                              final reasonController = TextEditingController();
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete product'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Enter a reason (this will be sent to the farmer).'),
                                      const SizedBox(height: 10),
                                      TextField(
                                        controller: reasonController,
                                        maxLines: 3,
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          hintText: 'Reason for deleting...',
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                              if (ok != true) return;

                              final reason = reasonController.text.trim();
                              if (reason.isEmpty) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Reason is required')),
                                  );
                                }
                                return;
                              }

                              try {
                                await ApiClient().adminProductDelete(id: id, reason: reason);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Product deleted')),
                                );
                                Navigator.pop(context, true);
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}