import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'gyms/gyms_list_screen.dart'; 
import 'dashboard/super_admin_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); 
  runApp(SuperAdminApp());
}

class SuperAdminApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Super Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.yellow,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: SuperAdminHome(),
    );
  }
}
