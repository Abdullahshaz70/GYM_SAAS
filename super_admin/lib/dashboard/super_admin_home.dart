import 'package:flutter/material.dart';
import '../gyms/gyms_list_screen.dart';
import '../add_edit_gym_screen.dart';

class SuperAdminHome extends StatelessWidget {
  const SuperAdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SUPER ADMIN")),
      body: const GymsListScreen(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditGymScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
