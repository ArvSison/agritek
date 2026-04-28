import 'package:flutter/material.dart';

import '../api/api_client.dart';

class UserEditPage extends StatefulWidget {
  final Map<String, String> profile;

  const UserEditPage({super.key, required this.profile});

  @override
  State<UserEditPage> createState() => _UserEditPageState();
}

class _UserEditPageState extends State<UserEditPage> {
  late TextEditingController usernameController;
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController addressController;
  late TextEditingController phoneController;
  late TextEditingController businessTypeController;
  late TextEditingController genderController;
  late TextEditingController birthController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    // 🔹 Initialize controllers with existing data
    usernameController =
        TextEditingController(text: widget.profile["username"]);
    nameController = TextEditingController(text: widget.profile["name"]);
    emailController = TextEditingController(text: widget.profile["email"]);
    addressController = TextEditingController(text: widget.profile["address"]);
    phoneController = TextEditingController(text: widget.profile["phone"]);
    businessTypeController =
        TextEditingController(text: widget.profile["businessType"]);
    genderController = TextEditingController(text: widget.profile["gender"]);
    birthController = TextEditingController(text: widget.profile["birth"]);
  }

  @override
  void dispose() {
    usernameController.dispose();
    nameController.dispose();
    emailController.dispose();
    addressController.dispose();
    phoneController.dispose();
    businessTypeController.dispose();
    genderController.dispose();
    birthController.dispose();
    super.dispose();
  }

  // 🔥 SAVE FUNCTION
  Future<void> saveProfile() async {
    if (_saving) return;
    setState(() => _saving = true);
    final updatedProfile = {
      "username": usernameController.text,
      "name": nameController.text,
      "email": emailController.text,
      "address": addressController.text,
      "phone": phoneController.text,
      "businessType": businessTypeController.text,
      "gender": genderController.text,
      "birth": birthController.text,
      "id": widget.profile["id"] ?? '',
    };

    try {
      final id = int.tryParse(widget.profile["id"] ?? '') ?? 0;
      if (id <= 0) throw Exception('Missing user id');
      await ApiClient().adminUserUpdate({
        'id': id,
        'username': usernameController.text.trim(),
        'email': emailController.text.trim(),
        'role': businessTypeController.text.trim(),
        'display_name': nameController.text.trim(),
        'address': addressController.text.trim(),
        'phone': phoneController.text.trim(),
        'gender': genderController.text.trim(),
        'birth_date': birthController.text.trim(),
      });
      if (!mounted) return;
      Navigator.pop(context, updatedProfile); // 🔁 return data
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDCE8D2),

      appBar: AppBar(
        title: const Text("Edit User"),
        backgroundColor: const Color(0xFF0F5C4A),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            buildField("Username", usernameController),
            buildField("Name", nameController),
            buildField("Email", emailController),
            buildField("Address", addressController),
            buildField("Phone", phoneController),
            buildField("Business Type", businessTypeController),
            buildField("Gender", genderController),
            buildField("Birth Date", birthController),

            const SizedBox(height: 30),

            // 💾 SAVE BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF024E44),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  "Save Changes",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 REUSABLE TEXTFIELD
  Widget buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}