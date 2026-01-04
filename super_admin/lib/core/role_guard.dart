import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../dashboard/super_admin_home.dart';

class RoleGuard extends StatelessWidget {
  final String uid;
  const RoleGuard({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;

        if (data == null || data['role'] != 'superAdmin') {
          return const Scaffold(
            body: Center(child: Text("ACCESS DENIED")),
          );
        }

        return const SuperAdminHome();
      },
    );
  }
}
