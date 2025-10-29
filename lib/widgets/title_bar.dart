import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/info/info_page.dart';

class TitleBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const TitleBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final double dynamicHeight = MediaQuery.of(context).size.height * 0.10;
    final theme = Theme.of(context);

    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      backgroundColor: theme.primaryColor,
      toolbarHeight: dynamicHeight,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: theme.dialogTheme.backgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                title: Row(
                  children: [
                    Icon(Icons.settings, color: theme.primaryColor, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      'Settings',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondaryContainer,
                        ),
                        icon: const Icon(Icons.info_outline_rounded),
                        label: const Text('App Info'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const InfoPage(),
                            ),
                            //
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                            (route) => false,

                            //
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        label: const Text('Close'),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
