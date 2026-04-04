import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../shared/skeleton_loaders.dart';

const _kPageSize = 10;

class PaymentHistoryScreen extends StatefulWidget {
  final String uid;
  final String gymId;

  const PaymentHistoryScreen(
      {super.key, required this.uid, required this.gymId});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final List<Map<String, dynamic>> _records = [];
  DocumentSnapshot? _lastDoc;
  bool _loading = false;
  bool _initialLoad = true;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetchPage();
  }

  Future<void> _fetchPage() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);

    Query q = FirebaseFirestore.instance
        .collection('gyms')
        .doc(widget.gymId)
        .collection('payments')
        .where('memberId', isEqualTo: widget.uid)
        .orderBy('timestamp', descending: true)
        .limit(_kPageSize);

    if (_lastDoc != null) q = q.startAfterDocument(_lastDoc!);

    final snap = await q.get();
    if (!mounted) return;

    if (snap.docs.isEmpty) {
      setState(() {
        _hasMore = false;
        _loading = false;
        _initialLoad = false;
      });
      return;
    }

    _lastDoc = snap.docs.last;
    setState(() {
      _records.addAll(
          snap.docs.map((d) => d.data() as Map<String, dynamic>));
      _hasMore = snap.docs.length == _kPageSize;
      _loading = false;
      _initialLoad = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "PAYMENT HISTORY",
          style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _initialLoad
          ? const PaymentHistorySkeleton()
          : _records.isEmpty
              ? _emptyState(Icons.history, "No payment history found")
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _records.length + 1,
                  itemBuilder: (context, index) {
                    if (index < _records.length) {
                      return _OwnerPaymentCard(data: _records[index]);
                    }
                    // Footer
                    if (_loading) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.yellowAccent,
                                strokeWidth: 2),
                          ),
                        ),
                      );
                    }
                    if (!_hasMore) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text("No more records",
                              style: TextStyle(
                                  color: Colors.white24, fontSize: 12)),
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: _LoadMoreButton(onTap: _fetchPage),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _emptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white10, size: 60),
          const SizedBox(height: 15),
          Text(message,
              style:
                  const TextStyle(color: Colors.white38, fontSize: 14)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Load More Button
// ─────────────────────────────────────────────────────────────
class _LoadMoreButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LoadMoreButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 28, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border:
              Border.all(color: Colors.yellowAccent.withOpacity(0.4)),
          color: Colors.yellowAccent.withOpacity(0.06),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.expand_more_rounded,
                color: Colors.yellowAccent, size: 18),
            SizedBox(width: 6),
            Text("Load more",
                style: TextStyle(
                    color: Colors.yellowAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Payment Card (owner view)
// ─────────────────────────────────────────────────────────────
class _OwnerPaymentCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _OwnerPaymentCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    final method = (data['method'] ?? 'cash').toString().toLowerCase();
    final plan = data['plan'] ?? 'Monthly';
    final status =
        (data['status'] ?? 'completed').toString().toLowerCase();
    final ts = data['timestamp'] as Timestamp?;
    final date =
        ts != null ? DateFormat('dd MMM yyyy').format(ts.toDate()) : '--';
    final time =
        ts != null ? DateFormat('hh:mm a').format(ts.toDate()) : '';
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

    // Status colour
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

    // Method colour & label
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
      recordedBy =
          'Staff${staffName.isNotEmpty ? ' · $staffName' : ''}';
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
          // ── Top row ─────────────────────────────────────────
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
                    _badge(status.toUpperCase(), statusColor),
                    const SizedBox(height: 6),
                    _badge(methodLabel, methodColor),
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

          // ── Screenshot button (lazy) ─────────────────────────
          if (screenshotUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ViewScreenshotButton(url: screenshotUrl),
            ),
          ],

          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8)),
    );
  }

  Widget _row(String label, String value, Color valueColor) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text("$label:",
              style:
                  const TextStyle(color: Colors.white38, fontSize: 11)),
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

// ─────────────────────────────────────────────────────────────
//  Lazy "View Screenshot" button — shared by both files
// ─────────────────────────────────────────────────────────────
class _ViewScreenshotButton extends StatelessWidget {
  final String url;
  const _ViewScreenshotButton({required this.url});

  void _open(BuildContext context) {
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
                        height: 260,
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
      onTap: () => _open(context),
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: Colors.yellowAccent.withOpacity(0.25)),
          color: Colors.yellowAccent.withOpacity(0.05),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_search_rounded,
                color: Colors.yellowAccent, size: 16),
            SizedBox(width: 8),
            Text("View Payment Screenshot",
                style: TextStyle(
                    color: Colors.yellowAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3)),
          ],
        ),
      ),
    );
  }
}