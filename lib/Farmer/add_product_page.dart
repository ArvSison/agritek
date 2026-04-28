import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api/api_client.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();

  String productName = '';
  String productDescription = '';
  double? productPrice;
  double? productStockKg;
  DateTime? productDate; // <-- Added date field
  final ImagePicker _picker = ImagePicker();
  Uint8List? _pickedBytes;
  String? _pickedFileName;
  bool _uploading = false;

  @override
  void dispose() {
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

  InputDecoration inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF0FFE2),
      appBar: AppBar(
        title: const Text(
          'Add New Product',
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
              /// Product Name
              Material(
                elevation: 3,
                borderRadius: BorderRadius.circular(30),
                child: TextFormField(
                  decoration: inputStyle("Product Name"),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter product name';
                    }
                    return null;
                  },
                  onSaved: (value) => productName = value!,
                ),
              ),
              const SizedBox(height: 16),

              /// Price
              Material(
                elevation: 3,
                borderRadius: BorderRadius.circular(30),
                child: TextFormField(
                  decoration: inputStyle("Price"),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter product price';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                  onSaved: (value) => productPrice = double.parse(value!),
                ),
              ),
              const SizedBox(height: 16),

              /// Available stock (kg)
              Material(
                elevation: 3,
                borderRadius: BorderRadius.circular(30),
                child: TextFormField(
                  decoration: inputStyle("Available Stock (kg)"),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter available stock';
                    }
                    final v = double.tryParse(value);
                    if (v == null) return 'Enter a valid number';
                    if (v < 0) return 'Stock cannot be negative';
                    return null;
                  },
                  onSaved: (value) => productStockKg = double.parse(value!),
                ),
              ),
              const SizedBox(height: 16),

              /// Product Description
              Material(
                elevation: 3,
                borderRadius: BorderRadius.circular(30),
                child: TextFormField(
                  decoration: inputStyle("Product Description"),
                  maxLines: 3,
                  onSaved: (value) => productDescription = value ?? '',
                ),
              ),
              const SizedBox(height: 16),

              /// Product Date
              Material(
                elevation: 3,
                borderRadius: BorderRadius.circular(30),
                child: TextFormField(
                  readOnly: true,
                  decoration: inputStyle("Select Date"),
                  controller: TextEditingController(
                    text: productDate == null
                        ? ''
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
                  validator: (value) {
                    if (productDate == null) {
                      return 'Please select a date';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),

              /// Product image (from device)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Product photo',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF024E44)),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _uploading ? null : () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Gallery'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: (_uploading || kIsWeb)
                          ? null
                          : () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Camera'),
                    ),
                  ),
                ],
              ),
              if (kIsWeb)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Web: use Gallery (browser file picker).',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
              const SizedBox(height: 12),
              Container(
                height: 180,
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
                child: _pickedBytes == null
                    ? const Center(
                        child: Text(
                          'No photo selected',
                          style: TextStyle(color: Colors.green),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Image.memory(
                          _pickedBytes!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
              ),
              if (_pickedBytes != null)
                TextButton(
                  onPressed: _uploading ? null : () => setState(() => _pickedBytes = null),
                  child: const Text('Remove photo'),
                ),
              const SizedBox(height: 30),

              /// Add Product Button
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    final dateStr = productDate == null
                        ? ''
                        : '${productDate!.year.toString().padLeft(4, '0')}-${productDate!.month.toString().padLeft(2, '0')}-${productDate!.day.toString().padLeft(2, '0')}';
                    try {
                      setState(() => _uploading = true);
                      String? imageUrl;
                      if (_pickedBytes != null && _pickedBytes!.isNotEmpty) {
                        final api = ApiClient();
                        imageUrl = await api.farmerUploadProductImage(
                          _pickedBytes!,
                          filename: _pickedFileName ?? 'product.jpg',
                        );
                      }
                      await ApiClient().farmerAddProduct({
                        'name': productName,
                        'price': productPrice,
                        'unit': 'kg',
                        'harvest_date': dateStr,
                        'description': productDescription,
                        'stock_kg': productStockKg,
                        if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
                      });
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Product submitted (pending admin approval)'),
                        ),
                      );
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                    } finally {
                      if (mounted) setState(() => _uploading = false);
                    }
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
                  _uploading ? 'Uploading…' : 'Add Product',
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