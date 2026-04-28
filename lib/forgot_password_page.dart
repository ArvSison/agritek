import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {

  final TextEditingController emailController = TextEditingController();

  void sendResetLink() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Reset Link Sent"),
          content: const Text(
              "If the email exists, a password reset link has been sent."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("OK"),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    double headerHeight = MediaQuery.of(context).size.height * 0.45;

    return Scaffold(
      backgroundColor: const Color(0xFF024E44),

      body: SingleChildScrollView(
        child: Column(
          children: [

            /// HEADER
            Container(
              height: headerHeight,
              width: double.infinity,
              color: const Color(0xFF024E44),
              child: const Center(
                child: Icon(
                  Icons.lock_reset,
                  size: 90,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// RESET PANEL
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(25),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(
                  Radius.circular(50),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  )
                ],
              ),

              child: Column(
                children: [

                  const Text(
                    "Reset Password",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Enter your email or username and we will send you a password reset link.",
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 25),

                  /// EMAIL FIELD
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      hintText: "Email or Username",
                      filled: true,
                      fillColor: const Color(0xFFD7F1BE),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  /// SEND RESET LINK BUTTON
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 55),
                      backgroundColor: const Color(0xFF024E44),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: sendResetLink,
                    child: const Text(
                      "Send Reset Link",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),

                  const SizedBox(height: 15),

                  /// BACK BUTTON
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Back to Login"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}