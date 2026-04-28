import 'package:flutter/material.dart';

import 'login_page.dart';
import 'api/api_client.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool agree = false;
  bool hidePassword = true;
  bool hideConfirmPassword = true;
  bool _busy = false;

  final _first = TextEditingController();
  final _last = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String _role = 'buyer';

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!agree) return;
    final u = _username.text.trim();
    final e = _email.text.trim();
    final p = _password.text;
    final c = _confirm.text;
    if (u.isEmpty || e.isEmpty || p.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill username, email, and password')),
      );
      return;
    }
    if (p != c) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await ApiClient().register(username: u, email: e, password: p, role: _role);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registered. Wait for admin approval, then log in.')),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // Use same style as Login page but smaller height and normal text
  InputDecoration inputStyle(String hint, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF024E44),
        fontWeight: FontWeight.bold, // hint text stays bold
      ),
      filled: true,
      fillColor: const Color(0xFFD7F1BE),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      suffixIcon: suffix,
    );
  }

  @override
  Widget build(BuildContext context) {
    double headerHeight = MediaQuery.of(context).size.height * 0.35;

    return Scaffold(
      backgroundColor: const Color(0xFF024E44),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// HEADER WITH LOGO
            Container(
              height: headerHeight,
              width: double.infinity,
              color: const Color(0xFF024E44),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Image.asset(
                    'logos/area51.jpg',
                    height: 90,
                    width: 90,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            /// SIGN UP PANEL
            Container(
              padding: const EdgeInsets.all(25),
              decoration: const BoxDecoration(
                color: Color(0xFFF0FFE2),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  /// SIGN UP TITLE
                  const Text(
                    "Sign Up",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF024E44),
                    ),
                  ),
                  const SizedBox(height: 20),

                  /// FIRST NAME + LAST NAME HORIZONTAL
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _first,
                          style: const TextStyle(
                            color: Color(0xFF024E44),
                            fontWeight: FontWeight.normal, // normal text
                          ),
                          decoration: inputStyle("First Name"),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: TextField(
                          controller: _last,
                          style: const TextStyle(
                            color: Color(0xFF024E44),
                            fontWeight: FontWeight.normal,
                          ),
                          decoration: inputStyle("Last Name"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  /// USERNAME FIELD
                  TextField(
                    controller: _username,
                    style: const TextStyle(
                      color: Color(0xFF024E44),
                      fontWeight: FontWeight.normal,
                    ),
                    decoration: inputStyle("Username"),
                  ),
                  const SizedBox(height: 12),

                  /// EMAIL FIELD
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(
                      color: Color(0xFF024E44),
                      fontWeight: FontWeight.normal,
                    ),
                    decoration: inputStyle("Email Address"),
                  ),
                  const SizedBox(height: 12),

                  /// PASSWORD FIELD
                  TextField(
                    controller: _password,
                    obscureText: hidePassword,
                    style: const TextStyle(
                      color: Color(0xFF024E44),
                      fontWeight: FontWeight.normal,
                    ),
                    decoration: inputStyle(
                      "Password",
                      suffix: IconButton(
                        icon: Icon(
                          hidePassword ? Icons.visibility_off : Icons.visibility,
                          color: const Color(0xFF024E44),
                        ),
                        onPressed: () {
                          setState(() {
                            hidePassword = !hidePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  /// CONFIRM PASSWORD FIELD
                  TextField(
                    controller: _confirm,
                    obscureText: hideConfirmPassword,
                    style: const TextStyle(
                      color: Color(0xFF024E44),
                      fontWeight: FontWeight.normal,
                    ),
                    decoration: inputStyle(
                      "Confirm Password",
                      suffix: IconButton(
                        icon: Icon(
                          hideConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: const Color(0xFF024E44),
                        ),
                        onPressed: () {
                          setState(() {
                            hideConfirmPassword = !hideConfirmPassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  const Text(
                    'Account type',
                    style: TextStyle(
                      color: Color(0xFF024E44),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Buyer'),
                        selected: _role == 'buyer',
                        onSelected: (_) => setState(() => _role = 'buyer'),
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text('Farmer'),
                        selected: _role == 'farmer',
                        onSelected: (_) => setState(() => _role = 'farmer'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  /// AGREEMENT CHECKBOX
                  Row(
                    children: [
                      Checkbox(
                        activeColor: const Color(0xFF024E44),
                        value: agree,
                        onChanged: (value) {
                          setState(() {
                            agree = value!;
                          });
                        },
                      ),
                      const Expanded(
                        child: Text(
                          "I agree with privacy and policy",
                          style: TextStyle(
                            color: Color(0xFF024E44),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  /// SIGN UP BUTTON
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50), // smaller height
                      backgroundColor: const Color(0xFF024E44),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: agree && !_busy ? _submit : null,
                    child: _busy
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            "Sign Up",
                            style: TextStyle(fontSize: 18),
                          ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}