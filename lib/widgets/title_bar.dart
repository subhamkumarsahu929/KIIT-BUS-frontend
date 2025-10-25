import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';

class TitleBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const TitleBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
   
    final double dynamicHeight = MediaQuery.of(context).size.height * 0.10;

    return PreferredSize(
      preferredSize: Size.fromHeight(dynamicHeight),
      child: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings,
              color: Colors.black,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  title: Row(
                    children: const [
                      Icon(Icons.settings, color: Colors.green, size: 28),
                      SizedBox(width: 10),
                      Text('Settings'),
                    ],
                  ),
                  content: const Text(
                    'Choose an option below:',
                    style: TextStyle(fontSize: 16),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'OK',
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      child: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

 
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
