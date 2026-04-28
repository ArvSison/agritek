import 'package:flutter/material.dart';
import 'Farmer/farmer_main_page.dart';
import 'Buyer/buyer_main_page.dart';
import 'Admin/admin_main_page.dart';
import 'api/api_client.dart';

class BuyerFarmerPage extends StatelessWidget {
  const BuyerFarmerPage({super.key});

  /// GO TO FARMER PAGE
  void goToFarmerPage(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, animation, __) => const FarmerMainPage(),
        transitionsBuilder: (_, animation, __, child) {
          final slide = Tween(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          );

          final fade = Tween<double>(begin: 0, end: 1).animate(animation);

          return SlideTransition(
            position: slide,
            child: FadeTransition(
              opacity: fade,
              child: child,
            ),
          );
        },
      ),
    );
  }

  /// GO TO BUYER PAGE
  void goToBuyerPage(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, animation, __) => const BuyerMainPage(),
        transitionsBuilder: (_, animation, __, child) {
          final slide = Tween(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          );

          return SlideTransition(
            position: slide,
            child: child,
          );
        },
      ),
    );
  }

  /// 🔒 ADMIN ACCESS WITH PIN (verified on server)
  void goToAdminPage(BuildContext context) {
    final controller = TextEditingController();
    var busy = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: const Text("Admin Access"),
              content: TextField(
                controller: controller,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(
                  hintText: "Enter 4-digit PIN",
                ),
              ),
              actions: [
                TextButton(
                  onPressed: busy
                      ? null
                      : () async {
                          final pin = controller.text.trim();
                          if (pin.length != 4) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(content: Text('PIN must be 4 digits')),
                            );
                            return;
                          }
                          setLocal(() => busy = true);
                          try {
                            await ApiClient().verifyAdminPin(pin);
                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext);
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const AdminPage()),
                            );
                          } catch (e) {
                            if (!dialogContext.mounted) return;
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          } finally {
                            setLocal(() => busy = false);
                          }
                        },
                  child: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Enter"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double headerHeight = MediaQuery.of(context).size.height * 0.25;
    const Color mainGreen = Color(0xFF024E44);

    return Scaffold(
      backgroundColor: mainGreen,
      body: Column(
        children: [

          /// 🔥 HEADER WITH CLICKABLE LOGO
          Container(
            height: headerHeight,
            width: double.infinity,
            color: mainGreen,
            child: Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(100),
                onTap: () => goToAdminPage(context), // 👈 CLICK HERE
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Image.asset(
                    'logos/area51.jpg',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),

          /// WHITE PANEL
          Expanded(
            child: Container(
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
                mainAxisSize: MainAxisSize.min,
                children: [

                  const Text(
                    "Are you a",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// FARMER BUTTON
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 55),
                      backgroundColor: mainGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () => goToFarmerPage(context),
                    child: const Text(
                      "Farmer",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    "OR",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  /// BUYER BUTTON
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 55),
                      backgroundColor: mainGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () => goToBuyerPage(context),
                    child: const Text(
                      "Buyer",
                      style: TextStyle(fontSize: 18, color: Colors.white),
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