import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api/api_client.dart';

class EditProductPage extends StatefulWidget {
  final Map<String, String> product;

  const EditProductPage({super.key, required this.product});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _weightController;
  late TextEditingController _harvestController;
  late TextEditingController _descriptionController;

  DateTime? productDate;
  String? _imagePreview;
  final ImagePicker _picker = ImagePicker();
  Uint8List? _pickedBytes;
  String? _pickedFileName;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product['name']);
    _priceController = TextEditingController(text: _coercePrice(widget.product['price']));
    _weightController = TextEditingController(text: widget.product['weight']);
    _harvestController = TextEditingController(text: widget.product['harvest']);
    _descriptionController =
        TextEditingController(text: widget.product['description']);
    final img = widget.product['image'] ?? '';
    _imagePreview = img.isEmpty ? null : img;
  }

  static String _coercePrice(String? raw) {
    // API returns label like "₱50.00/kg". Edit form needs numeric.
    final s = (raw ?? '').trim();
    if (s.isEmpty) return '';
    var out = s.replaceAll('₱', '');
    if (out.contains('/')) out = out.split('/').first;
    return out.trim();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _weightController.dispose();
    _harvestController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final x = await _picker.pickImage(source: source, maxWidth: 2048, maxHeight: 2048, imageQuality: 88);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pickedBytes = bytes;
        _pickedFileName = x.name;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  /// SAME INPUT STYLE
  InputDecoration inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: Colors.green.shade700, width: 2),
      ),
    );
  }

  Widget buildField(Widget child) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(30),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF0FFE2),

      /// APPBAR
      appBar: AppBar(
        title: const Text(
          'Edit Product',
          style: TextStyle(
            color: Color(0xFFF0FFE2),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF024E44),
        iconTheme: const IconThemeData(color: Color(0xFFF0FFE2)),
        elevation: 8,
        shadowColor: Colors.black38,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(25),
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),

        child: Form(
          key: _formKey,
          child: Column(
            children: [

              /// IMAGE PREVIEW + BUTTON
              Column(
                children: [
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: _pickedBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: Image.memory(
                              _pickedBytes!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          )
                        : _imagePreview != null && _imagePreview!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(25),
                                child: Image.network(
                                  _imagePreview!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.broken_image, size: 40),
                                  ),
                                ),
                              )
                            : const Center(
                                child: Text(
                                  'No photo selected',
                                  style: TextStyle(color: Colors.green),
                                ),
                              ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _saving ? null : () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Gallery'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: (_saving || kIsWeb) ? null : () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: const Text('Camera'),
                        ),
                      ),
                    ],
                  ),
                  if (_pickedBytes != null)
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () => setState(() {
                                _pickedBytes = null;
                              }),
                      child: const Text('Use original photo'),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              /// NAME
              buildField(
                TextFormField(
                  controller: _nameController,
                  decoration: inputStyle("Product Name"),
                  validator: (value) =>
                  value!.isEmpty ? 'Please enter product name' : null,
                ),
              ),

              const SizedBox(height: 16),

              /// PRICE
              buildField(
                TextFormField(
                  controller: _priceController,
                  decoration: inputStyle("Price"),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) return 'Enter price';
                    if (double.tryParse(value) == null) {
                      return 'Invalid number';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 16),

              /// WEIGHT
              buildField(
                TextFormField(
                  controller: _weightController,
                  decoration: inputStyle("Weight (kg)"),
                  keyboardType: TextInputType.number,
                ),
              ),

              const SizedBox(height: 16),

              /// DATE PICKER
              buildField(
                TextFormField(
                  readOnly: true,
                  decoration: inputStyle("Harvest Date"),
                  controller: TextEditingController(
                    text: productDate == null
                        ? _harvestController.text
                        : "${productDate!.day}/${productDate!.month}/${productDate!.year}",
                  ),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );

                    if (pickedDate != null) {
                      setState(() {
                        productDate = pickedDate;
                      });
                    }
                  },
                ),
              ),

              const SizedBox(height: 16),

              /// DESCRIPTION
              buildField(
                TextFormField(
                  controller: _descriptionController,
                  decoration: inputStyle("Product Description"),
                  maxLines: 3,
                ),
              ),

              const SizedBox(height: 30),

              /// SAVE BUTTON
              ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => _saving = true);
                  try {
                    String imageUrl = _imagePreview ?? '';
                    if (_pickedBytes != null && _pickedBytes!.isNotEmpty) {
                      imageUrl = await ApiClient().farmerUploadProductImage(
                        _pickedBytes!,
                        filename: _pickedFileName ?? 'product.jpg',
                      );
                    }
                    if (!context.mounted) return;
                    final harvestText = productDate == null
                        ? _harvestController.text.trim()
                        : '${productDate!.year.toString().padLeft(4, '0')}-${productDate!.month.toString().padLeft(2, '0')}-${productDate!.day.toString().padLeft(2, '0')}';
                    final updated = Map<String, String>.from(widget.product);
                    updated['name'] = _nameController.text.trim();
                    updated['price'] = _priceController.text.trim();
                    updated['weight'] = _weightController.text.trim();
                    updated['harvest'] = harvestText;
                    updated['harvestDate'] = harvestText;
                    updated['description'] = _descriptionController.text.trim();
                    if (imageUrl.isNotEmpty) {
                      updated['image'] = imageUrl;
                    }
                    final id = int.tryParse(widget.product['id'] ?? '') ?? 0;
                    if (id <= 0) {
                      throw Exception('Missing product id');
                    }
                    await ApiClient().farmerUpdateProduct({
                      'id': id,
                      'name': updated['name'],
                      'price': double.parse(updated['price'] ?? '0'),
                      'unit': 'kg',
                      'harvest_date': harvestText,
                      'description': updated['description'] ?? '',
                      'farmer_location': updated['farmerLocation'] ?? '',
                      'stock_kg': double.tryParse(updated['weight'] ?? ''),
                      if ((updated['image'] ?? '').isNotEmpty) 'image_url': updated['image'],
                    });
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Product updated successfully!')),
                    );
                    Navigator.pop(context, updated);
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  } finally {
                    if (mounted) setState(() => _saving = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF024E44),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                  shadowColor: Colors.black45,
                ),
                child: Text(
                  _saving ? 'Saving…' : 'Save Changes',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFFF0FFE2),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}