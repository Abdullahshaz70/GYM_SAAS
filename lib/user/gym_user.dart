import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firestore_service.dart';
import 'screens/stats_tile.dart';
import 'screens/payment_card.dart';
import 'screens/attendance_calendar.dart';
import 'screens/skeleton_loaders.dart';
import '../qr_scan.dart';
import 'package:intl/intl.dart';
import '../auth/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/pay_fee_screen.dart';
import 'screens/user_payment_history_screen.dart'; 

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
  double currentFee = 0;
  bool isPaid = false;
  bool _isLoading = true;

  DateTime focusedDay = DateTime.now();
  DateTime selectedDay = DateTime.now();
  Set<String> presentDates = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
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
        currentFee = (memberData['currentFee'] as num?)?.toDouble() ?? 0;
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

  void _openPayFeeScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PayFeeScreen(
          gymId: gymId,
          memberId: user.uid,
          plan: plan,
          currentFee: currentFee,
        ),
      ),
    ).then((_) => _loadUserData());
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
      body: _isLoading
          ? const GymUserSkeleton()
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
                        onPay: _openPayFeeScreen,
                      ),
                      const SizedBox(height: 12),


                      GestureDetector(
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const UserPaymentHistoryScreen(),
    ),
  ),
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.blueAccent.withOpacity(0.06),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.receipt_long_rounded,
              color: Colors.blueAccent, size: 20),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "My Payment History",
                style: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
              SizedBox(height: 2),
              Text(
                "View all transactions & screenshots",
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
        const Icon(Icons.arrow_forward_ios_rounded,
            color: Colors.blueAccent, size: 14),
      ],
    ),
  ),
),
 
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
                      onDaySelected: (day) => setState(() {
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
}