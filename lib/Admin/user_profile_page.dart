import 'package:flutter/material.dart';
import 'user_edit_page.dart'; // ✅ IMPORT EDIT PAGE

class UserProfilePage extends StatelessWidget {
  final Map<String, String> profile;

  const UserProfilePage({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final String name = profile["name"] ?? "No Name";

    return Scaffold(
      backgroundColor: const Color(0xFFDCE8D2),

      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🔷 HEADER
            Container(
              height: 170,
              decoration: const BoxDecoration(
                color: Color(0xFF0F5C4A),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.green,
                    child: Text(
                      name.isNotEmpty
                          ? name.substring(0, 2).toUpperCase()
                          : "NA",
                      style: const TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        "User Profile",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🔷 USER INFO CARD
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Material(
                elevation: 3,
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "User Information",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF024E44),
                        ),
                      ),

                      const SizedBox(height: 10),
                      const Divider(),
                      const SizedBox(height: 10),

                      ProfileRow("Username:", profile["username"] ?? ""),
                      ProfileRow("Name:", profile["name"] ?? ""),
                      ProfileRow("Email:", profile["email"] ?? ""),
                      ProfileRow("Address:", profile["address"] ?? ""),
                      ProfileRow("Phone:", profile["phone"] ?? ""),
                      ProfileRow("Business Type:", profile["businessType"] ?? ""),
                      ProfileRow("Gender:", profile["gender"] ?? ""),
                      ProfileRow("Birth Date:", profile["birth"] ?? ""),

                      const SizedBox(height: 20),

                      // 🔥 ACTION BUTTONS
                      Row(
                        children: [
                          // ✏️ EDIT BUTTON (UPDATED)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final updated = await Navigator.push<Map<String, String>>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        UserEditPage(profile: profile),
                                  ),
                                );
                                if (updated != null && context.mounted) {
                                  Navigator.pop(context, updated);
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF024E44),
                                side: const BorderSide(color: Color(0xFF024E44)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text("Edit Info"),
                            ),
                          ),

                          const SizedBox(width: 10),

                          // 🗑️ DELETE BUTTON
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                final TextEditingController pinController =
                                TextEditingController();

                                const String adminPin = "1234";

                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Admin Access Required"),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                            "Enter admin PIN to delete this user"),
                                        const SizedBox(height: 10),
                                        TextField(
                                          controller: pinController,
                                          keyboardType: TextInputType.number,
                                          obscureText: true,
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            hintText: "Enter PIN",
                                          ),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context),
                                        child: const Text("Cancel"),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          if (pinController.text == adminPin) {
                                            Navigator.pop(context);

                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title:
                                                const Text("Delete User"),
                                                content: Text(
                                                    "Are you sure you want to delete $name?"),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                    child:
                                                    const Text("Cancel"),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      Navigator.pop(context);

                                                      ScaffoldMessenger.of(
                                                          context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                            content: Text(
                                                                "$name deleted")),
                                                      );
                                                    },
                                                    child: const Text(
                                                      "Delete",
                                                      style: TextStyle(
                                                          color: Colors.red),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content:
                                                Text("Incorrect PIN"),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        },
                                        child: const Text("Confirm"),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text("Delete"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// 🔹 PROFILE ROW WIDGET
class ProfileRow extends StatelessWidget {
  final String title;
  final String value;

  const ProfileRow(this.title, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}