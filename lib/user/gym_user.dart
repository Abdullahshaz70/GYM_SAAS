import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firestore_service.dart';
import 'screens/stats_tile.dart';
import 'screens/payment_card.dart';
import 'screens/attendance_calendar.dart';
import '../qr_scan.dart';
import 'package:intl/intl.dart';
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

  DateTime focusedDay = DateTime.now();
  DateTime selectedDay = DateTime.now();
  Set<String> presentDates = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await _fs.getUserData(user.uid);
    if (userData == null) return;

    setState(() {
      gymId = userData['gymId'] ?? "";
      userName = userData['name'] ?? "Athlete";
    });

    if (gymId.isNotEmpty) {
      final memberData = await _fs.getMemberData(gymId, user.uid);
      if (memberData != null) {
        setState(() {
          feeStatus = memberData['feeStatus'] ?? "unpaid";
          plan = memberData['plan'] ?? "Monthly";
          isPaid = feeStatus.toLowerCase() == "paid";
          if (memberData['validUntil'] != null) {
            DateTime date = (memberData['validUntil'] as Timestamp).toDate();
            expiryDate = DateFormat('dd MMM yyyy').format(date);
          }
        });
      }

      final attendance = await _fs.getAttendance(gymId, user.uid);
      setState(() => presentDates = attendance);
    }
  }

  void _openQRScanner() async {
    final scannedCode = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const QRScannerPage()));
    if (scannedCode != null && scannedCode.isNotEmpty) {
      await _markAttendance();
    }
  }

  Future<void> _markAttendance() async {
    final todayKey = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2,'0')}-${DateTime.now().day.toString().padLeft(2,'0')}";

    if (presentDates.contains(todayKey)) {
      _showSnackBar("ℹ️ Already checked in today", Colors.orange);
      return;
    }

    await _fs.markAttendance(gymId, user.uid);
    setState(() => presentDates.add(todayKey));
    _showSnackBar("✅ Attendance marked", Colors.green);
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black,
        title: const Text("PRO TRACKER", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.yellowAccent)),
        actions: [
          IconButton(onPressed: () => FirebaseAuth.instance.signOut(), icon: const Icon(Icons.logout, color: Colors.yellowAccent))
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openQRScanner,
        backgroundColor: Colors.yellowAccent,
        icon: const Icon(Icons.qr_code_scanner, color: Colors.black),
        label: const Text("CHECK IN", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        color: Colors.yellowAccent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Welcome back,", style: TextStyle(fontSize: 16, color: Colors.grey)),
              Text(userName.toUpperCase(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(child: StatsTile(label: "SESSIONS", value: "${presentDates.length}", icon: Icons.bolt)),
                  const SizedBox(width: 15),
                  Expanded(child: StatsTile(label: "PLAN", value: plan, icon: Icons.workspace_premium)),
                ],
              ),
              const SizedBox(height: 20),
              PaymentCard(feeStatus: feeStatus, isPaid: isPaid, expiryDate: expiryDate, onPay: _showPaymentSheet),
              const SizedBox(height: 30),
              const Text("ATTENDANCE HISTORY", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.yellowAccent, letterSpacing: 1.5)),
              const SizedBox(height: 15),
              AttendanceCalendar(
                focusedDay: focusedDay,
                selectedDay: selectedDay,
                presentDates: presentDates,
                onDaySelected: (day) => setState(() { selectedDay = day; focusedDay = day; }),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(30),
        decoration: const BoxDecoration(color: Color(0xFF121212), borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 25),
            const Text("UPI PAYMENT", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet, color: Colors.yellowAccent),
              title: const Text("Pay via Google Pay / PhonePe", style: TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.chevron_right, color: Colors.white24),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
