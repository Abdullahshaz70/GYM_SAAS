  import 'package:flutter/material.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:intl/intl.dart';
  import 'package:url_launcher/url_launcher.dart';
  import 'package:intl/intl.dart';


class AttendanceScreen extends StatelessWidget {
  final String uid;
  final String gymId;

  const AttendanceScreen({super.key, required this.uid, required this.gymId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, title: const Text("ATTENDANCE LOG")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('gyms').doc(gymId)
            .collection('attendance').where('memberId', isEqualTo: uid)
            .orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No records found", style: TextStyle(color: Colors.white38)));

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final date = (docs[index]['timestamp'] as Timestamp).toDate();
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                    const SizedBox(width: 15),
                    Text(DateFormat('EEEE, dd MMM yyyy').format(date), style: const TextStyle(color: Colors.white)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}