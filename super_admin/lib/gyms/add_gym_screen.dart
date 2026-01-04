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

  Future<void> createGym() async {
    await FirebaseFirestore.instance.collection('gyms').add({
      'gymName': name.text,
      'location': location.text,
      'defaultFee': num.parse(fee.text),
      'registrationCode': DateTime.now().millisecondsSinceEpoch.toString(),
      'plan': 'free',
      'status': 'active',
      'isSaaSActive': true,
      'createdAt': Timestamp.now(),
      'ownerUid': '',
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ADD GYM")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: "Gym Name")),
            TextField(controller: location, decoration: const InputDecoration(labelText: "Location")),
            TextField(controller: fee, decoration: const InputDecoration(labelText: "Default Fee"), keyboardType: TextInputType.number),
            const SizedBox(height: 30),
            ElevatedButton(onPressed: createGym, child: const Text("CREATE GYM"))
          ],
        ),
      ),
    );
  }
}
