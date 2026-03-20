import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../auth/login.dart';
import 'staff_mark_attendance.dart';
import 'staff_mark_fees.dart';
import '../../shared/skeleton_loaders.dart';
import '../../shared/gym_status_service.dart';
import '../../shared/utils.dart';

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
  bool _isLoggingOut = false;
  List<Map<String, dynamic>> members = [];

  GymStatusResult? _gymStatus;

  bool get _isLocked => _gymStatus?.access == GymAccessLevel.locked;
  bool get _isReadOnly => _gymStatus?.access == GymAccessLevel.readOnly;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final uid = _auth.currentUser!.uid;
      final userDoc = await _fs.collection('users').doc(uid).get();
      final data = userDoc.data()!;
      staffName = data['name'] ?? 'Staff';
      gymId = data['gymId'] ?? '';

      if (gymId.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final statusResult = await GymStatusService.checkAccess(gymId);
      final gymDoc = await _fs.collection('gyms').doc(gymId).get();
      gymName = gymDoc.data()?['gymName'] ?? 'Gym';

      final today = DateTime.now();
      final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final attSnap = await _fs
          .collection('gyms')
          .doc(gymId)
          .collection('attendance')
          .where('date', isEqualTo: todayKey)
          .get();
      todayAttendance = attSnap.size;

      final membersSnap = await _fs.collection('gyms').doc(gymId).collection('members').get();
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

      if (mounted) {
        setState(() {
          members = loaded;
          _gymStatus = statusResult;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }



    Future<void> _logout() async {
    if (_isLoggingOut) return;

    final confirmed = await showConfirmDialog(
      context:context,
      title: 'Log out',
      message: 'Are you sure you want to log out?',
      confirmLabel: 'Log out',
      isDestructive: true,
    );
    if (!confirmed) return;

    setState(() => _isLoggingOut = true);
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const Login()),
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error logging out: $e')));
      }
      setState(() => _isLoggingOut = false);
    }
  }


  void _requireFullAccess(VoidCallback action) {
    if (_isLocked) {
      _showSnack('Gym is unavailable. Contact manager.', Colors.redAccent);
      return;
    }
    if (_isReadOnly) {
      _showSnack('Online services disabled.', Colors.orangeAccent);
      return;
    }
    action();
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _gymStatus == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: _buildAppBar(titleWidget: skeletonBox(width: 140, height: 14)),
        body: const GymStaffSkeleton(),
      );
    }

    if (_isLocked) {
      return _LockedScreen(
        gymName: gymName,
        staffName: staffName,
        message: _gymStatus!.message,
        onLogout: _logout,
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (_isReadOnly)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withOpacity(0.9),
              ),
              child: const Row(
                children: [
                  Icon(Icons.cloud_off_rounded, color: Colors.black, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'READ-ONLY MODE: Record keeping is temporarily disabled.',
                      style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: Colors.yellowAccent,
              backgroundColor: Colors.grey[900],
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "QUICK OVERVIEW",
                      style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _statCard("CHECK-INS", '$todayAttendance', Icons.bolt_rounded, Colors.yellowAccent),
                        const SizedBox(width: 12),
                        _statCard('MEMBERS', '$totalMembers', Icons.people_outline_rounded, Colors.blueAccent),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      "STAFF OPERATIONS",
                      style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 16),
                    _actionButton(
                      icon: Icons.qr_code_scanner_rounded,
                      label: 'MARK ATTENDANCE',
                      subtitle: 'Verify & check-in members',
                      color: Colors.yellowAccent,
                      disabled: _isReadOnly,
                      onTap: () => _requireFullAccess(() {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => StaffMarkAttendance(gymId: gymId, staffName: staffName, members: members)));
                      }),
                    ),
                    const SizedBox(height: 12),
                    _actionButton(
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'COLLECT FEES',
                      subtitle: 'Update payment status',
                      color: Colors.blueAccent,
                      disabled: _isReadOnly,
                      onTap: () => _requireFullAccess(() {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => StaffMarkFees(gymId: gymId, staffName: staffName, members: members)));
                      }),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar({Widget? titleWidget}) => AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: titleWidget ??
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(gymName.toUpperCase(),
                    style: const TextStyle(color: Colors.yellowAccent, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.circle, size: 6, color: Colors.greenAccent),
                    const SizedBox(width: 4),
                    Text(staffName.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
        actions: [
          IconButton(
            icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent, size: 22),
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      );

  Widget _statCard(String label, String value, IconData icon, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 16),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
              Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ],
          ),
        ),
      );

  Widget _actionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool disabled = false,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: disabled ? 0.3 : 1.0,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: color.withOpacity(0.1),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.4)),
              ],
            ),
          ),
        ),
      );


}

class _LockedScreen extends StatelessWidget {
  const _LockedScreen({required this.gymName, required this.staffName, required this.message, required this.onLogout});
  final String gymName, staffName, message;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_person_rounded, color: Colors.redAccent.withOpacity(0.5), size: 80),
              const SizedBox(height: 32),
              Text(gymName.toUpperCase(), style: const TextStyle(color: Colors.yellowAccent, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const SizedBox(height: 8),
              const Text('ACCESS RESTRICTED', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 14, height: 1.6)),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onLogout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('SIGN OUT', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}