import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../user/screens/skeleton_loaders.dart'; // ← NEW

class AttendanceScreen extends StatefulWidget {
  final String uid;
  final String gymId;

  const AttendanceScreen(
      {super.key, required this.uid, required this.gymId});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Set<DateTime> _attendedDays = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchAttendance();
  }

  Future<void> _fetchAttendance() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('gyms')
          .doc(widget.gymId)
          .collection('attendance')
          .where('memberId', isEqualTo: widget.uid)
          .get();

      final dates = snapshot.docs.map((doc) {
        final ts = doc['timestamp'] as Timestamp;
        final d = ts.toDate();
        return DateTime(d.year, d.month, d.day);
      }).toSet();

      setState(() {
        _attendedDays = dates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAttendanceManual() async {
    final now = DateTime.now();
    final selectedDate = _selectedDay ?? now;

    final DateTime finalDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      now.hour,
      now.minute,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15)),
        title: const Text("Confirm Attendance",
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Marking attendance for:",
                style:
                    TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 8),
            Text(
              DateFormat('EEEE, dd MMM yyyy').format(finalDateTime),
              style: const TextStyle(
                  color: Colors.yellowAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              "Time: ${DateFormat('hh:mm a').format(finalDateTime)}",
              style: const TextStyle(
                  color: Colors.white38, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL",
                style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellowAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await FirebaseFirestore.instance
                    .collection('gyms')
                    .doc(widget.gymId)
                    .collection('attendance')
                    .add({
                  'memberId': widget.uid,
                  'timestamp':
                      Timestamp.fromDate(finalDateTime),
                  'markedBy': 'admin',
                  'status': 'present'
                });
                await _fetchAttendance();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            "Attendance marked successfully!")),
                  );
                }
              } catch (e) {
                setState(() => _isLoading = false);
                debugPrint("Error: $e");
              }
            },
            child: const Text("CONFIRM"),
          ),
        ],
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
        title: const Text("ATTENDANCE CALENDAR",
            style: TextStyle(fontSize: 16)),
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.yellowAccent,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text("MARK PRESENT",
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold)),
        onPressed: _markAttendanceManual,
      ),
      // ── SKELETON vs real content ──────────────────────────────────────
      body: _isLoading
          ? const AttendanceScreenSkeleton() // ← skeleton
          : Column(
              children: [
                _buildCalendar(),
                const Divider(color: Colors.white10),
                Expanded(child: _buildAttendanceList()),
              ],
            ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.now(),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) =>
            isSameDay(_selectedDay, day),
        calendarFormat: CalendarFormat.month,
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        eventLoader: (day) {
          final normalizedDay =
              DateTime(day.year, day.month, day.day);
          return _attendedDays.contains(normalizedDay)
              ? ['attended']
              : [];
        },
        calendarStyle: const CalendarStyle(
          todayDecoration: BoxDecoration(
              color: Colors.white24, shape: BoxShape.circle),
          selectedDecoration: BoxDecoration(
              color: Colors.yellowAccent,
              shape: BoxShape.circle),
          selectedTextStyle: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold),
          markerDecoration: BoxDecoration(
              color: Colors.greenAccent,
              shape: BoxShape.circle),
          defaultTextStyle: TextStyle(color: Colors.white),
          weekendTextStyle: TextStyle(color: Colors.white60),
          outsideDaysVisible: false,
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
              color: Colors.yellowAccent,
              fontWeight: FontWeight.bold),
          leftChevronIcon:
              Icon(Icons.chevron_left, color: Colors.white),
          rightChevronIcon:
              Icon(Icons.chevron_right, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildAttendanceList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('gyms')
          .doc(widget.gymId)
          .collection('attendance')
          .where('memberId', isEqualTo: widget.uid)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return _emptyState("Something went wrong");
        if (!snapshot.hasData) return const SizedBox();

        final allDocs = snapshot.data!.docs;
        final filteredDocs = allDocs.where((doc) {
          final date =
              (doc['timestamp'] as Timestamp).toDate();
          return isSameDay(date, _selectedDay);
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('dd MMM yyyy')
                        .format(_selectedDay!),
                    style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    filteredDocs.isNotEmpty
                        ? "PRESENT"
                        : "ABSENT",
                    style: TextStyle(
                      color: filteredDocs.isNotEmpty
                          ? Colors.greenAccent
                          : Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filteredDocs.isEmpty
                  ? Center(
                      child: Text("No records for this day",
                          style: TextStyle(
                              color: Colors.white24)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20),
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        final time = (filteredDocs[index]
                                ['timestamp'] as Timestamp)
                            .toDate();
                        return Container(
                          margin:
                              const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent
                                .withOpacity(0.05),
                            borderRadius:
                                BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.greenAccent
                                    .withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time,
                                  color: Colors.greenAccent,
                                  size: 18),
                              const SizedBox(width: 15),
                              Text(
                                "Marked at ${DateFormat('hh:mm a').format(time)}",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                    size: 20),
                                onPressed: () =>
                                    _deleteAttendance(
                                        filteredDocs[index].id),
                              )
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAttendance(String docId) async {
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text("Delete Record?",
                style: TextStyle(color: Colors.white)),
            content: const Text(
                "This will remove this attendance entry.",
                style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                  onPressed: () =>
                      Navigator.pop(context, false),
                  child: const Text("CANCEL")),
              TextButton(
                  onPressed: () =>
                      Navigator.pop(context, true),
                  child: const Text("DELETE",
                      style: TextStyle(color: Colors.red))),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      await FirebaseFirestore.instance
          .collection('gyms')
          .doc(widget.gymId)
          .collection('attendance')
          .doc(docId)
          .delete();
      _fetchAttendance();
    }
  }

  Widget _emptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_note,
              color: Colors.white10, size: 50),
          const SizedBox(height: 10),
          Text(msg,
              style:
                  const TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }
}