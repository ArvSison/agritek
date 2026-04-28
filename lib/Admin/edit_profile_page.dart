import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api/api_client.dart';
import '../services/app_session.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, String> profile;

  const EditProfilePage({super.key, required this.profile});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController usernameController;
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController addressController;
  late TextEditingController phoneController;
  late TextEditingController birthController;

  String gender = "Male";
  String _serverAvatarUrl = '';
  Uint8List? _pickedBytes;
  String _pickedFilename = 'avatar.jpg';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    usernameController =
        TextEditingController(text: widget.profile["username"]);
    nameController = TextEditingController(text: widget.profile["name"]);
    emailController = TextEditingController(text: widget.profile["email"]);
    addressController =
        TextEditingController(text: widget.profile["address"]);
    phoneController = TextEditingController(text: widget.profile["phone"]);
    birthController = TextEditingController(text: widget.profile["birth"]);
    _serverAvatarUrl = widget.profile["avatarUrl"] ?? '';
    gender = _coerceGender(widget.profile["gender"]);
  }

  @override
  void dispose() {
    usernameController.dispose();
    nameController.dispose();
    emailController.dispose();
    addressController.dispose();
    phoneController.dispose();
    birthController.dispose();
    super.dispose();
  }

  static String _coerceGender(String? raw) {
    final g = (raw ?? '').trim();
    if (g.isEmpty || g == '—' || g == '-') return 'Male';
    if (g.toLowerCase() == 'female') return 'Female';
    if (g.toLowerCase() == 'male') return 'Male';
    return 'Male';
  }

  InputDecoration inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFD7F1BE),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: BorderSide(
          color: Colors.green.shade700,
          width: 2,
        ),
      ),
    );
  }

  Future<void> pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF024E44),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF024E44)),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        birthController.text =
            "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _pickImage() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 88,
    );
    if (x == null) return;
    final bytes = await x.readAsBytes();
    setState(() {
      _pickedBytes = bytes;
      _pickedFilename = x.name.isNotEmpty ? x.name : 'avatar.jpg';
    });
  }

  Future<void> _saveProfile() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      String? avatarUrl = _serverAvatarUrl.isNotEmpty ? _serverAvatarUrl : null;
      if (_pickedBytes != null && _pickedBytes!.isNotEmpty) {
        avatarUrl = await ApiClient().uploadProfileImage(_pickedBytes!, filename: _pickedFilename);
      }
      final body = <String, dynamic>{
        'username': usernameController.text.trim(),
        'email': emailController.text.trim(),
        'display_name': nameController.text.trim(),
        'address': addressController.text.trim(),
        'phone': phoneController.text.trim(),
        'gender': gender,
        'birth_date': birthController.text.trim(),
      };
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        body['avatar_url'] = avatarUrl;
      }
      final user = await ApiClient().patchProfile(body);
      await AppSession.applyFromProfileRow(user);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _avatarPreview() {
    Widget inner;
    if (_pickedBytes != null && _pickedBytes!.isNotEmpty) {
      inner = Image.memory(_pickedBytes!, width: 110, height: 110, fit: BoxFit.cover);
    } else if (_serverAvatarUrl.isNotEmpty) {
      inner = Image.network(
        _serverAvatarUrl,
        width: 110,
        height: 110,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 60, color: Color(0xFF024E44)),
      );
    } else {
      inner = const Icon(Icons.person, size: 60, color: Color(0xFF024E44));
    }
    return ClipOval(child: inner);
  }

  Widget label(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF024E44),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountType = widget.profile['businessType'] ?? AppSession.userRole ?? '—';

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Edit Profile',
            style: TextStyle(color: Color(0xFFF0FFE2))),
        backgroundColor: const Color(0xFF024E44),
        iconTheme: const IconThemeData(color: Color(0xFFF0FFE2)),
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(bottom: Radius.circular(25)),
        ),
        elevation: 4,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFD7F1BE),
                            border: Border.all(
                              color: const Color(0xFF024E44),
                              width: 2,
                            ),
                          ),
                          child: _avatarPreview(),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFF024E44),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                label("Username"),
                TextFormField(
                    controller: usernameController,
                    decoration: inputStyle("Enter username")),
                const SizedBox(height: 16),

                label("Name"),
                TextFormField(
                    controller: nameController,
                    decoration: inputStyle("Enter name")),
                const SizedBox(height: 16),

                label("Account type"),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8E8E8),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    accountType,
                    style: const TextStyle(color: Color(0xFF024E44), fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 16),

                label("Email"),
                TextFormField(
                    controller: emailController,
                    decoration: inputStyle("Enter email")),
                const SizedBox(height: 16),

                label("Address"),
                TextFormField(
                    controller: addressController,
                    decoration: inputStyle("Enter address")),
                const SizedBox(height: 16),

                label("Phone Number"),
                TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: inputStyle("Enter phone number")),
                const SizedBox(height: 16),

                label("Gender"),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7F1BE),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: const Offset(1, 3),
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: gender,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                            value: "Male", child: Text("Male")),
                        DropdownMenuItem(
                            value: "Female", child: Text("Female")),
                      ],
                      onChanged: (value) =>
                          setState(() => gender = value!),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                label("Date of Birth"),
                TextFormField(
                  controller: birthController,
                  readOnly: true,
                  onTap: pickDate,
                  decoration: inputStyle("Select birth date"),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _saving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF024E44),
                    minimumSize:
                        const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(30)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF0FFE2)),
                        )
                      : const Text("Save Profile",
                          style: TextStyle(
                              fontSize: 18,
                              color: Color(0xFFF0FFE2))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
