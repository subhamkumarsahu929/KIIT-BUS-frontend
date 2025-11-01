import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'driver_dashboard.dart';
import '../../widgets/title_bar.dart';
import '../../theme.dart';

class DriverMainPage extends StatefulWidget {
  const DriverMainPage({super.key});

  @override
  State<DriverMainPage> createState() => _DriverMainPageState();
}

class _DriverMainPageState extends State<DriverMainPage> {
  String username = "Loading...";
  String email = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDriverData();
  }

  Future<void> _fetchDriverData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint("No user logged in");
        setState(() {
          username = "No user found";
          isLoading = false;
        });
        return;
      }

      debugPrint("Fetching data for driver: ${user.uid}");
      final ref = FirebaseDatabase.instance.ref("users/${user.uid}");
      final snapshot = await ref.get();

      if (snapshot.exists) {
        debugPrint("Found driver data: ${snapshot.value}");
        if (snapshot.value is Map) {
          final data = Map<String, dynamic>.from(snapshot.value as Map);

          if (data['role'] != 'driver') {
            debugPrint("Warning: User is not a driver");
          }

          setState(() {
            username = data['username'] ?? "Unknown";
            email = data['email'] ?? user.email ?? "No email";
            isLoading = false;
          });

        
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('username', username);
          await prefs.setString('email', email);
          debugPrint(
            "Updated SharedPreferences with username: $username, email: $email",
          );
        }
      } else {
        debugPrint("No data found for driver ${user.uid}");
        
        setState(() {
          username = user.displayName ?? "Unknown Driver";
          email = user.email ?? "";
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching driver data: $e");
      setState(() {
        username = "Error loading data";
        email = "";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: const TitleBar(title: 'KIIT BUS'),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 10),

             
              Text(
                'Welcome to Driver Portal',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: theme.colorScheme.primary,
                ),
              ),

              const SizedBox(height: 25),

             
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          if (!isDark)
                            const BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundColor: AppTheme.primaryColor,
                            child: const Icon(
                              Icons.directions_bus,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  username,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  email,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 14,
                                    color: theme.textTheme.bodyMedium?.color
                                        ?.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ],
          ),
        ),
      ),

     
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            if (!isDark)
              const BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, -2),
              ),
          ],
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.dashboard, color: Colors.white),
          label: const Text(
            'Go to Dashboard',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DriverDashboard()),
            );
          },
        ),
      ),
    );
  }
}
