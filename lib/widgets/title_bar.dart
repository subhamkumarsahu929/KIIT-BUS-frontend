import 'dart:ui';
import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/info/info_page.dart';

class TitleBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;

  const TitleBar({super.key, required this.title});

  @override
  State<TitleBar> createState() => _TitleBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _TitleBarState extends State<TitleBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _iconController;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  void _openSettings(BuildContext context) {
    _iconController.forward();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Settings",
      barrierColor: Colors.black.withOpacity(0.25),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, _, _) {
        final slide = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );

        return SlideTransition(
          position: slide,
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 115, right: 45),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Material(
                    color: Colors.white.withOpacity(0.12),
                    child: SizedBox(
                      width: 250,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.settings,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Settings',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.info_outline),
                                label: const Text('App Info'),
                                onPressed: () {
                                  Navigator.pop(context);
                                  _iconController.reverse();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const InfoPage(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 10),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                ),
                                icon: const Icon(Icons.logout),
                                label: const Text('Logout'),
                                onPressed: () {
                                  Navigator.pop(context);
                                  _iconController.reverse();
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                    (route) => false,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 5),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ).then((_) => _iconController.reverse());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dynamicHeight = MediaQuery.of(context).size.height * 0.10;

    return AppBar(
      toolbarHeight: dynamicHeight,
      centerTitle: true,
      backgroundColor: theme.primaryColor,
      title: Text(
        widget.title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      actions: [
        RotationTransition(
          turns: Tween(begin: 0.0, end: 0.25).animate(_iconController),
          child: IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => _openSettings(context),
          ),
        ),
      ],
    );
  }
}
