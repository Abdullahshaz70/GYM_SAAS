import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dashboard/super_admin_home.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SuperAdminApp());
}

class SuperAdminApp extends StatelessWidget {
  const SuperAdminApp({super.key});

  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Super Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: Colors.yellowAccent,
          secondary: Colors.yellowAccent.withOpacity(0.8),
        ),
      ),
      home: FutureBuilder(
        future: _initializeFirebase(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show splash / loading indicator while Firebase initializes
            return const Scaffold(
              backgroundColor: Color(0xFF0F0F0F),
              body: Center(
                child: CircularProgressIndicator(
                  color: Colors.yellowAccent,
                ),
              ),
            );
          } else if (snapshot.hasError) {
            return Scaffold(
              backgroundColor: Color(0xFF0F0F0F),
              body: Center(
                child: Text(
                  'Firebase Initialization Failed',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            );
          } else {
            // Firebase initialized successfully → show home screen
            return const SuperAdminHome();
          }
        },
      ),
    );
  }
}
