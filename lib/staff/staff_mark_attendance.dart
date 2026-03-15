import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class StaffMarkAttendance extends StatefulWidget {
  final String gymId;
  final String staffName;
  final List<Map<String, dynamic>> members;

  const StaffMarkAttendance({
    super.key,
    required this.gymId,
    required this.staffName,
    required this.members,
  });

  @override
  State<StaffMarkAttendance> createState() => _StaffMarkAttendanceState();
}

class _StaffMarkAttendanceState extends State<StaffMarkAttendance> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _filtered = [];
  bool _isMarking = false;

  @override
  void initState() {
    super.initState();
    _filtered = widget.members;
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.toLowerCase();
      setState(() {
        _filtered = widget.members
            .where((m) =>
                (m['name'] as String).toLowerCase().contains(q))
            .toList();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _markAttendance(Map<String, dynamic> member) async {
    final now = DateTime.now();

    // Check already marked today
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final existing = await FirebaseFirestore.instance
        .collection('gyms')
        .doc(widget.gymId)
        .collection('attendance')
        .where('memberId', isEqualTo: member['uid'])
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .where('timestamp', isLessThan: Timestamp.fromDate(todayEnd))
        .get();

    if (existing.docs.isNotEmpty) {
      _showSnack("${member['name']} already checked in today",
          Colors.orange);
      return;
    }

    final confirmed = await _confirmDialog(member['name']);
    if (!confirmed) return;

    setState(() => _isMarking = true);
    try {
      await FirebaseFirestore.instance
          .collection('gyms')
          .doc(widget.gymId)
          .collection('attendance')
          .add({
        'memberId': member['uid'],
        'timestamp': FieldValue.serverTimestamp(),
        'markedBy': 'staff',
        'staffName': widget.staffName,
        'status': 'present',
        'date':
            "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}",
      });
      _showSnack("✅ Attendance marked for ${member['name']}",
          Colors.green);
    } catch (e) {
      _showSnack("Error: $e", Colors.redAccent);
    } finally {
      setState(() => _isMarking = false);
    }
  }

  Future<bool> _confirmDialog(String memberName) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.grey[900],
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text("Confirm Attendance",
                style: TextStyle(color: Colors.white)),
            content: Text(
              "Mark $memberName as present for today?\n${DateFormat('dd MMM yyyy').format(DateTime.now())}",
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("CANCEL",
                      style: TextStyle(color: Colors.white38))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                onPressed: () => Navigator.pop(context, true),
                child: const Text("CONFIRM",
                    style:
                        TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSnack(String msg, Color color) {
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
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text("MARK ATTENDANCE",
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search member...",
                hintStyle:
                    const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search,
                    color: Colors.greenAccent),
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
          ),
          const SizedBox(height: 10),

          // Today's date banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.calendar_today,
                    color: Colors.white38, size: 14),
                const SizedBox(width: 8),
                Text(
                  "Today: ${DateFormat('EEEE, dd MMM yyyy').format(DateTime.now())}",
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Member list
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
                    child: Text("No members found",
                        style:
                            TextStyle(color: Colors.white38)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final m = _filtered[i];
                      return _memberRow(m);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _memberRow(Map<String, dynamic> m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor:
                Colors.greenAccent.withOpacity(0.1),
            child: Text(
              (m['name'] as String)[0].toUpperCase(),
              style: const TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(m['name'],
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15)),
          ),
          _isMarking
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.greenAccent))
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.greenAccent.withOpacity(0.15),
                    foregroundColor: Colors.greenAccent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                  ),
                  onPressed: () => _markAttendance(m),
                  child: const Text("CHECK IN",
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
        ],
      ),
    );
  }
}