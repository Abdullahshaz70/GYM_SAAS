import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../add_edit_gym_screen.dart';

class GymsListScreen extends StatelessWidget {
  const GymsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('gyms').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final gyms = snapshot.data!.docs;

        if (gyms.isEmpty) {
          return const Center(child: Text("No gyms added yet", style: TextStyle(color: Colors.white)));
        }

        return ListView.builder(
          itemCount: gyms.length,
          itemBuilder: (context, index) {
            final doc = gyms[index];
            final g = doc.data() as Map<String, dynamic>;

            return Card(
              color: Colors.white10,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(g['gymName'] ?? "--", style: const TextStyle(color: Colors.white)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Status: ${g['status'] ?? '--'}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    Text("Plan: ${g['plan'] ?? '--'}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    Text("Default Fee: Rs ${g['defaultFee'] ?? 0}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.yellowAccent),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditGymScreen(gymId: doc.id),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
