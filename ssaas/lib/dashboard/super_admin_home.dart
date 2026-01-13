import 'package:flutter/material.dart';
import '../gyms/gyms_list_screen.dart';
import '../add_edit_gym_screen.dart';

class SuperAdminHome extends StatelessWidget {
  const SuperAdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F), // Deep black background
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        backgroundColor: const Color(0xFF0F0F0F),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "SUPER ADMIN",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                color: Colors.white54,
                letterSpacing: 2,
              ),
            ),
            Text(
              "Gym Management",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.05),
              child: const Icon(Icons.person_outline, color: Colors.white),
            ),
          ),
        ],
      ),
      body: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
          ),
          child: const GymsListScreen(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditGymScreen()),
          );
        },
        backgroundColor: Colors.yellowAccent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add, weight: 700),
        label: const Text(
          "ADD NEW GYM",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),
    );
  }
}