// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'services/firestore_service.dart';
// import 'screens/stats_tile.dart';
// import 'screens/payment_card.dart';
// import 'screens/attendance_calendar.dart';
// import 'screens/skeleton_loaders.dart';
// import '../qr_scan.dart';
// import 'package:intl/intl.dart';
// import '../auth/login.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'screens/pay_fee_screen.dart';
// import 'screens/user_payment_history_screen.dart'; 

// class GymUser extends StatefulWidget {
//   const GymUser({super.key});

//   @override
//   State<GymUser> createState() => _GymUserScreen();
// }

// class _GymUserScreen extends State<GymUser> {
//   final user = FirebaseAuth.instance.currentUser!;
//   final FirestoreService _fs = FirestoreService();

//   String gymId = "";
//   String userName = "Athlete";
//   String feeStatus = "unpaid";
//   String plan = "Standard";
//   String expiryDate = "---";
//   double currentFee = 0;
//   bool isPaid = false;
//   bool _isLoading = true;

//   DateTime focusedDay = DateTime.now();
//   DateTime selectedDay = DateTime.now();
//   Set<String> presentDates = {};

//   @override
//   void initState() {
//     super.initState();
//     _loadUserData();
//   }

//   Future<void> _loadUserData() async {
//     if (!_isLoading) setState(() => _isLoading = true);

//     final userData = await _fs.getUserData(user.uid);
//     if (userData == null) {
//       setState(() => _isLoading = false);
//       return;
//     }

//     gymId = userData['gymId'] ?? "";
//     userName = userData['name'] ?? "Athlete";

//     if (gymId.isNotEmpty) {
//       final memberData = await _fs.getMemberData(gymId, user.uid);
//       if (memberData != null) {
//         feeStatus = memberData['feeStatus'] ?? "unpaid";
//         plan = memberData['plan'] ?? "Monthly";
//         currentFee = (memberData['currentFee'] as num?)?.toDouble() ?? 0;
//         isPaid = feeStatus.toLowerCase() == "paid";
//         if (memberData['validUntil'] != null) {
//           DateTime date = (memberData['validUntil'] as Timestamp).toDate();
//           expiryDate = DateFormat('dd MMM yyyy').format(date);
//         }
//       }

//       final attendance = await _fs.getAttendance(gymId, user.uid);
//       presentDates = attendance;
//     }

//     setState(() => _isLoading = false);
//   }

//   void _openQRScanner() async {
//     final scannedCode = await Navigator.push<String>(
//         context, MaterialPageRoute(builder: (_) => const QRScannerPage()));
//     if (scannedCode != null && scannedCode.isNotEmpty) {
//       await _markAttendance();
//     }
//   }

//   Future<void> _markAttendance() async {
//     final todayKey =
//         "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";

//     if (presentDates.contains(todayKey)) {
//       _showSnackBar("ℹ️ Already checked in today", Colors.orange);
//       return;
//     }

//     await _fs.markAttendance(gymId, user.uid);
//     setState(() => presentDates.add(todayKey));
//     _showSnackBar("✅ Attendance marked", Colors.green);
//   }

//   void _showSnackBar(String msg, Color color) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//         content: Text(msg),
//         backgroundColor: color,
//         behavior: SnackBarBehavior.floating));
//   }

