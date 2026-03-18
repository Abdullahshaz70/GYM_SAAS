import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class PaymentPendingScreen extends StatelessWidget {
  final String gymId;
  final String paymentId;
  final String referenceCode;
  final double amount;

  const PaymentPendingScreen({
    super.key,
    required this.gymId,
    required this.paymentId,
    required this.referenceCode,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final FirestoreService fs = FirestoreService();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('PAYMENT STATUS',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: fs.watchPayment(gymId, paymentId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child:
                    CircularProgressIndicator(color: Colors.yellowAccent));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final status = data?['status'] ?? 'pending';

          if (status == 'completed') {
            return _buildVerified(context);
          }

          if (status == 'failed') {
            return _buildFailed(context);
          }

          return _buildPending(context);
        },
      ),
    );
  }

  Widget _buildPending(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.07),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.hourglass_top_rounded,
                color: Colors.orangeAccent, size: 52),
          ),
          const SizedBox(height: 24),
          const Text('Verification Pending',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text(
            'Your payment screenshot has been submitted.\nOur team will verify it shortly.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 36),
          _infoCard(
            label: 'Amount Submitted',
            value: 'Rs ${amount.toStringAsFixed(0)}',
            color: Colors.yellowAccent,
          ),
          const SizedBox(height: 12),
          _infoCard(
            label: 'Reference Code',
            value: referenceCode,
            color: Colors.blueAccent,
            copyable: true,
            context: context,
          ),
          const SizedBox(height: 36),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white38, size: 18),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This page updates automatically once your payment is verified. You can also close it and check back later.',
                    style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('BACK TO HOME',
                  style: TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerified(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: Colors.greenAccent, size: 52),
          ),
          const SizedBox(height: 24),
          const Text('Payment Verified!',
              style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text(
            'Your membership is now active.\nEnjoy your workouts!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellowAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('GO TO HOME',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailed(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cancel_rounded,
                color: Colors.redAccent, size: 52),
          ),
          const SizedBox(height: 24),
          const Text('Payment Rejected',
              style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text(
            'Your payment could not be verified.\nPlease contact support or try again.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellowAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('TRY AGAIN',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required String label,
    required String value,
    required Color color,
    bool copyable = false,
    BuildContext? context,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11)),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1)),
              ],
            ),
          ),
          if (copyable && context != null)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Copied!'),
                    behavior: SnackBarBehavior.floating));
              },
              child: const Icon(Icons.copy_rounded,
                  color: Colors.white38, size: 18),
            ),
        ],
      ),
    );
  }
}