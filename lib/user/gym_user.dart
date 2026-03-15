import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firestore_service.dart';
import 'screens/stats_tile.dart';
import 'screens/payment_card.dart';
import 'screens/attendance_calendar.dart';
import 'screens/skeleton_loaders.dart'; // ← NEW
import '../qr_scan.dart';
import 'package:intl/intl.dart';
import '../auth/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GymUser extends StatefulWidget {
  const GymUser({super.key});

  @override
  State<GymUser> createState() => _GymUserScreen();
}

class _GymUserScreen extends State<GymUser> {
  final user = FirebaseAuth.instance.currentUser!;
  final FirestoreService _fs = FirestoreService();

  String gymId = "";
  String userName = "Athlete";
  String feeStatus = "unpaid";
  String plan = "Standard";
  String expiryDate = "---";
  bool isPaid = false;
  bool _isLoading = true; // ← NEW

  DateTime focusedDay = DateTime.now();
  DateTime selectedDay = DateTime.now();
  Set<String> presentDates = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // Only show skeleton on first load, not on pull-to-refresh
    if (!_isLoading) setState(() => _isLoading = true);

    final userData = await _fs.getUserData(user.uid);
    if (userData == null) {
      setState(() => _isLoading = false);
      return;
    }

    gymId = userData['gymId'] ?? "";
    userName = userData['name'] ?? "Athlete";

    if (gymId.isNotEmpty) {
      final memberData = await _fs.getMemberData(gymId, user.uid);
      if (memberData != null) {
        feeStatus = memberData['feeStatus'] ?? "unpaid";
        plan = memberData['plan'] ?? "Monthly";
        isPaid = feeStatus.toLowerCase() == "paid";
        if (memberData['validUntil'] != null) {
          DateTime date = (memberData['validUntil'] as Timestamp).toDate();
          expiryDate = DateFormat('dd MMM yyyy').format(date);
        }
      }

      final attendance = await _fs.getAttendance(gymId, user.uid);
      presentDates = attendance;
    }

    setState(() => _isLoading = false);
  }

  void _openQRScanner() async {
    final scannedCode = await Navigator.push<String>(
        context, MaterialPageRoute(builder: (_) => const QRScannerPage()));
    if (scannedCode != null && scannedCode.isNotEmpty) {
      await _markAttendance();
    }
  }

  Future<void> _markAttendance() async {
    final todayKey =
        "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";

    if (presentDates.contains(todayKey)) {
      _showSnackBar("ℹ️ Already checked in today", Colors.orange);
      return;
    }

    await _fs.markAttendance(gymId, user.uid);
    setState(() => presentDates.add(todayKey));
    _showSnackBar("✅ Attendance marked", Colors.green);
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black,
        title: const Text("PRO TRACKER",
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.yellowAccent)),
        actions: [
          IconButton(
              onPressed: () async {


                try {
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const Login()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
      }

    }
              },
              icon: const Icon(Icons.logout, color: Colors.yellowAccent))
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openQRScanner,
        backgroundColor: Colors.yellowAccent,
        icon: const Icon(Icons.qr_code_scanner, color: Colors.black),
        label: const Text("CHECK IN",
            style:
                TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      // ── SKELETON vs real content ──────────────────────────────────────
      body: _isLoading
          ? const GymUserSkeleton() // ← skeleton while loading
          : RefreshIndicator(
              onRefresh: _loadUserData,
              color: Colors.yellowAccent,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Welcome back,",
                        style: TextStyle(fontSize: 16, color: Colors.grey)),
                    Text(userName.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(
                            child: StatsTile(
                                label: "SESSIONS",
                                value: "${presentDates.length}",
                                icon: Icons.bolt)),
                        const SizedBox(width: 15),
                        Expanded(
                            child: StatsTile(
                                label: "PLAN",
                                value: plan,
                                icon: Icons.workspace_premium)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    PaymentCard(
                        feeStatus: feeStatus,
                        isPaid: isPaid,
                        expiryDate: expiryDate,
                        onPay: _showPaymentSheet),
                    const SizedBox(height: 30),
                    const Text("ATTENDANCE HISTORY",
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.yellowAccent,
                            letterSpacing: 1.5)),
                    const SizedBox(height: 15),
                    AttendanceCalendar(
                      focusedDay: focusedDay,
                      selectedDay: selectedDay,
                      presentDates: presentDates,
                      onDaySelected: (day) =>
                          setState(() {
                            selectedDay = day;
                            focusedDay = day;
                          }),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }

  void _showPaymentSheet() async {
    final List<Map<String, dynamic>> gateways =
        await _fs.getGymGateways(gymId);

    if (!mounted) return;

    if (gateways.isEmpty) {
      _showSnackBar(
          "No payment methods available for this gym.", Colors.orange);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(30, 15, 30, 30),
        decoration: const BoxDecoration(
          color: Color(0xFF121212),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              "CHOOSE PAYMENT METHOD",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: gateways.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: Colors.white10),
              itemBuilder: (context, index) {
                final gateway = gateways[index];
                final String type =
                    (gateway['gateway'] ?? 'other').toLowerCase();
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _getGatewayIcon(type),
                  title: Text(type.toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: Text("Pay with your $type wallet",
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios,
                      color: Colors.white24, size: 16),
                  onTap: () => Navigator.pop(context),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _getGatewayIcon(String type) {
    IconData iconData;
    switch (type) {
      case 'easypaisa':
        iconData = Icons.account_balance_wallet;
        break;
      case 'jazzcash':
        iconData = Icons.phonelink_ring;
        break;
      case 'stripe':
      case 'card':
        iconData = Icons.credit_card;
        break;
      default:
        iconData = Icons.payment;
    }
    return CircleAvatar(
      backgroundColor: Colors.white.withOpacity(0.05),
      child: Icon(iconData, color: Colors.yellowAccent),
    );
  }
}