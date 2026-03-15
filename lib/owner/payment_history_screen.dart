import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../user/screens/skeleton_loaders.dart'; // ← NEW

class PaymentHistoryScreen extends StatelessWidget {
  final String uid;
  final String gymId;

  const PaymentHistoryScreen(
      {super.key, required this.uid, required this.gymId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("PAYMENT HISTORY",
            style: TextStyle(color: Colors.white, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('gyms')
            .doc(gymId)
            .collection('payments')
            .where('memberId', isEqualTo: uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // ── SKELETON while waiting ──────────────────────────────────
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const PaymentHistorySkeleton(); // ← skeleton
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(
                Icons.history, "No payment history found");
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data =
                  docs[index].data() as Map<String, dynamic>;
              final ts = data['timestamp'] as Timestamp?;
              final date = ts?.toDate() ?? DateTime.now();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Rs ${data['amount']}",
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                        Text(
                            DateFormat('dd MMM yyyy').format(date),
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                    const Spacer(),
                    Text(data['method'] ?? "Cash",
                        style: const TextStyle(
                            color: Colors.yellowAccent, fontSize: 12)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white10, size: 60),
          const SizedBox(height: 15),
          Text(message,
              style: const TextStyle(
                  color: Colors.white38, fontSize: 14)),
        ],
      ),
    );
  }
}