import 'package:flutter/material.dart';
import 'forgot_password_page.dart';

import 'Admin/admin_main_page.dart';
import 'Buyer/buyer_main_page.dart';
import 'Farmer/farmer_main_page.dart';
import 'api/api_client.dart';
import 'api/models.dart';
import 'services/app_session.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter username and password')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final api = ApiClient();
      final json = await api.login(username: username, password: password);
      final user = ApiUser.fromJson(json['user'] as Map<String, dynamic>);
      await AppSession.setUserId(user.id);
      await AppSession.applyFromProfileRow(json['user'] as Map<String, dynamic>);

      Widget next;
      switch (user.role) {
        case 'admin':
          next = const AdminPage();
          break;
        case 'farmer':
          next = const FarmerMainPage();
          break;
        case 'buyer':
        default:
          next = const BuyerMainPage();
          break;
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) => next,
          transitionsBuilder: (_, animation, __, child) {
            final slideAnimation = Tween(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            );
            final fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(animation);
            return SlideTransition(
              position: slideAnimation,
              child: FadeTransition(opacity: fadeAnimation, child: child),
            );
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
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

            /// LOGIN PANEL
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

                  /// LOGIN TITLE
                  const Text(
                    "Log In",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF024E44),
                    ),
                  ),
                  const SizedBox(height: 20),

                  /// USERNAME FIELD
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      hintText: "Username",
                      hintStyle: const TextStyle(
                        color: Color(0xFF024E44),
                        fontWeight: FontWeight.bold,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFD7F1BE),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  /// PASSWORD FIELD
                  TextField(
                    obscureText: _obscurePassword,
                    controller: _passwordController,
                    decoration: InputDecoration(
                      hintText: "Password",
                      hintStyle: const TextStyle(
                        color: Color(0xFF024E44),
                        fontWeight: FontWeight.bold,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFD7F1BE),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  /// FORGOT PASSWORD
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                            const ForgotPasswordPage(),
                          ),
                        );
                      },
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(
                          color: Color(0xFF024E44),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// LOGIN BUTTON
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 55),
                      backgroundColor: const Color(0xFF024E44),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            "Log In",
                            style: TextStyle(fontSize: 18),
                          ),
                  ),

                  const SizedBox(height: 25),

                  // Social login temporarily disabled (Google/Facebook).
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}