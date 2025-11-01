import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  Future<void> openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;
    double containerWidth = orientation == Orientation.portrait
        ? size.width * 0.9
        : size.width * 0.6;

    const darkGrey = Color(0xFF2E2E2E);
    const darkBlue = Color(0xFF003366);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ABOUT',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: theme.primaryColor,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: Container(
                  width: containerWidth,
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(3, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/icons/logo.png',
                        height: 100,
                        width: 100,
                      ),
                      const SizedBox(height: 20),

                      Text(
                        'About This App',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Text(
                        'This application is developed using Flutter and Dart, featuring a clean and intuitive UI/UX.'
                        ' It enables students to track their buses in real-time with ease.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 25),
                      Divider(color: theme.dividerColor),
                      const SizedBox(height: 10),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          children: [
                            SocialBox(
                              iconPath: 'assets/icons/linkedin.png',
                              label: 'LinkedIn',
                              url:
                                  'https://www.linkedin.com/in/subham-kumar-sahu-ba3446279?utm_source=share&utm_campaign=share_via&utm_content=profile&utm_medium=android_app',
                              backgroundColor: darkGrey,
                            ),
                            Container(height: 1, color: darkBlue),
                            SocialBox(
                              iconPath: 'assets/icons/instagram.png',
                              label: 'Instagram',
                              url:
                                  'https://www.instagram.com/kumarsubham_06?igsh=ZXNmOTRmdGNrNnVn',
                              backgroundColor: darkGrey,
                            ),
                            Container(height: 1, color: darkBlue),
                            SocialBox(
                              iconPath: 'assets/icons/gmail.png',
                              label: 'Gmail',
                              url: 'mailto:subhamkumarsahu929@gmail.com',
                              backgroundColor: darkGrey,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

       
          Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Column(
              children: [
                Text(
                  'Developed by Subham Kumar Sahu',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Version 1.0.0', style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SocialBox extends StatelessWidget {
  final String iconPath;
  final String label;
  final String url;
  final Color backgroundColor;

  const SocialBox({
    super.key,
    required this.iconPath,
    required this.label,
    required this.url,
    required this.backgroundColor,
  });

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Image.asset(iconPath, height: 28, width: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Colors.white,
              ),
              onPressed: () => _openUrl(url),
            ),
          ],
        ),
      ),
    );
  }
}
