import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'auth/login.dart';
import 'firebase_options.dart';
import 'auth/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gym App',
      theme: ThemeData(
        useMaterial3: true,
        
        brightness: Brightness.dark,
        
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.yellowAccent,      
          selectionColor: Colors.yellowAccent,   
          selectionHandleColor: Colors.yellowAccent, 
        ),

        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.yellowAccent,
          primary: Colors.yellowAccent,
          brightness: Brightness.dark,
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}





// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(); // Ensure your google-services.json is in android/app/
//   runApp(const GymAdminApp());
// }

// class GymAdminApp extends StatelessWidget {
//   const GymAdminApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
//       home: const SeederDashboard(),
//     );
//   }
// }

// class SeederDashboard extends StatefulWidget {
//   const SeederDashboard({super.key});

//   @override
//   State<SeederDashboard> createState() => _SeederDashboardState();
// }

// class _SeederDashboardState extends State<SeederDashboard> {
//   final String targetGymId = "Fm6B5qNpXSh2DQmftX70";
//   bool _isSeeding = false;

//   // The Seeding Logic
//   Future<void> seedData() async {
//     setState(() => _isSeeding = true);
//     final FirebaseFirestore db = FirebaseFirestore.instance;

//     try {
//       // List of dummy members to add
//       List<Map<String, dynamic>> dummyMembers = [
//         {'name': 'Zain Ahmed', 'email': 'zain@example.pk', 'phone': '03001112223'},
//         {'name': 'Ayesha Khan', 'email': 'ayesha@example.pk', 'phone': '03215556667'},
//         {'name': 'Bilal Siddiqui', 'email': 'bilal@example.pk', 'phone': '03339998887'},
//       ];

//       for (var data in dummyMembers) {
//         // 1. Generate unique ID for the user
//         DocumentReference userRef = db.collection('users').doc();
//         String newUid = userRef.id;

//         // 2. Reference the member sub-collection
//         DocumentReference memberRef = db
//             .collection('gyms')
//             .doc(targetGymId)
//             .collection('members')
//             .doc(newUid);

//         WriteBatch batch = db.batch();

//         // Create the global User record
//         batch.set(userRef, {
//           'name': data['name'],
//           'email': data['email'],
//           'role': 'member',
//           'gymId': targetGymId,
//           'isVerified': true,
//           'createdAt': FieldValue.serverTimestamp(),
//           'contactNumber': data['phone'],
//         });

//         // Create the Gym-specific Member record
//         batch.set(memberRef, {
//           'uid': newUid,
//           'name': data['name'],
//           'contactNumber': data['phone'],
//           'plan': 'basic',
//           'joinedAt': FieldValue.serverTimestamp(),
//           'currentFee': 5000,
//           'feeStatus': 'unpaid',
//           'validUntil': null,
//           'createdBy': 'system_seeder',
//           'createdAt': FieldValue.serverTimestamp(),
//         });

//         await batch.commit();
//       }

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Successfully seeded 3 members!")),
//       );
//     } catch (e) {
//       print(e);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error: $e")),
//       );
//     } finally {
//       setState(() => _isSeeding = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Gym Data Seeder")),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.fitness_center, size: 80, color: Colors.blue),
//             const SizedBox(height: 20),
//             Text("Gym ID: $targetGymId", style: const TextStyle(fontWeight: FontWeight.bold)),
//             const SizedBox(height: 40),
//             _isSeeding
//                 ? const CircularProgressIndicator()
//                 : ElevatedButton.icon(
//                     onPressed: seedData,
//                     icon: const Icon(Icons.person_add),
//                     label: const Text("Seed Dummy Members"),
//                     style: ElevatedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
//                     ),
//                   ),
//           ],
//         ),
//       ),
//     );
//   }
// } 