//   void _openPayFeeScreen() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => PayFeeScreen(
//           gymId: gymId,
//           memberId: user.uid,
//           plan: plan,
//           currentFee: currentFee,
//         ),
//       ),
//     ).then((_) => _loadUserData());
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.black,
//         title: const Text("PRO TRACKER",
//             style: TextStyle(
//                 fontWeight: FontWeight.bold, color: Colors.yellowAccent)),
//         actions: [
//           IconButton(
//               onPressed: () async {
//                 try {
//                   await FirebaseAuth.instance.signOut();
//                   if (mounted) {
//                     Navigator.of(context).pushAndRemoveUntil(
//                       MaterialPageRoute(builder: (context) => const Login()),
//                       (Route<dynamic> route) => false,
//                     );
//                   }
//                 } catch (e) {
//                   if (mounted) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text('Error logging out: $e')),
//                     );
//                   }
//                 }
//               },
//               icon: const Icon(Icons.logout, color: Colors.yellowAccent))
//         ],
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: _openQRScanner,
//         backgroundColor: Colors.yellowAccent,
//         icon: const Icon(Icons.qr_code_scanner, color: Colors.black),
//         label: const Text("CHECK IN",
//             style:
//                 TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
//       ),
//       body: _isLoading
//           ? const GymUserSkeleton()
//           : RefreshIndicator(
//               onRefresh: _loadUserData,
//               color: Colors.yellowAccent,
//               child: SingleChildScrollView(
//                 physics: const AlwaysScrollableScrollPhysics(),
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text("Welcome back,",
//                         style: TextStyle(fontSize: 16, color: Colors.grey)),
//                     Text(userName.toUpperCase(),
//                         style: const TextStyle(
//                             fontSize: 32,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white)),
//                     const SizedBox(height: 25),
//                     Row(
//                       children: [
//                         Expanded(
//                             child: StatsTile(
//                                 label: "SESSIONS",
//                                 value: "${presentDates.length}",
//                                 icon: Icons.bolt)),
//                         const SizedBox(width: 15),
//                         Expanded(
//                             child: StatsTile(
//                                 label: "PLAN",
//                                 value: plan,
//                                 icon: Icons.workspace_premium)),
//                       ],
//                     ),
//                     const SizedBox(height: 20),
                    
                    
//                     PaymentCard(
//                         feeStatus: feeStatus,
//                         isPaid: isPaid,
//                         expiryDate: expiryDate,
//                         onPay: _openPayFeeScreen,
//                       ),
//                       const SizedBox(height: 12),


//                       GestureDetector(
//   onTap: () => Navigator.push(
//     context,
//     MaterialPageRoute(
//       builder: (_) => const UserPaymentHistoryScreen(),
//     ),
//   ),
//   child: Container(
//     padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
//     decoration: BoxDecoration(
//       color: Colors.blueAccent.withOpacity(0.06),
//       borderRadius: BorderRadius.circular(16),
//       border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
//     ),
//     child: Row(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(9),
//           decoration: BoxDecoration(
//             color: Colors.blueAccent.withOpacity(0.12),
//             shape: BoxShape.circle,
//           ),
//           child: const Icon(Icons.receipt_long_rounded,
//               color: Colors.blueAccent, size: 20),
//         ),
//         const SizedBox(width: 14),
//         const Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 "My Payment History",
//                 style: TextStyle(
//                     color: Colors.blueAccent,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 14),
//               ),
//               SizedBox(height: 2),
//               Text(
//                 "View all transactions & screenshots",
//                 style: TextStyle(color: Colors.white38, fontSize: 11),
//               ),
//             ],
//           ),
//         ),
//         const Icon(Icons.arrow_forward_ios_rounded,
//             color: Colors.blueAccent, size: 14),
//       ],
//     ),
//   ),
// ),
 
//                     const Text("ATTENDANCE HISTORY",
//                         style: TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.yellowAccent,
//                             letterSpacing: 1.5)),
//                     const SizedBox(height: 15),
//                     AttendanceCalendar(
//                       focusedDay: focusedDay,
//                       selectedDay: selectedDay,
//                       presentDates: presentDates,
//                       onDaySelected: (day) => setState(() {
//                         selectedDay = day;
//                         focusedDay = day;
//                       }),
//                     ),
//                     const SizedBox(height: 100),
//                   ],
//                 ),
//               ),
//             ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'services/firestore_service.dart';
import 'screens/attendance_calendar.dart';
import 'screens/skeleton_loaders.dart';
import 'screens/pay_fee_screen.dart';
import 'screens/user_payment_history_screen.dart';
import '../qr_scan.dart';
import '../auth/login.dart';

class GymUser extends StatefulWidget {
  const GymUser({super.key});

  @override
  State<GymUser> createState() => _GymUserState();
}

class _GymUserState extends State<GymUser> {
  final _user = FirebaseAuth.instance.currentUser!;
  final _fs = FirestoreService();

  String _gymId = '';
  String _userName = 'Athlete';
  String _feeStatus = 'unpaid';
  String _plan = 'Standard';
  String _expiryDate = '---';
  double _currentFee = 0;
  bool _isPaid = false;
  bool _isLoading = true;

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Set<String> _presentDates = {};

  // ─── Lifecycle ───────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // ─── Data ─────────────────────────────────────────────────────────────────

  Future<void> _loadUserData() async {
    if (!_isLoading) setState(() => _isLoading = true);

    final userData = await _fs.getUserData(_user.uid);
    if (userData == null) {
      setState(() => _isLoading = false);
      return;
    }

    _gymId = userData['gymId'] ?? '';
    _userName = userData['name'] ?? 'Athlete';

    if (_gymId.isNotEmpty) {
      final memberData = await _fs.getMemberData(_gymId, _user.uid);
      if (memberData != null) {
        _feeStatus = memberData['feeStatus'] ?? 'unpaid';
        _plan = memberData['plan'] ?? 'Monthly';
        _currentFee = (memberData['currentFee'] as num?)?.toDouble() ?? 0;
        _isPaid = _feeStatus.toLowerCase() == 'paid';
        if (memberData['validUntil'] != null) {
          final date = (memberData['validUntil'] as Timestamp).toDate();
          _expiryDate = DateFormat('dd MMM yyyy').format(date);
        }
      }
      _presentDates = await _fs.getAttendance(_gymId, _user.uid);
    }

    setState(() => _isLoading = false);
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  Future<void> _openQRScanner() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QRScannerPage()),
    );
    if (code != null && code.isNotEmpty) await _markAttendance();
  }

  Future<void> _markAttendance() async {
    final now = DateTime.now();
    final todayKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    if (_presentDates.contains(todayKey)) {
      _showSnackBar('Already checked in today', Colors.orange);
      return;
    }

    await _fs.markAttendance(_gymId, _user.uid);
    setState(() => _presentDates.add(todayKey));
    _showSnackBar('Attendance marked', Colors.green);
  }

  void _openPayFeeScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PayFeeScreen(
          gymId: _gymId,
          memberId: _user.uid,
          plan: _plan,
          currentFee: _currentFee,
        ),
      ),
    ).then((_) => _loadUserData());
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const Login()),
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error logging out: $e', Colors.red);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: _buildAppBar(showActions: false),
        body: const GymUserSkeleton(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        color: Colors.yellowAccent,
        backgroundColor: Colors.grey[900],
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Check-in CTA ─────────────────────────────────────────────
              _CheckInButton(onTap: _openQRScanner),
              const SizedBox(height: 12),

              // ── Membership card ───────────────────────────────────────────
              _MembershipCard(
                plan: _plan,
                expiryDate: _expiryDate,
                feeStatus: _feeStatus,
                isPaid: _isPaid,
                currentFee: _currentFee,
                onPayTap: _openPayFeeScreen,
              ),
              const SizedBox(height: 12),

              // ── Stats row ─────────────────────────────────────────────────
              _StatsRow(
                sessionCount: _presentDates.length,
                plan: _plan,
              ),
              const SizedBox(height: 12),

              // ── Payment history nav ───────────────────────────────────────
              _NavItem(
                icon: Icons.receipt_long_rounded,
                iconColor: const Color(0xFF60a5fa),
                label: 'Payment history',
                subtitle: 'View transactions & receipts',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const UserPaymentHistoryScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Attendance calendar ───────────────────────────────────────
              _CalendarSection(
                focusedDay: _focusedDay,
                selectedDay: _selectedDay,
                presentDates: _presentDates,
                onDaySelected: (day) => setState(() {
                  _selectedDay = day;
                  _focusedDay = day;
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar({bool showActions = true}) {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      titleSpacing: 16,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome back',
            style: TextStyle(fontSize: 12, color: Colors.white54),
          ),
          Text(
            _userName.toUpperCase(),
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
      actions: showActions
          ? [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded,
                    color: Colors.white54),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white54),
                onPressed: _logout,
              ),
              const SizedBox(width: 4),
            ]
          : null,
    );
  }
}

