import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class UserPaymentHistoryScreen extends StatelessWidget {
  const UserPaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "PAYMENT HISTORY",
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
        builder: (context, userSnap) {
          if (userSnap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.yellowAccent),
            );
          }
          if (!userSnap.hasData || !userSnap.data!.exists) {
            return _emptyState("Could not load profile.");
          }

          final gymId = userSnap.data!['gymId'] ?? '';
          if (gymId.isEmpty) {
            return _emptyState("No gym assigned to your account.");
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('gyms')
                .doc(gymId)
                .collection('payments')
                .where('memberId', isEqualTo: uid)
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.yellowAccent),
                );
              }
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return _emptyState("No payment records found.");
              }

              final docs = snap.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return _PaymentCard(data: data);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _emptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              color: Colors.white10, size: 60),
          const SizedBox(height: 16),
          Text(msg,
              style: const TextStyle(color: Colors.white38, fontSize: 14)),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _PaymentCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    final method = (data['method'] ?? 'cash').toString().toLowerCase();
    final plan = data['plan'] ?? 'Monthly';
    final status = (data['status'] ?? 'completed').toString().toLowerCase();
    final ts = data['timestamp'] as Timestamp?;
    final date = ts != null
        ? DateFormat('dd MMM yyyy · hh:mm a').format(ts.toDate())
        : '--';
    final validUntil = data['validUntil'] as Timestamp?;
    final validStr = validUntil != null
        ? DateFormat('dd MMM yyyy').format(validUntil.toDate())
        : null;
    final screenshotUrl = (data['screenshot'] ?? data['screenshotUrl'] ?? '') as String;
    final referenceCode = data['referenceCode'] ?? data['transactionId'] ?? '--';

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'completed':
        statusColor = Colors.greenAccent;
        statusLabel = 'PAID';
        break;
      case 'pending':
        statusColor = Colors.orangeAccent;
        statusLabel = 'PENDING';
        break;
      case 'rejected':
        statusColor = Colors.redAccent;
        statusLabel = 'REJECTED';
        break;
      default:
        statusColor = Colors.white38;
        statusLabel = status.toUpperCase();
    }

    Color methodColor;
    String methodLabel;
    IconData methodIcon;
    switch (method) {
      case 'easypaisa':
        methodColor = Colors.greenAccent;
        methodLabel = 'Easypaisa';
        methodIcon = Icons.account_balance_wallet;
        break;
      case 'jazzcash':
        methodColor = Colors.redAccent;
        methodLabel = 'JazzCash';
        methodIcon = Icons.phonelink_ring;
        break;
      default:
        methodColor = Colors.blueAccent;
        methodLabel = 'Cash';
        methodIcon = Icons.payments_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: methodColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(methodIcon, color: methodColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Rs ${amount.toStringAsFixed(0)}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(date,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
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
                const SizedBox(height: 6),
                _row("Method", methodLabel, methodColor),
                const SizedBox(height: 6),
                _row("Reference", referenceCode, Colors.blueAccent),
                if (validStr != null) ...[
                  const SizedBox(height: 6),
                  _row("Valid until", validStr, Colors.purpleAccent),
                ],
                if (status == 'rejected') ...[
                  const SizedBox(height: 6),
                  _row("Note",
                      "Payment was rejected. Contact your gym.",
                      Colors.redAccent),
                ],
              ],
            ),
          ),

          // ── Screenshot ──────────────────────────────────────
          if (screenshotUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ScreenshotThumbnail(url: screenshotUrl),
            ),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color valueColor) {
    return Row(
      children: [
        Text("$label: ",
            style:
                const TextStyle(color: Colors.white38, fontSize: 12)),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  color: valueColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
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
                      color: Colors.black54,
                      shape: BoxShape.circle),
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