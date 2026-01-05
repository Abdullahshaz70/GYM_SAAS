import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'qr_scan.dart'; 


// import 'package:mobile_scanner/mobile_scanner.dart';
// import 'dart:io';
// import 'qr_scan.dart';

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
  String userName = "User";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    if (mounted) {
      setState(() {
        gymId = userDoc['gymId'] ?? "";
        userName = userDoc['name'] ?? "Athlete";
      });
      await _loadAttendance();
    }
  }

  Future<void> _loadAttendance() async {
    if (gymId.isEmpty) return;

    final snap = await FirebaseFirestore.instance
        .collection('gyms')
        .doc(gymId)
        .collection('attendance')
        .where('memberId', isEqualTo: user.uid)
        .get();

    final dates = snap.docs.map((d) => d['date'] as String).toSet();

    if (mounted) {
      setState(() {
        presentDates = dates;
      });
    }
  }

  bool _isPresent(DateTime day) => presentDates.contains(_formatDate(day));

  String _formatDate(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";




Future<void> _markAttendance(String scannedToken) async {
  try {
    scannedToken = scannedToken.trim();
    if (scannedToken.isEmpty) throw "The scanned QR code is empty.";

    if (gymId.isEmpty) throw "Your gym is not assigned!";

    final todayKey = _formatDate(DateTime.now());

    final attendanceCollection = FirebaseFirestore.instance
        .collection('gyms')
        .doc(gymId)        
        .collection('attendance');

    final querySnap = await attendanceCollection
        .where('memberId', isEqualTo: user.uid)
        .where('date', isEqualTo: todayKey)
        .limit(1)
        .get();

    if (querySnap.docs.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("ℹ️ You already checked in today!"),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    await attendanceCollection.add({
      "memberId": user.uid,
      "date": todayKey,
      "timestamp": FieldValue.serverTimestamp(),
    });

    if (mounted) {
      setState(() {
        presentDates.add(todayKey);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Attendance marked successfully!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error: $e"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}



// void _showStatusSnackBar(String message, Color color) {
//   ScaffoldMessenger.of(context).showSnackBar(
//     SnackBar(
//       content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
//       backgroundColor: color,
//       behavior: SnackBarBehavior.floating,
//     ),
//   );
// }


  void _openQRScanner() async {
    // We wait for the 'code' returned from the Scanner Page
    final String? scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QRScannerPage()),
    );

    // If a code was actually scanned (not just back-button pressed)
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
        foregroundColor: Colors.yellowAccent,
        title: const Text("PRO TRACKER",
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        actions: [
          IconButton(
              onPressed: () => FirebaseAuth.instance.signOut(),
              icon: const Icon(Icons.logout, color: Colors.yellowAccent))
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openQRScanner,
        backgroundColor: Colors.yellowAccent,
        icon: const Icon(Icons.qr_code_scanner, color: Colors.black),
        label: const Text("CHECK IN",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("Welcome back,", style: TextStyle(fontSize: 16, color: Colors.grey)),
            Text(userName.toUpperCase(),
                style: const TextStyle(
                    fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 25),
            _buildStatsCard(),
            const SizedBox(height: 30),
            const Text("ATTENDANCE HISTORY",
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellowAccent,
                    letterSpacing: 1.5)),
            const SizedBox(height: 15),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white10, width: 1),
              ),
              child: TableCalendar(
                firstDay: DateTime.utc(2023, 1, 1),
                lastDay: DateTime.utc(2035, 12, 31),
                focusedDay: focusedDay,
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(color: Colors.grey),
                  weekendStyle: TextStyle(color: Colors.yellowAccent),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle:
                      TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  leftChevronIcon: Icon(Icons.chevron_left, color: Colors.yellowAccent),
                  rightChevronIcon:
                      Icon(Icons.chevron_right, color: Colors.yellowAccent),
                ),
                calendarStyle: const CalendarStyle(
                  defaultTextStyle: TextStyle(color: Colors.white),
                  weekendTextStyle: TextStyle(color: Colors.white70),
                  todayDecoration:
                      BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, _) =>
                      _isPresent(day) ? _presentDay(day) : null,
                  todayBuilder: (context, day, _) =>
                      _isPresent(day) ? _presentDay(day) : null,
                ),
                onDaySelected: (selected, focused) {
                  setState(() {
                    selectedDay = selected;
                    focusedDay = focused;
                  });
                },
              ),
            ),
            const SizedBox(height: 30),
          ]),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.yellowAccent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("TOTAL SESSIONS",
                  style:
                      TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold)),
              Text("${presentDates.length}",
                  style: const TextStyle(
                      color: Colors.black, fontSize: 40, fontWeight: FontWeight.bold)),
            ],
          ),
          const Icon(Icons.fitness_center_rounded, color: Colors.black, size: 50),
        ],
      ),
    );
  }

  Widget _presentDay(DateTime day) {
    return Container(
      margin: const EdgeInsets.all(6),
      decoration: const BoxDecoration(color: Colors.yellowAccent, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text('${day.day}',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
    );
  }


}













