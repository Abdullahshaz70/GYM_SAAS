import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'Member Attendence/attendance_screen.dart';
import 'Member Payment/payment_history_screen.dart';
import 'Membership Details/membership_screen.dart';
import '../user/screens/skeleton_loaders.dart'; // ← NEW

class MemberDetailScreen extends StatefulWidget {
  final String uid;
  final String gymId;

  const MemberDetailScreen(
      {super.key, required this.uid, required this.gymId});

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  bool loading = true;
  String name = '';
  String plan = '';
  DateTime? joinedAt;
  DateTime? validUntil;
  num currentFee = 0;
  String feeStatus = '';
  String contactNumber = '';
  List<Map<String, dynamic>> recentPayments = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final firestore = FirebaseFirestore.instance;
    try {
      final userDoc =
          await firestore.collection('users').doc(widget.uid).get();
      final memberDoc = await firestore
          .collection('gyms')
          .doc(widget.gymId)
          .collection('members')
          .doc(widget.uid)
          .get();

      // Read from payments collection — single source of truth
      final paymentsSnapshot = await firestore
          .collection('gyms')
          .doc(widget.gymId)
          .collection('payments')
          .where('memberId', isEqualTo: widget.uid)
          .orderBy('timestamp', descending: true)
          .limit(3)
          .get();

      setState(() {
        name = userDoc.data()?['name'] ?? 'Unknown';
        contactNumber = userDoc.data()?['contactNumber'] ?? '--';
        plan = memberDoc.data()?['plan'] ?? 'free';
        currentFee = memberDoc.data()?['currentFee'] ?? 0;
        feeStatus = memberDoc.data()?['feeStatus'] ?? 'unpaid';
        joinedAt =
            (memberDoc.data()?['createdAt'] as Timestamp?)?.toDate();
        validUntil =
            (memberDoc.data()?['validUntil'] as Timestamp?)?.toDate();
        recentPayments = paymentsSnapshot.docs.map((doc) => doc.data()).toList();
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      debugPrint('Member fetch error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text("MEMBER PROFILE",
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // ── SKELETON vs real content ──────────────────────────────────────
      body: loading
          ? const MemberDetailSkeleton() // ← skeleton while loading
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    bool isPaid = feeStatus.toLowerCase() == 'paid';

    return SingleChildScrollView(
      // padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          _buildProfileHeader(isPaid),
          const SizedBox(height: 25),
          _buildActionRow(),
          const SizedBox(height: 30),
          _buildNavigationTile("Attendance History",
              Icons.calendar_today_rounded, () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AttendanceScreen(
                        uid: widget.uid, gymId: widget.gymId)));
          }),
          _buildNavigationTile(
              "Payment History", Icons.account_balance_wallet_rounded, () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => PaymentHistoryScreen(
                        uid: widget.uid, gymId: widget.gymId)));
          }),
          const SizedBox(height: 12),
          // ── Record Payment ────────────────────────────────
          _buildRecordPaymentTile(),
          const SizedBox(height: 25),
          _buildSubscriptionCard(),
          const SizedBox(height: 30),
          _sectionHeader("RECENT TRANSACTIONS"),
          const SizedBox(height: 12),
          if (recentPayments.isEmpty)
            const Center(
                child: Text("No records found",
                    style:
                        TextStyle(color: Colors.white24, fontSize: 12)))
          else
            ...recentPayments.map((p) => _paymentTile(p)),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(bool isPaid) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 55,
              backgroundColor: Colors.yellowAccent.withOpacity(0.1),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                    fontSize: 45,
                    color: Colors.yellowAccent,
                    fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                  color: Colors.black, shape: BoxShape.circle),
              child: Icon(
                isPaid ? Icons.check_circle : Icons.error,
                color: isPaid ? Colors.greenAccent : Colors.redAccent,
                size: 28,
              ),
            )
          ],
        ),
        const SizedBox(height: 15),
        Text(name,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isPaid
                ? Colors.greenAccent.withOpacity(0.1)
                : Colors.redAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: isPaid
                    ? Colors.greenAccent.withOpacity(0.5)
                    : Colors.redAccent.withOpacity(0.5)),
          ),
          child: Text(
            feeStatus.toUpperCase(),
            style: TextStyle(
              color: isPaid ? Colors.greenAccent : Colors.redAccent,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _actionCircle(
            Icons.phone_rounded, "Call", Colors.blue, _makeCall),
        const SizedBox(width: 40),
        _actionCircle(Icons.chat_bubble_rounded, "WhatsApp",
            Colors.greenAccent, _sendWhatsApp),
      ],
    );
  }

  Widget _actionCircle(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildNavigationTile(
      String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        tileColor: Colors.white.withOpacity(0.04),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.white10)),
        leading: Icon(icon, color: Colors.yellowAccent, size: 22),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded,
            color: Colors.white24, size: 14),
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    return Column(
      children: [
        _sectionHeader("MEMBERSHIP DETAILS"),
        const SizedBox(height: 12),
        _membershipListTile(Icons.fitness_center_rounded, "Plan Type",
            plan, Colors.blueAccent,
            () => _navigateToEdit("plan", plan)),
        _membershipListTile(Icons.currency_rupee_rounded, "Fees Amount",
            "Rs $currentFee", Colors.orangeAccent,
            () => _navigateToEdit("fee", currentFee.toString())),
        _membershipListTile(
          Icons.calendar_month_rounded,
          "Valid Until",
          validUntil != null
              ? DateFormat('dd MMM yyyy').format(validUntil!)
              : "--",
          Colors.purpleAccent,
          () => _navigateToEdit("validity", validUntil.toString()),
        ),
      ],
    );
  }

  void _navigateToEdit(String fieldType, String currentValue) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MembershipEditScreen(
          uid: widget.uid,
          gymId: widget.gymId,
          fieldType: fieldType,
          currentValue: currentValue,
        ),
      ),
    ).then((_) => fetchData());
  }

  Widget _membershipListTile(IconData icon, String label, String value,
      Color accentColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding:
            const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, color: accentColor, size: 22),
            const SizedBox(width: 15),
            Text(label,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 14)),
            const Spacer(),
            Text(value,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white24, size: 12),
          ],
        ),
      ),
    );
  }

  Widget _paymentTile(Map<String, dynamic> p) {
    final amount = p['amount'] ?? 0;
    final method = (p['method'] ?? 'cash').toString().toUpperCase();
    final plan = p['plan'] ?? 'Monthly';
    final markedBy = p['markedBy'] ?? 'owner';
    final ts = p['timestamp'] as Timestamp?;
    final date = ts != null
        ? DateFormat('dd MMM yyyy').format(ts.toDate())
        : '--';

    // Badge color per method
    final Color methodColor;
    switch ((p['method'] ?? '').toString().toLowerCase()) {
      case 'easypaisa':
        methodColor = Colors.greenAccent;
        break;
      case 'jazzcash':
        methodColor = Colors.redAccent;
        break;
      default:
        methodColor = Colors.blueAccent;
    }

    // Who recorded it
    String recordedBy;
    if (markedBy == 'online') {
      recordedBy = 'Online payment';
    } else if (markedBy == 'staff') {
      recordedBy = 'By staff · ${p['staffName'] ?? ''}';
    } else {
      recordedBy = 'By owner';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.greenAccent.withOpacity(0.1),
            child: const Icon(Icons.done_rounded,
                color: Colors.greenAccent, size: 16),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                Text(recordedBy,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("Rs $amount",
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: methodColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(method,
                        style: TextStyle(
                            color: methodColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              Text(date,
                  style: const TextStyle(
                      color: Colors.white24, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Record Payment tile ──────────────────────────────────────────────
  Widget _buildRecordPaymentTile() {
    return GestureDetector(
      onTap: _showRecordPaymentSheet,
      child: Container(
        margin: const EdgeInsets.only(bottom: 0),
        child: ListTile(
          tileColor: Colors.greenAccent.withOpacity(0.06),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.greenAccent.withOpacity(0.2))),
          leading: const Icon(Icons.payments_rounded,
              color: Colors.greenAccent, size: 22),
          title: const Text("Record Payment",
              style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          subtitle: const Text("Mark fees as paid & log transaction",
              style: TextStyle(color: Colors.white38, fontSize: 11)),
          trailing: const Icon(Icons.arrow_forward_ios_rounded,
              color: Colors.greenAccent, size: 14),
        ),
      ),
    );
  }

  // ── Record Payment bottom sheet ──────────────────────────────────────
  void _showRecordPaymentSheet() {
    // Local state inside the sheet
    String selectedMethod = 'cash';
    final txnController = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                decoration: const BoxDecoration(
                  color: Color(0xFF121212),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Header
                    Row(
                      children: [
                        const Icon(Icons.payments_rounded,
                            color: Colors.greenAccent, size: 20),
                        const SizedBox(width: 10),
                        const Text("RECORD PAYMENT",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                letterSpacing: 1)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$name  ·  $plan  ·  Rs $currentFee",
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 12),
                    ),
                    const SizedBox(height: 24),

                    // Payment method selector
                    const Text("PAYMENT METHOD",
                        style: TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _methodChip("cash", "💵 Cash",
                            selectedMethod, (v) => setSheetState(() => selectedMethod = v)),
                        const SizedBox(width: 10),
                        _methodChip("easypaisa", "🟢 Easypaisa",
                            selectedMethod, (v) => setSheetState(() => selectedMethod = v)),
                        const SizedBox(width: 10),
                        _methodChip("jazzcash", "🔴 JazzCash",
                            selectedMethod, (v) => setSheetState(() => selectedMethod = v)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Transaction ID (optional for cash, required for others)
                    TextField(
                      controller: txnController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: selectedMethod == 'cash'
                            ? "Transaction ID (optional)"
                            : "Transaction ID *",
                        labelStyle:
                            const TextStyle(color: Colors.white38),
                        hintText: "e.g. TXN-123456",
                        hintStyle:
                            const TextStyle(color: Colors.white24, fontSize: 12),
                        prefixIcon: const Icon(Icons.tag_rounded,
                            color: Colors.white38, size: 18),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Colors.greenAccent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Confirm button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                // Validate txn ID for online methods
                                if (selectedMethod != 'cash' &&
                                    txnController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text(
                                        "Transaction ID is required for online payments"),
                                    backgroundColor: Colors.redAccent,
                                    behavior: SnackBarBehavior.floating,
                                  ));
                                  return;
                                }

                                setSheetState(() => isSaving = true);
                                await _recordPayment(
                                  method: selectedMethod,
                                  txnId: txnController.text.trim(),
                                );
                                if (sheetCtx.mounted) {
                                  Navigator.pop(sheetCtx);
                                }
                              },
                        child: isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black))
                            : Text(
                                "CONFIRM  ·  Rs $currentFee",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    letterSpacing: 0.5),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _methodChip(String value, String label, String selected,
      ValueChanged<String> onSelect) {
    final bool isSelected = selected == value;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.greenAccent.withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isSelected
                  ? Colors.greenAccent.withOpacity(0.6)
                  : Colors.white12),
        ),
        child: Text(label,
            style: TextStyle(
                color: isSelected ? Colors.greenAccent : Colors.white54,
                fontSize: 12,
                fontWeight: isSelected
                    ? FontWeight.bold
                    : FontWeight.normal)),
      ),
    );
  }

  // ── Core Firestore write ─────────────────────────────────────────────
  Future<void> _recordPayment({
    required String method,
    required String txnId,
  }) async {
    try {
      final now = DateTime.now();
      final nowTs = Timestamp.fromDate(now);

      // Calculate new validUntil from today based on plan
      int months = 1;
      if (plan == '6 Months') months = 6;
      if (plan == 'Yearly') months = 12;
      final newValidUntil =
          Timestamp.fromDate(DateTime(now.year, now.month + months, now.day));

      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      // 1. gyms/{gymId}/payments/{auto}
      final payRef =
          db.collection('gyms').doc(widget.gymId).collection('payments').doc();
      batch.set(payRef, {
        'memberId': widget.uid,
        'amount': currentFee,
        'method': method,
        'verified': true,
        'timestamp': nowTs,
        'transactionId': txnId.isEmpty
            ? 'CASH-${now.millisecondsSinceEpoch}'
            : txnId,
        'plan': plan,
        'validUntil': newValidUntil,
        'createdAt': nowTs,
        'status': 'completed',
        'updatedAt': nowTs,
        'markedBy': 'owner',
      });

      // 2. gyms/{gymId}/members/{uid}
      final memberRef = db
          .collection('gyms')
          .doc(widget.gymId)
          .collection('members')
          .doc(widget.uid);
      batch.update(memberRef, {
        'feeStatus': 'paid',
        'validUntil': newValidUntil,
        'lastPaidAt': nowTs,
      });

      await batch.commit();

      // Refresh the screen so header badge + fee list update
      await fetchData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              "✅ Rs $currentFee recorded via ${method.toUpperCase()}"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      }
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

  Widget _sectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title,
          style: const TextStyle(
              color: Colors.yellowAccent,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0)),
    );
  }


  void _makeCall() async {
    if (contactNumber.isNotEmpty) {
      final Uri url = Uri.parse("tel:$contactNumber");
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  void _sendWhatsApp() async {
  if (contactNumber.isNotEmpty) {
    String cleanNumber = contactNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final Uri url = Uri.parse("https://wa.me/$cleanNumber");
    
    if (await canLaunchUrl(url)) {
      await launchUrl(
        url, 
        mode: LaunchMode.externalApplication, 
      );
    } else {
      print("Could not launch WhatsApp for $url");
    }
  }
}


}