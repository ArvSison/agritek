import 'package:flutter/material.dart';
import 'login_page.dart';
import 'sign_up_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool expanded = false;
  bool logoVisible = false;

  @override
  void initState() {
    super.initState();
    // Fade in logo after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        logoVisible = true;
      });
    });
  }

  void swipeUp() {
    setState(() {
      expanded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    // Custom colors
    const customGreen = Color(0xFF024E44);
    const customYellow = Color(0xFFCDEA6C);

    return Scaffold(
      backgroundColor: const Color(0xFFF0FFE2),
      body: Stack(
        children: [
          // MAIN LOGO (moves up on expand)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            top: expanded ? 230 : screenHeight * 0.3,
            left: 0,
            right: 0,
            child: Column(
              children: [
                AnimatedOpacity(
                  opacity: logoVisible ? 1 : 0,
                  duration: const Duration(seconds: 2),
                  child: ClipOval(
                    child: Image.asset(
                      'logos/kadiwa.jpg',
                      width: 220,
                      height: 220,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 70),
              ],
            ),
          ),

          // BOTTOM PANEL
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.delta.dy < -5) swipeUp();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                height: expanded ? screenHeight * 0.31 : 90,
                decoration: const BoxDecoration(
                  color: customGreen,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(40),
                  ),
                ),
                child: expanded
                    ? SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 15),
                          child: const Text(
                            "WELCOME",
                            style: TextStyle(
                              fontSize: 30,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Text(
                            "We're excited to have you! Log in now and discover "
                                "how we can help simplify your everyday tasks and "
                                "connect you to what matters most.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: customYellow,
                                  foregroundColor: customGreen,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 55, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    PageRouteBuilder(
                                      transitionDuration:
                                      const Duration(milliseconds: 500),
                                      pageBuilder: (context, animation, secondaryAnimation) =>
                                      const LoginPage(),
                                      transitionsBuilder: (context, animation,
                                          secondaryAnimation, child) {
                                        const begin = Offset(0.0, 1.0);
                                        const end = Offset.zero;
                                        final tween = Tween(begin: begin, end: end)
                                            .chain(CurveTween(curve: Curves.easeInOut));
                                        final offsetAnimation = animation.drive(tween);
                                        return SlideTransition(
                                          position: offsetAnimation,
                                          child: child,
                                        );
                                      },
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Log In",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF0FFE2),
                                  foregroundColor: customGreen,
                                  side: const BorderSide(color: customGreen),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 55, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    PageRouteBuilder(
                                      transitionDuration:
                                      const Duration(milliseconds: 500),
                                      pageBuilder: (context, animation, secondaryAnimation) =>
                                      const SignUpPage(),
                                      transitionsBuilder: (context, animation,
                                          secondaryAnimation, child) {
                                        const begin = Offset(0.0, 1.0);
                                        const end = Offset.zero;
                                        final tween = Tween(begin: begin, end: end)
                                            .chain(CurveTween(curve: Curves.easeInOut));
                                        final offsetAnimation = animation.drive(tween);
                                        return SlideTransition(
                                          position: offsetAnimation,
                                          child: child,
                                        );
                                      },
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Sign Up",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    : const Center(
                  child: Icon(
                    Icons.keyboard_arrow_up,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}