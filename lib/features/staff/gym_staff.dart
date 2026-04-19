import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  int unpaidMembers = 0;
  bool _isLoggingOut = false;
  List<Map<String, dynamic>> members = [];

  GymStatusResult? _gymStatus;

  bool get _isLocked   => _gymStatus?.access == GymAccessLevel.locked;
  bool get _isReadOnly => _gymStatus?.access == GymAccessLevel.readOnly;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

Future<void> _loadData() async {
  if (!_isLoading) setState(() => _isLoading = true);
  try {
    final uid = _auth.currentUser!.uid;

    // Step 1: Get staff's own user doc first (need gymId before anything else)
    final userDoc = await _fs.collection('users').doc(uid).get();
    final data = userDoc.data()!;
    staffName = data['name'] ?? 'Staff';
    gymId = data['gymId'] ?? '';

    if (gymId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final today = DateTime.now();
    final todayKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // Step 2: Fire all remaining calls at the same time
    final results = await Future.wait([
      GymStatusService.checkAccess(gymId),                                    // [0]
      _fs.collection('gyms').doc(gymId).get(),                                // [1]
      _fs.collection('gyms').doc(gymId)
          .collection('attendance')
          .where('date', isEqualTo: todayKey)
          .get(),                                                              // [2]
      _fs.collection('gyms').doc(gymId)
          .collection('members')
          .get(),                                                              // [3]
    ]);

    final statusResult  = results[0] as GymStatusResult;
    final gymDoc        = results[1] as DocumentSnapshot;
    final attSnap       = results[2] as QuerySnapshot;
    final membersSnap   = results[3] as QuerySnapshot;

    gymName        = gymDoc.get('gymName') ?? 'Gym';
    todayAttendance = attSnap.size;

    // Step 3: Build member list from members subcollection only — no extra user fetches
    final List<Map<String, dynamic>> loaded = [];
    int unpaid = 0;

    for (final doc in membersSnap.docs) {
      final mData = doc.data() as Map<String, dynamic>;
      if (mData['isDeleted'] == true) continue; // skip soft-deleted members
      final status = mData['feeStatus'] ?? 'unpaid';
      if (status != 'paid') unpaid++;
      loaded.add({
        'uid'        : doc.id,
        'name'       : mData['name'] ?? 'Unknown',   // ← from members doc, no extra read
        'plan'       : mData['plan'] ?? 'Monthly',
        'feeStatus'  : status,
        'currentFee' : mData['currentFee'] ?? 0,
        'validUntil' : mData['validUntil'],
      });
    }

    totalMembers = loaded.length;

    if (mounted) {
      setState(() {
        members        = loaded;
        unpaidMembers  = unpaid;
        _gymStatus     = statusResult;
        _isLoading     = false;
      });
    }
  } catch (e) {
    if (mounted) setState(() => _isLoading = false);
  }
}
  Future<void> _logout() async {
    if (_isLoggingOut) return;
    final confirmed = await showConfirmDialog(
      context: context,
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
      _showSnack('Online services are currently disabled.', Colors.orangeAccent);
      return;
    }
    action();
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _gymStatus == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        appBar: _buildAppBar(),
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
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (_isReadOnly)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.orangeAccent,
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.black, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Online services are disabled. Record keeping unavailable.',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: Colors.yellowAccent,
              backgroundColor: const Color(0xFF141414),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatsRow(
                      todayAttendance: todayAttendance,
                      totalMembers: totalMembers,
                      unpaidMembers: unpaidMembers,
                    ),
                    const SizedBox(height: 12),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text(
                        'OPERATIONS',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    _ActionTile(
                      icon: Icons.qr_code_scanner_rounded,
                      iconColor: Colors.yellowAccent,
                      label: 'Mark Attendance',
                      subtitle: 'Show QR or check in manually',
                      disabled: _isReadOnly,
                      onTap: () => _requireFullAccess(() {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StaffMarkAttendance(
                              gymId: gymId,
                              staffName: staffName,
                              members: members,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    _ActionTile(
                      icon: Icons.account_balance_wallet_rounded,
                      iconColor: Colors.yellowAccent,
                      label: 'Collect Fees',
                      subtitle: 'Record cash payments for members',
                      disabled: _isReadOnly,
                      onTap: () => _requireFullAccess(() {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StaffMarkFees(
                              gymId: gymId,
                              staffName: staffName,
                              members: members,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text(
                        'MEMBERS',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    if (members.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            'No members found',
                            style: TextStyle(
                                color: Colors.white24, fontSize: 14),
                          ),
                        ),
                      )
                    else
                      ...members.take(10).map((m) => _MemberRow(member: m)),

                    if (members.length > 10)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Center(
                          child: Text(
                            '+${members.length - 10} more members',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() => AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              gymName.isEmpty ? 'Loading…' : gymName.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white54,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              staffName.isEmpty ? 'Staff' : staffName.toUpperCase(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
                height: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: _logout,
          ),
          const SizedBox(width: 4),
        ],
      );
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.todayAttendance,
    required this.totalMembers,
    required this.unpaidMembers,
  });

  final int todayAttendance;
  final int totalMembers;
  final int unpaidMembers;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _StatCard(
              label: 'Check-ins today',
              value: '$todayAttendance',
              sub: 'total attendance',
            ),
            const SizedBox(width: 8),
            _StatCard(
              label: 'Total members',
              value: '$totalMembers',
              sub: 'registered',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _StatCard(
              label: 'Unpaid fees',
              value: '$unpaidMembers',
              sub: 'need collection',
              valueColor:
                  unpaidMembers > 0 ? Colors.redAccent : Colors.greenAccent,
            ),
            const SizedBox(width: 8),
            _StatCard(
              label: 'Paid up',
              value: '${totalMembers - unpaidMembers}',
              sub: 'all clear',
              valueColor: Colors.greenAccent,
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    this.valueColor,
  });

  final String label;
  final String value;
  final String sub;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sub,
              style: const TextStyle(
                  color: Colors.white24, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.disabled = false,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.45 : 1.0,
      child: Material(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        disabled ? 'Currently unavailable' : subtitle,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white24,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member});

  final Map<String, dynamic> member;

  @override
  Widget build(BuildContext context) {
    final status =
        (member['feeStatus'] ?? 'unpaid').toString().toLowerCase();
    final Color statusColor = switch (status) {
      'paid'    => Colors.greenAccent,
      'pending' => Colors.orangeAccent,
      _         => Colors.redAccent,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: statusColor, width: 2),
                ),
              ),
              CircleAvatar(
                radius: 19,
                backgroundColor: Colors.yellowAccent.withOpacity(0.1),
                child: Text(
                  (member['name'] as String)[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.yellowAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member['name'] ?? 'Member',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  member['plan'] ?? 'Monthly',
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedScreen extends StatelessWidget {
  const _LockedScreen({
    required this.gymName,
    required this.staffName,
    required this.message,
    required this.onLogout,
  });

  final String gymName;
  final String staffName;
  final String message;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              gymName.toUpperCase(),
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
            Text(
              staffName.toUpperCase(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: onLogout,
            child: const Text('Logout',
                style: TextStyle(color: Colors.redAccent)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline_rounded,
                    color: Colors.redAccent, size: 40),
              ),
              const SizedBox(height: 28),
              const Text(
                'Gym Unavailable',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 14, height: 1.6),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please contact your gym manager.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white38, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 36),
              OutlinedButton(
                onPressed: onLogout,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 14),
                ),
                child: const Text('Log Out',
                    style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}