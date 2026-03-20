// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import '../user/screens/skeleton_loaders.dart'; // ← NEW

// class PaymentHistoryScreen extends StatelessWidget {
//   final String uid;
//   final String gymId;

//   const PaymentHistoryScreen(
//       {super.key, required this.uid, required this.gymId});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         title: const Text("PAYMENT HISTORY",
//             style: TextStyle(color: Colors.white, fontSize: 16)),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new,
//               color: Colors.white, size: 20),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('gyms')
//             .doc(gymId)
//             .collection('payments')
//             .where('memberId', isEqualTo: uid)
//             .orderBy('timestamp', descending: true)
//             .snapshots(),
//         builder: (context, snapshot) {
//           // ── SKELETON while waiting ──────────────────────────────────
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const PaymentHistorySkeleton(); // ← skeleton
//           }

//           if (snapshot.hasError ||
//               !snapshot.hasData ||
//               snapshot.data!.docs.isEmpty) {
//             return _buildEmptyState(
//                 Icons.history, "No payment history found");
//           }

//           final docs = snapshot.data!.docs;

//           return ListView.builder(
//             padding: const EdgeInsets.all(20),
//             itemCount: docs.length,
//             itemBuilder: (context, index) {
//               final data =
//                   docs[index].data() as Map<String, dynamic>;
//               final ts = data['timestamp'] as Timestamp?;
//               final date = ts?.toDate() ?? DateTime.now();

//               return Container(
//                 margin: const EdgeInsets.only(bottom: 12),
//                 padding: const EdgeInsets.all(15),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.05),
//                   borderRadius: BorderRadius.circular(15),
//                 ),
//                 child: Row(
//                   children: [
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text("Rs ${data['amount']}",
//                             style: const TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 18)),
//                         Text(
//                             DateFormat('dd MMM yyyy').format(date),
//                             style: const TextStyle(
//                                 color: Colors.white38, fontSize: 12)),
//                       ],
//                     ),
//                     const Spacer(),
//                     Text(data['method'] ?? "Cash",
//                         style: const TextStyle(
//                             color: Colors.yellowAccent, fontSize: 12)),
//                   ],
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildEmptyState(IconData icon, String message) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(icon, color: Colors.white10, size: 60),
//           const SizedBox(height: 15),
//           Text(message,
//               style: const TextStyle(
//                   color: Colors.white38, fontSize: 14)),
//         ],
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../shared/skeleton_loaders.dart';

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
            style: TextStyle(color: Colors.white, fontSize: 14,
                fontWeight: FontWeight.bold, letterSpacing: 1.2)),
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const PaymentHistorySkeleton();
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(Icons.history, "No payment history found");
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return _OwnerPaymentCard(data: data);
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
              style: const TextStyle(color: Colors.white38, fontSize: 14)),
        ],
      ),
    );
  }
}

class _OwnerPaymentCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _OwnerPaymentCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    final method = (data['method'] ?? 'cash').toString().toLowerCase();
    final plan = data['plan'] ?? 'Monthly';
    final status = (data['status'] ?? 'completed').toString().toLowerCase();
    final ts = data['timestamp'] as Timestamp?;
    final date = ts != null
        ? DateFormat('dd MMM yyyy').format(ts.toDate())
        : '--';
    final time = ts != null
        ? DateFormat('hh:mm a').format(ts.toDate())
        : '';
    final validUntil = data['validUntil'] as Timestamp?;
    final validStr = validUntil != null
        ? DateFormat('dd MMM yyyy').format(validUntil.toDate())
        : null;
    final markedBy = data['markedBy'] ?? 'owner';
    final staffName = data['staffName'] ?? '';
    final transactionId =
        data['transactionId'] ?? data['referenceCode'] ?? '--';
    final screenshotUrl =
        (data['screenshot'] ?? data['screenshotUrl'] ?? '') as String;

    Color statusColor;
    switch (status) {
      case 'completed':
        statusColor = Colors.greenAccent;
        break;
      case 'pending':
        statusColor = Colors.orangeAccent;
        break;
      case 'rejected':
        statusColor = Colors.redAccent;
        break;
      default:
        statusColor = Colors.white38;
    }

    Color methodColor;
    String methodLabel;
    switch (method) {
      case 'easypaisa':
        methodColor = Colors.greenAccent;
        methodLabel = 'Easypaisa';
        break;
      case 'jazzcash':
        methodColor = Colors.redAccent;
        methodLabel = 'JazzCash';
        break;
      default:
        methodColor = Colors.blueAccent;
        methodLabel = 'Cash';
    }

    String recordedBy;
    if (markedBy == 'online') {
      recordedBy = 'Online payment';
    } else if (markedBy == 'staff') {
      recordedBy = 'Staff${staffName.isNotEmpty ? ' · $staffName' : ''}';
    } else {
      recordedBy = 'Owner';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Rs ${amount.toStringAsFixed(0)}",
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20),
                      ),
                      const SizedBox(height: 3),
                      Text("$date  $time",
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(status.toUpperCase(),
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: methodColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(methodLabel,
                          style: TextStyle(
                              color: methodColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Details ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _row("Plan", plan, Colors.white70),
                const SizedBox(height: 5),
                _row("Recorded by", recordedBy, Colors.white54),
                const SizedBox(height: 5),
                _row("Txn ID", transactionId, Colors.blueAccent),
                if (validStr != null) ...[
                  const SizedBox(height: 5),
                  _row("Valid until", validStr, Colors.purpleAccent),
                ],
              ],
            ),
          ),

          // ── Screenshot ──────────────────────────────────────
          if (screenshotUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ScreenshotThumbnail(url: screenshotUrl),
            ),
          ],

          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color valueColor) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text("$label:",
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  color: valueColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _ScreenshotThumbnail extends StatelessWidget {
  final String url;
  const _ScreenshotThumbnail({required this.url});

  void _view(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const SizedBox(
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(
                              color: Colors.yellowAccent),
                        ),
                      ),
                errorBuilder: (_, __, ___) => const SizedBox(
                  height: 200,
                  child: Center(
                    child: Text("Failed to load image",
                        style: TextStyle(color: Colors.white54)),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                      color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _view(context),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const Center(
                        child: CircularProgressIndicator(
                            color: Colors.yellowAccent, strokeWidth: 2)),
                errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image,
                        color: Colors.white24, size: 28)),
              ),
              Container(
                color: Colors.black.withOpacity(0.35),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.zoom_in_rounded,
                        color: Colors.white70, size: 16),
                    SizedBox(width: 6),
                    Text("Payment screenshot",
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}