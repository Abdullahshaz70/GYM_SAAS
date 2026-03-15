import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../auth/login.dart';
import 'staff_mark_attendance.dart';
import 'staff_mark_fees.dart';
import '../user/screens/skeleton_loaders.dart';

class GymStaff extends StatefulWidget {
  const GymStaff({super.key});

  @override
  State<GymStaff> createState() => _GymStaffState();
}

class _GymStaffState extends State<GymStaff> {
  final _fs = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  String staffName = '';
  String gymId = '';
  String gymName = '';
  int todayAttendance = 0;
  int totalMembers = 0;
  List<Map<String, dynamic>> members = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final uid = _auth.currentUser!.uid;

      // 1. Get staff user profile
      final userDoc = await _fs.collection('users').doc(uid).get();
      final data = userDoc.data()!;
      staffName = data['name'] ?? 'Staff';
      gymId = data['gymId'] ?? '';

      if (gymId.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      // 2. Get gym name
      final gymDoc = await _fs.collection('gyms').doc(gymId).get();
      gymName = gymDoc.data()?['gymName'] ?? 'Gym';

      // 3. Today's attendance count
      final today = DateTime.now();
      final todayKey =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
      final attSnap = await _fs
          .collection('gyms')
          .doc(gymId)
          .collection('attendance')
          .where('date', isEqualTo: todayKey)
          .get();
      todayAttendance = attSnap.size;

      // 4. Members list
      final membersSnap = await _fs
          .collection('gyms')
          .doc(gymId)
          .collection('members')
          .get();
      totalMembers = membersSnap.size;

      final List<Map<String, dynamic>> loaded = [];
      for (final doc in membersSnap.docs) {
        final mData = doc.data();
        final uDoc = await _fs.collection('users').doc(doc.id).get();
        loaded.add({
          'uid': doc.id,
          'name': uDoc.data()?['name'] ?? 'Unknown',
          'plan': mData['plan'] ?? 'Monthly',
          'feeStatus': mData['feeStatus'] ?? 'unpaid',
          'currentFee': mData['currentFee'] ?? 0,
          'validUntil': mData['validUntil'],
        });
      }

      setState(() {
        members = loaded;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Staff load error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const Login()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: _isLoading
            ? skeletonBox(width: 160, height: 16)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(gymName.toUpperCase(),
                      style: const TextStyle(
                          color: Colors.yellowAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5)),
                  Text("STAFF · ${staffName.toUpperCase()}",
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11)),
                ],
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const GymStaffSkeleton()
          : RefreshIndicator(
              onRefresh: _loadData,
              color: Colors.yellowAccent,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Stats row ──────────────────────────────
                    Row(
                      children: [
                        _statCard("TODAY'S CHECK-INS",
                            "$todayAttendance", Icons.how_to_reg,
                            Colors.yellowAccent),
                        const SizedBox(width: 15),
                        _statCard("TOTAL MEMBERS",
                            "$totalMembers", Icons.group,
                            Colors.blueAccent),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Quick action buttons ───────────────────
                    _actionButton(
                      icon: Icons.qr_code_scanner,
                      label: "MARK ATTENDANCE",
                      subtitle: "Scan or search to check in a member",
                      color: Colors.greenAccent,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StaffMarkAttendance(
                              gymId: gymId,
                              staffName: staffName,
                              members: members),
                        ),
                      ).then((_) => _loadData()),
                    ),
                    const SizedBox(height: 12),
                    _actionButton(
                      icon: Icons.payments_rounded,
                      label: "MARK FEES PAID",
                      subtitle: "Record a cash payment for a member",
                      color: Colors.orangeAccent,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StaffMarkFees(
                              gymId: gymId,
                              staffName: staffName,
                              members: members),
                        ),
                      ).then((_) => _loadData()),
                    ),
                    const SizedBox(height: 30),

                    // ── Members list (read-only) ───────────────
                    const Text("MEMBERS",
                        style: TextStyle(
                            color: Colors.yellowAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5)),
                    const SizedBox(height: 12),
                    if (members.isEmpty)
                      const Center(
                          child: Text("No members yet",
                              style:
                                  TextStyle(color: Colors.white38)))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: members.length,
                        itemBuilder: (_, i) =>
                            _memberTile(members[i]),
                      ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _statCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 10),
            Text(label,
                style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: color.withOpacity(0.5), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _memberTile(Map<String, dynamic> member) {
    final bool isPaid =
        member['feeStatus']?.toString().toLowerCase() == 'paid';
    final validUntil = member['validUntil'] != null
        ? DateFormat('dd MMM yyyy')
            .format((member['validUntil'] as Timestamp).toDate())
        : '--';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.yellowAccent.withOpacity(0.1),
            child: Text(
              (member['name'] as String)[0].toUpperCase(),
              style: const TextStyle(
                  color: Colors.yellowAccent,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member['name'],
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const SizedBox(height: 3),
                Text("Valid: $validUntil",
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isPaid
                  ? Colors.greenAccent.withOpacity(0.1)
                  : Colors.redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isPaid ? 'PAID' : 'UNPAID',
              style: TextStyle(
                  color: isPaid ? Colors.greenAccent : Colors.redAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}