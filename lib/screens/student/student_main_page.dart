import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'student_dashboard.dart';
import 'bus_schedule.dart';
import '../../widgets/title_bar.dart';
import '../../theme.dart';

class StudentMainPage extends StatefulWidget {
  const StudentMainPage({super.key});

  @override
  State<StudentMainPage> createState() => _StudentMainPageState();
}

class _StudentMainPageState extends State<StudentMainPage> {
  String username = "Loading...";
  String email = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocalUserData();
    _fetchUserDataFromFirebase(); 
  }

 
  Future<void> _loadLocalUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? "Loading...";
      email = prefs.getString('email') ?? "";
      isLoading = false;
    });
  }

 
  Future<void> _fetchUserDataFromFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        debugPrint("No user logged in");
        return;
      }

      debugPrint("Fetching data for user: ${user.uid}");
      final ref = FirebaseDatabase.instance.ref("users/${user.uid}");
      final snapshot = await ref.get();

      if (snapshot.exists) {
        debugPrint("Found user data: ${snapshot.value}");
        if (snapshot.value is Map) {
          final data = Map<String, dynamic>.from(snapshot.value as Map);
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
        debugPrint("No data found for user ${user.uid}");
        
        setState(() {
          username = user.displayName ?? "Unknown Student";
          email = user.email ?? "No email";
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching student data: $e");
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
                'Welcome to Student Portal',
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
                              Icons.person,
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
                                        ?.withValues(alpha:0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

              const SizedBox(height: 30),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
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
                  'Dashboard',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StudentDashboard()),
                  );
                },
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.schedule, color: Colors.white),
                label: const Text(
                  'Schedule',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BusSchedulePage()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