// ─── Check-in button ──────────────────────────────────────────────────────────

class _CheckInButton extends StatelessWidget {
  const _CheckInButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.yellowAccent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_scanner_rounded,
                  size: 20, color: Colors.black),
              SizedBox(width: 10),
              Text(
                'CHECK IN',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Membership card ──────────────────────────────────────────────────────────

class _MembershipCard extends StatelessWidget {
  const _MembershipCard({
    required this.plan,
    required this.expiryDate,
    required this.feeStatus,
    required this.isPaid,
    required this.currentFee,
    required this.onPayTap,
  });

  final String plan;
  final String expiryDate;
  final String feeStatus;
  final bool isPaid;
  final double currentFee;
  final VoidCallback onPayTap;

  @override
  Widget build(BuildContext context) {
    final statusColor =
        isPaid ? const Color(0xFF4ade80) : const Color(0xFFf87171);
    final statusBg = isPaid
        ? const Color(0xFF4ade80).withOpacity(0.1)
        : const Color(0xFFf87171).withOpacity(0.1);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          // Top — plan info + status pill
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current plan',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plan,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Expires $expiryDate',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    feeStatus.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom — fee + action
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF1A1A1A))),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monthly fee',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Rs ${currentFee.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                isPaid
                    ? const Text(
                        'All clear ✓',
                        style: TextStyle(
                          color: Color(0xFF4ade80),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    : Material(
                        color: Colors.yellowAccent,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: onPayTap,
                          borderRadius: BorderRadius.circular(10),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            child: Text(
                              'Pay now',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stats row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.sessionCount, required this.plan});

  final int sessionCount;
  final String plan;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Sessions this month',
            value: '$sessionCount',
            sub: 'total check-ins',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Plan',
            value: plan,
            sub: 'active membership',
          ),
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
  });

  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(sub,
              style: const TextStyle(
                  color: Color(0xFF444444), fontSize: 11)),
        ],
      ),
    );
  }
}

// ─── Nav item ─────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF141414),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    Text(label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Color(0xFF555555), fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFF333333), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Calendar section ─────────────────────────────────────────────────────────

class _CalendarSection extends StatelessWidget {
  const _CalendarSection({
    required this.focusedDay,
    required this.selectedDay,
    required this.presentDates,
    required this.onDaySelected,
  });

  final DateTime focusedDay;
  final DateTime selectedDay;
  final Set<String> presentDates;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ATTENDANCE',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          AttendanceCalendar(
            focusedDay: focusedDay,
            selectedDay: selectedDay,
            presentDates: presentDates,
            onDaySelected: onDaySelected,
          ),
        ],
      ),
    );
  }
}