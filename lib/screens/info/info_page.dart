import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/title_bar.dart';
import '../../theme.dart';
import 'dart:ui';

class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0F111A) : const Color(0xFFF0F2F5);

    return Scaffold(
      appBar: const TitleBar(title: 'About App'),
      backgroundColor: backgroundColor,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isDark ? const Color(0xFF0F111A) : const Color(0xFFF0F2F5),
              isDark ? const Color(0xFF1A1D2E) : Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                // Glassmorphic Main Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.9),
                        isDark ? Colors.white.withOpacity(0.03) : Colors.white.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(isDark ? 0.3 : 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                        ),
                        child: Image.asset(
                          'assets/icons/logo.png',
                          height: 70,
                          width: 70,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        'About This App',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'This application is developed using Flutter and Dart, featuring a clean and intuitive UI/UX. It enables students to track their buses in real-time with ease.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.white70 : Colors.black54,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Connection Section
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 12),
                    child: Text(
                      'CONNECT WITH DEVELOPER',
                      style: theme.textTheme.labelLarge?.copyWith(
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
                
                SocialTile(
                  iconPath: 'assets/icons/gmail.png',
                  label: 'Email Support',
                  subtitle: 'subhamkumarsahu929@gmail.com',
                  url: 'mailto:subhamkumarsahu929@gmail.com',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                SocialTile(
                  iconPath: 'assets/icons/linkedin.png',
                  label: 'LinkedIn',
                  subtitle: 'Professional Profile',
                  url: 'https://www.linkedin.com/in/subham-kumar-sahu-ba3446279/',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                SocialTile(
                  iconPath: 'assets/icons/github.png',
                  label: 'GitHub',
                  subtitle: 'Open Source Projects',
                  url: 'https://github.com/subhamkumarsahu929',
                  isDark: isDark,
                ),
                
                const SizedBox(height: 30),
                Text(
                  'Designed & Developed by',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  'Subham Kumar Sahu',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Version 2.0.0',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryColor.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SocialTile extends StatelessWidget {
  final String iconPath;
  final String label;
  final String subtitle;
  final String url;
  final bool isDark;

  const SocialTile({
    super.key,
    required this.iconPath,
    required this.label,
    required this.subtitle,
    required this.url,
    required this.isDark,
  });

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openUrl(url),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
            ),
            boxShadow: isDark ? [] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(iconPath, height: 24, width: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppTheme.primaryColor.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
