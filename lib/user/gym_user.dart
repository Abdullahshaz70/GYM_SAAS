import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../qr_scan.dart';

class GymUser extends StatefulWidget {
  const GymUser({super.key});

  @override
  State<GymUser> createState() => _GymUser();
}

class _GymUser extends State<GymUser> {
  final user = FirebaseAuth.instance.currentUser!;
  DateTime focusedDay = DateTime.now();
  DateTime selectedDay = DateTime.now();

  Set<String> presentDates = {};
  String gymId = "";
  String userName = "Athlete";
  
  String feeStatus = "unpaid";
  String plan = "Standard";
  String expiryDate = "---";
  bool isPaid = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 1. FORMATTER: Converts DateTime to YYYY-MM-DD string for internal tracking
  String _formatDate(DateTime d) {
    return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
  }

  Future<void> _loadUserData() async {
    final firestore = FirebaseFirestore.instance;
    
    try {
      final userDoc = await firestore.collection('users').doc(user.uid).get();

      if (mounted && userDoc.exists) {
        setState(() {
          gymId = userDoc['gymId'] ?? "";
          userName = userDoc['name'] ?? "Athlete";
        });

        if (gymId.isNotEmpty) {
          final memberDoc = await firestore
              .collection('gyms')
              .doc(gymId)
              .collection('members')
              .doc(user.uid)
              .get();

          if (memberDoc.exists) {
            final data = memberDoc.data()!;
            setState(() {
              
              feeStatus = data['feeStatus'] ?? "unpaid";
              plan = data['plan'] ?? "Monthly";
              isPaid = feeStatus.toLowerCase() == "paid";
              
              if (data['validUntil'] != null) {
                DateTime date = (data['validUntil'] as Timestamp).toDate();
                expiryDate = DateFormat('dd MMM yyyy').format(date);
              }
            });
          }
          await _loadAttendance();
        }
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
    }
  }

  // 2. LOAD ATTENDANCE: Converts Firestore Timestamps to strings for the Calendar
  Future<void> _loadAttendance() async {
    if (gymId.isEmpty) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('gyms')
          .doc(gymId)
          .collection('attendance')
          .where('memberId', isEqualTo: user.uid)
          .get();

      final Set<String> dates = {};
      for (var doc in snap.docs) {
        final data = doc.data();
        if (data['timestamp'] != null) {
          // Extract DateTime from the Firestore Timestamp
          DateTime dt = (data['timestamp'] as Timestamp).toDate();
          dates.add(_formatDate(dt)); // Store as "YYYY-MM-DD"
        }
      }

      if (mounted) {
        setState(() {
          presentDates = dates;
        });
      }
    } catch (e) {
      debugPrint("Attendance load error: $e");
    }
  }

  bool _isPresent(DateTime day) => presentDates.contains(_formatDate(day));

  Future<void> _markAttendance(String scannedToken) async {
    try {
      final todayKey = _formatDate(DateTime.now());

      if (presentDates.contains(todayKey)) {
        _showSnackBar("ℹ️ You already checked in today!", Colors.orange);
        return;
      }

      await FirebaseFirestore.instance
          .collection('gyms')
          .doc(gymId)
          .collection('attendance')
          .add({
        "memberId": user.uid,
        "status": "present",
        "markedBy": "member",
        "timestamp": FieldValue.serverTimestamp(),
      });

      setState(() => presentDates.add(todayKey));
      _showSnackBar("✅ Attendance marked successfully!", Colors.green);
      
    } catch (e) {
      _showSnackBar("❌ Error: $e", Colors.redAccent);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  void _openQRScanner() async {
    final String? scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QRScannerPage()),
    );
    if (scannedCode != null && scannedCode.isNotEmpty) {
      _markAttendance(scannedCode);
    }
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
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Welcome back,", style: TextStyle(fontSize: 16, color: Colors.grey)),
                Text(userName.toUpperCase(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 25),
                Row(
                  children: [
                    Expanded(child: _buildStatTile("SESSIONS", "${presentDates.length}", Icons.bolt)),
                    const SizedBox(width: 15),
                    Expanded(child: _buildStatTile("PLAN", plan, Icons.workspace_premium)),
                  ],
                ),
                const SizedBox(height: 20),
                _buildPaymentCard(),
                const SizedBox(height: 30),
                const Text("ATTENDANCE HISTORY", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.yellowAccent, letterSpacing: 1.5)),
                const SizedBox(height: 15),
                _buildCalendar(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.yellowAccent, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.black, size: 20),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildPaymentCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("STATUS", style: TextStyle(color: Colors.white38, fontSize: 11)),
                  const SizedBox(height: 5),
                  Text(feeStatus.toUpperCase(), style: TextStyle(color: isPaid ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("EXPIRES ON", style: TextStyle(color: Colors.white38, fontSize: 11)),
                  const SizedBox(height: 5),
                  Text(expiryDate, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isPaid ? Colors.white10 : Colors.yellowAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: isPaid ? null : () => _showPaymentSheet(),
              child: Text(isPaid ? "MEMBERSHIP ACTIVE" : "PAY FEES NOW", style: TextStyle(color: isPaid ? Colors.white38 : Colors.black, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
      child: TableCalendar(
        firstDay: DateTime.utc(2023, 1, 1),
        lastDay: DateTime.utc(2035, 12, 31),
        focusedDay: focusedDay,
        selectedDayPredicate: (day) => isSameDay(selectedDay, day),
        headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true, titleTextStyle: TextStyle(color: Colors.white)),
        calendarStyle: const CalendarStyle(defaultTextStyle: TextStyle(color: Colors.white), weekendTextStyle: TextStyle(color: Colors.white70)),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, _) => _isPresent(day) ? _presentDay(day) : null,
          todayBuilder: (context, day, _) => _isPresent(day) ? _presentDay(day) : null,
        ),
        onDaySelected: (selected, focused) {
          setState(() {
            selectedDay = selected;
            focusedDay = focused;
          });
        },
      ),
    );
  }

  Widget _presentDay(DateTime day) {
    return Container(
      margin: const EdgeInsets.all(6),
      decoration: const BoxDecoration(
        color: Colors.yellowAccent, 
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.yellowAccent, blurRadius: 4)]
      ),
      alignment: Alignment.center,
      child: Text('${day.day}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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