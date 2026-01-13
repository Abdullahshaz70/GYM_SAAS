import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddGymScreen extends StatefulWidget {
  const AddGymScreen({super.key});

  @override
  State<AddGymScreen> createState() => _AddGymScreenState();
}

class _AddGymScreenState extends State<AddGymScreen> {
  final name = TextEditingController();
  final location = TextEditingController();
  final fee = TextEditingController();
  bool isLoading = false;

  Future<void> createGym() async {
    if (name.text.isEmpty || location.text.isEmpty || fee.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('gyms').add({
        'gymName': name.text,
        'location': location.text,
        'defaultFee': num.tryParse(fee.text) ?? 0,
        'registrationCode': DateTime.now().millisecondsSinceEpoch.toString(),
        'plan': 'free',
        'status': 'active',
        'isSaaSActive': true,
        'createdAt': Timestamp.now(),
        'ownerUid': '',
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54, fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.yellowAccent, size: 20),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.yellowAccent, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "REGISTER GYM",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "New Branch Details",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Enter the information below to add a new gym to the SaaS platform.",
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: name,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Gym Name", Icons.fitness_center_rounded),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: location,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Location / City", Icons.location_on_rounded),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: fee,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: _inputDecoration("Monthly Default Fee (Rs)", Icons.payments_rounded),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isLoading ? null : createGym,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellowAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Text(
                        "CONFIRM & CREATE",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}