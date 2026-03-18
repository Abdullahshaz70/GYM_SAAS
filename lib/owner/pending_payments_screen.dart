import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PendingPaymentsScreen extends StatefulWidget {
  final String gymId;

  const PendingPaymentsScreen({super.key, required this.gymId});

  @override
  State<PendingPaymentsScreen> createState() => _PendingPaymentsScreenState();
}

class _PendingPaymentsScreenState extends State<PendingPaymentsScreen> {
  bool loading = true;
  List<Map<String, dynamic>> pendingPayments = [];

  @override
  void initState() {
    super.initState();
    _fetchPending();
  }

  Future<void> _fetchPending() async {
    setState(() => loading = true);
    final firestore = FirebaseFirestore.instance;

    try {
      final snap = await firestore
          .collection('gyms')
          .doc(widget.gymId)
          .collection('payments')
          .where('status', isEqualTo: 'pending')
          .get();

      List<Map<String, dynamic>> results = [];

      for (final doc in snap.docs) {
        final data = doc.data();
        final memberId = data['memberId'] ?? '';

        // Fetch member name
        String memberName = 'Unknown';
        try {
          final userDoc =
              await firestore.collection('users').doc(memberId).get();
          memberName = userDoc.data()?['name'] ?? 'Unknown';
        } catch (_) {}

        results.add({
          'paymentId': doc.id,
          'memberId': memberId,
          'memberName': memberName,
          'amount': data['amount'] ?? 0,
          'method': data['method'] ?? 'online',
          'plan': data['plan'] ?? 'Monthly',
          'referenceCode': data['referenceCode'] ?? '--',
          'screenshotUrl': data['screenshot'] ?? '',
          'createdAt': data['createdAt'],
          'validUntil': data['validUntil'],
        });
      }

      setState(() {
        pendingPayments = results;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  Future<void> _approve(Map<String, dynamic> payment) async {
    final firestore = FirebaseFirestore.instance;
    final paymentId = payment['paymentId'];
    final memberId = payment['memberId'];
    final validUntil = payment['validUntil'];

    try {
      final batch = firestore.batch();

      // 1. Update payment → completed
      final payRef = firestore
          .collection('gyms')
          .doc(widget.gymId)
          .collection('payments')
          .doc(paymentId);
      batch.update(payRef, {
        'status': 'completed',
        'verified': true,
        'updatedAt': Timestamp.now(),
      });

      
      // 2. Update member → paid + validUntil
      final memberRef = firestore
          .collection('gyms')
          .doc(widget.gymId)
          .collection('members')
          .doc(memberId);

      final Map<String, dynamic> memberUpdate = {
        'feeStatus': 'paid',
        'updatedAt': Timestamp.now(),
      };
      if (validUntil != null) {
        memberUpdate['validUntil'] = validUntil;
      }
      batch.update(memberRef, memberUpdate);

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("✅ Payment approved!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      }
      await _fetchPending();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

 Future<void> _reject(Map<String, dynamic> payment) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text("Reject Payment?",
          style: TextStyle(color: Colors.white)),
      content: Text(
        "Reject payment from ${payment['memberName']}?\nMember will be marked as unpaid.",
        style: const TextStyle(color: Colors.white54, fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("CANCEL", style: TextStyle(color: Colors.white38)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
          onPressed: () => Navigator.pop(context, true),
          child: const Text("REJECT",
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  try {
    final firestore = FirebaseFirestore.instance;

    await Future.wait([
      // Mark the payment as rejected
      firestore
          .collection('gyms')
          .doc(widget.gymId)
          .collection('payments')
          .doc(payment['paymentId'])
          .update({
        'status': 'rejected',
        'updatedAt': Timestamp.now(),
      }),
      // Reset member fee status back to unpaid
      firestore
          .collection('gyms')
          .doc(widget.gymId)
          .collection('members')
          .doc(payment['memberUid'])
          .update({
        'feeStatus': 'unpaid',
      }),
    ]);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Payment rejected — member marked unpaid."),
        backgroundColor: Colors.orangeAccent,
        behavior: SnackBarBehavior.floating,
      ));
    }

    await _fetchPending();
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error: $e"),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}
  void _viewScreenshot(String url) {
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
                    : const Center(
                        child: CircularProgressIndicator(
                            color: Colors.yellowAccent)),
                errorBuilder: (_, __, ___) => const Center(
                  child: Text("Failed to load image",
                      style: TextStyle(color: Colors.white54)),
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("PENDING PAYMENTS",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
            Text("${pendingPayments.length} awaiting review",
                style:
                    const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
      ),
      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(color: Colors.yellowAccent))
          : pendingPayments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline_rounded,
                          color: Colors.greenAccent.withOpacity(0.4),
                          size: 64),
                      const SizedBox(height: 16),
                      const Text("All caught up!",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      const Text("No pending payments to review.",
                          style: TextStyle(
                              color: Colors.white38, fontSize: 13)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchPending,
                  color: Colors.yellowAccent,
                  backgroundColor: Colors.grey[900],
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: pendingPayments.length,
                    itemBuilder: (context, index) {
                      return _buildPaymentCard(pendingPayments[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final method =
        (payment['method'] ?? 'online').toString().toLowerCase();
    final amount = (payment['amount'] as num).toDouble();
    final createdAt = (payment['createdAt'] as Timestamp?)?.toDate();
    final dateStr = createdAt != null
        ? DateFormat('dd MMM yyyy · hh:mm a').format(createdAt)
        : '--';
    final hasScreenshot = (payment['screenshotUrl'] as String).isNotEmpty;

    Color methodColor;
    String methodLabel;
    switch (method) {
      case 'easypaisa':
        methodColor = Colors.greenAccent;
        methodLabel = '🟢 Easypaisa';
        break;
      case 'jazzcash':
        methodColor = Colors.redAccent;
        methodLabel = '🔴 JazzCash';
        break;
      default:
        methodColor = Colors.blueAccent;
        methodLabel = '💳 Online';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.yellowAccent.withOpacity(0.1),
                  child: Text(
                    (payment['memberName'] ?? 'G')[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.yellowAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(payment['memberName'] ?? 'Unknown',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(dateStr,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.orangeAccent.withOpacity(0.3)),
                  ),
                  child: const Text("PENDING",
                      style: TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8)),
                ),
              ],
            ),
          ),

          // ── Info rows ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _infoRow("Amount",
                    "Rs ${amount.toStringAsFixed(0)}", Colors.white),
                const SizedBox(height: 8),
                _infoRow("Method", methodLabel, methodColor),
                const SizedBox(height: 8),
                _infoRow("Plan", payment['plan'] ?? '--', Colors.white70),
                const SizedBox(height: 8),
                _infoRow(
                    "Reference",
                    payment['referenceCode'] ?? '--',
                    Colors.blueAccent),
              ],
            ),
          ),

          // ── Screenshot preview ────────────────────────────────
          if (hasScreenshot) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _viewScreenshot(payment['screenshotUrl']),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                height: 120,
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
                        payment['screenshotUrl'],
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) =>
                            progress == null
                                ? child
                                : const Center(
                                    child: CircularProgressIndicator(
                                        color: Colors.yellowAccent,
                                        strokeWidth: 2)),
                        errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image,
                                color: Colors.white24)),
                      ),
                      Container(
                        alignment: Alignment.center,
                        color: Colors.black.withOpacity(0.3),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.zoom_in_rounded,
                                color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text("Tap to view",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // ── Action buttons ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _reject(payment),
                    icon: const Icon(Icons.close_rounded,
                        size: 16, color: Colors.redAccent),
                    label: const Text("REJECT",
                        style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: Colors.redAccent.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _approve(payment),
                    icon: const Icon(Icons.check_rounded,
                        size: 16, color: Colors.black),
                    label: const Text("APPROVE",
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, Color valueColor) {
    return Row(
      children: [
        Text("$label: ",
            style: const TextStyle(color: Colors.white38, fontSize: 12)),
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