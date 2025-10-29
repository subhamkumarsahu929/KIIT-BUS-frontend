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
    double containerWidth =
        orientation == Orientation.portrait ? size.width * 0.9 : size.width * 0.6;

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
                        'assets/images/app_logo.png',
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
                        'This app is made using Flutter and Dart.\n'
                        'It is designed with a minimal UI/UX and helps students track their buses in real-time.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),

                      const SizedBox(height: 25),
                      Divider(color: theme.dividerColor),
                      const SizedBox(height: 20),

                    
                      SizedBox(
                        width: containerWidth * 0.8,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.link),
                          onPressed: () {
                            openUrl(
                              "https://www.linkedin.com/in/subham-kumar-sahu-ba3446279?utm_source=share&utm_campaign=share_via&utm_content=profile&utm_medium=android_app",
                            );
                          },
                          label: const Text('LinkedIn'),
                        ),
                      ),
                      const SizedBox(height: 10),

                     
                      SizedBox(
                        width: containerWidth * 0.8,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.camera_alt),
                          onPressed: () {
                            openUrl(
                              "https://www.instagram.com/kumarsubham_06?igsh=ZXNmOTRmdGNrNnVn",
                            );
                          },
                          label: const Text('Instagram'),
                        ),
                      ),
                      const SizedBox(height: 10),

                      SizedBox(
                        width: containerWidth * 0.8,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.email),
                          onPressed: () {
                            openUrl("mailto:2405612@kiit.ac.in");
                          },
                          label: const Text('Gmail'),
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
                Text(
                  'Version 1.0.0',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
