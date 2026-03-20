import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'services/firestore_service.dart';
import 'screens/attendance_calendar.dart';
import '../../shared/skeleton_loaders.dart';
import 'screens/pay_fee_screen.dart';
import 'screens/user_payment_history_screen.dart';
import 'screens/payment_pending_screen.dart';
import '../../shared/qr_scan.dart';
import '../../auth/login.dart';
import '../../shared/gym_status_service.dart';

class GymUser extends StatefulWidget {
  const GymUser({super.key});

  @override
  State<GymUser> createState() => _GymUserState();
}

class _GymUserState extends State<GymUser> {
  final _user = FirebaseAuth.instance.currentUser!;
  final _fs   = FirestoreService();

  String _gymId      = '';
  String _gymName    = '';
  String _userName   = 'Athlete';
  String _feeStatus  = 'unpaid';
  String _plan       = 'Standard';
  String _expiryDate = '---';
  double _currentFee = 0;
  bool   _isPaid     = false;
  bool   _isLoading  = true;

  GymStatusResult? _gymStatus;

  String _pendingPaymentId     = '';
  String _pendingReferenceCode = '';
  double _pendingAmount        = 0;

  DateTime    _focusedDay   = DateTime.now();
  DateTime    _selectedDay  = DateTime.now();
  Set<String> _presentDates = {};

  // ─── Computed helpers ───────────────────────────────────────────────────
  bool get _isLocked   => _gymStatus?.access == GymAccessLevel.locked;
  bool get _isReadOnly => _gymStatus?.access == GymAccessLevel.readOnly;
  bool get _isFull     => _gymStatus?.access == GymAccessLevel.full;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (!_isLoading) setState(() => _isLoading = true);
    try {
      final userData = await _fs.getUserData(_user.uid);
      if (userData == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      _gymId    = userData['gymId'] ?? '';
      _userName = userData['name']  ?? 'Athlete';

      if (_gymId.isNotEmpty) {
        // Check gym status first
        final statusResult = await GymStatusService.checkAccess(_gymId);

        final memberData = await _fs.getMemberData(_gymId, _user.uid);
        if (memberData != null) {
          _feeStatus  = memberData['feeStatus'] ?? 'unpaid';
          _plan       = memberData['plan']       ?? 'Monthly';
          _currentFee = (memberData['currentFee'] as num?)?.toDouble() ?? 0;
          _isPaid     = _feeStatus.toLowerCase() == 'paid';
          if (memberData['validUntil'] != null) {
            _expiryDate = DateFormat('dd MMM yyyy')
                .format((memberData['validUntil'] as Timestamp).toDate());
          }
        }

        // Fetch gym name for locked/readonly screens
        final gymDoc = await FirebaseFirestore.instance
            .collection('gyms')
            .doc(_gymId)
            .get();
        _gymName = gymDoc.data()?['gymName'] ?? 'Gym';

        _pendingPaymentId     = '';
        _pendingReferenceCode = '';
        _pendingAmount        = 0;

        if (_feeStatus.toLowerCase() == 'pending') await _fetchPendingPayment();

        _presentDates = await _fs.getAttendance(_gymId, _user.uid);

        if (mounted) setState(() => _gymStatus = statusResult);
      }
    } catch (e) {
      debugPrint('_loadUserData error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchPendingPayment() async {
    try {
      QuerySnapshot snap;
      try {
        snap = await FirebaseFirestore.instance
            .collection('gyms').doc(_gymId).collection('payments')
            .where('memberId', isEqualTo: _user.uid)
            .where('status',   isEqualTo: 'pending')
            .orderBy('createdAt', descending: true)
            .limit(1).get();
      } catch (_) {
        snap = await FirebaseFirestore.instance
            .collection('gyms').doc(_gymId).collection('payments')
            .where('memberId', isEqualTo: _user.uid)
            .where('status',   isEqualTo: 'pending')
            .limit(10).get();
      }

      if (snap.docs.isEmpty) {
        _pendingPaymentId = 'NOT_FOUND';
        return;
      }

      final docs = snap.docs.toList()
        ..sort((a, b) {
          final aTs = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          final bTs = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          if (aTs == null) return 1;
          if (bTs == null) return -1;
          return bTs.compareTo(aTs);
        });

      final doc  = docs.first;
      final data = doc.data() as Map<String, dynamic>;
      _pendingPaymentId     = doc.id;
      _pendingReferenceCode = data['referenceCode'] ?? '';
      _pendingAmount        = (data['amount'] as num?)?.toDouble() ?? _currentFee;
    } catch (e) {
      debugPrint('_fetchPendingPayment error: $e');
      _pendingPaymentId = 'NOT_FOUND';
    }
  }

  // ─── Write-gated action helper ───────────────────────────────────────────

  void _requireFullAccess(VoidCallback action) {
    if (_isLocked) {
      _showSnackBar('Gym is unavailable. Contact your gym.', Colors.redAccent);
      return;
    }
    if (_isReadOnly) {
      _showSnackBar(
        'Online services are currently disabled by your gym. Visit in person.',
        Colors.orangeAccent,
      );
      return;
    }
    action();
  }

  Future<void> _openQRScanner() async {
    // Check-in is a write — blocked in readOnly/locked
    _requireFullAccess(() async {
      final code = await Navigator.push<String>(
          context, MaterialPageRoute(builder: (_) => const QRScannerPage()));
      if (code != null && code.isNotEmpty) await _markAttendance();
    });
  }

  Future<void> _markAttendance() async {
    final now = DateTime.now();
    final key = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (_presentDates.contains(key)) {
      _showSnackBar('Already checked in today', Colors.orange);
      return;
    }
    await _fs.markAttendance(_gymId, _user.uid);
    setState(() => _presentDates.add(key));
    _showSnackBar('Attendance marked', Colors.green);
  }

  void _openPayFeeScreen() {
    // Payment is a write — blocked in readOnly/locked
    _requireFullAccess(() {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => PayFeeScreen(
            gymId:     _gymId,
            memberId:  _user.uid,
            plan:      _plan,
            currentFee: _currentFee),
      )).then((_) => _loadUserData());
    });
  }

  void _openPendingScreen() {
    // Viewing pending status is read — allowed in readOnly
    // But cancelling/acting on it is a write — guard inside that screen
    if (_gymId.isEmpty) {
      _showSnackBar('Gym data not loaded. Pull down to refresh.', Colors.orange);
      return;
    }
    if (_pendingPaymentId.isEmpty || _pendingPaymentId == 'NOT_FOUND') {
      _showSnackBar('Payment record not found. Pull down to refresh.', Colors.orange);
      _loadUserData();
      return;
    }
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PaymentPendingScreen(
        gymId:         _gymId,
        paymentId:     _pendingPaymentId,
        referenceCode: _pendingReferenceCode,
        amount:        _pendingAmount,
      ),
    )).then((_) => _loadUserData());
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const Login()), (_) => false);
    } catch (e) {
      if (mounted) _showSnackBar('Error logging out: $e', Colors.red);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Loading gate
    if (_isLoading || _gymStatus == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: _buildAppBar(showActions: false),
        body: const GymUserSkeleton(),
      );
    }

    // Full lockout
    if (_isLocked) {
      return _LockedScreen(
        gymName:  _gymName,
        message:  _gymStatus!.message,
        onLogout: _logout,
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Read-only banner — isSaaSActive=false
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
                      'Online services are disabled. Visit your gym in person.',
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
              onRefresh: _loadUserData,
              color: Colors.yellowAccent,
              backgroundColor: Colors.grey[900],
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Check-in blocked in readOnly
                    _CheckInButton(
                      onTap: _openQRScanner,
                      disabled: _isReadOnly,
                    ),
                    const SizedBox(height: 12),
                    _MembershipCard(
                      plan:             _plan,
                      expiryDate:       _expiryDate,
                      feeStatus:        _feeStatus,
                      isPaid:           _isPaid,
                      currentFee:       _currentFee,
                      // Pay/pending blocked in readOnly
                      onPayTap:     _openPayFeeScreen,
                      onPendingTap: _openPendingScreen,
                      pendingPaymentId: _pendingPaymentId,
                      isReadOnly:       _isReadOnly,
                    ),
                    const SizedBox(height: 12),
                    _StatsRow(
                        sessionCount: _presentDates.length, plan: _plan),
                    const SizedBox(height: 12),
                    // Payment history is read — always allowed
                    _NavItem(
                      icon:      Icons.receipt_long_rounded,
                      iconColor: const Color(0xFF60a5fa),
                      label:     'Payment history',
                      subtitle:  'View transactions & receipts',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const UserPaymentHistoryScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _CalendarSection(
                      focusedDay:    _focusedDay,
                      selectedDay:   _selectedDay,
                      presentDates:  _presentDates,
                      onDaySelected: (day) =>
                          setState(() => _selectedDay = _focusedDay = day),
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

  AppBar _buildAppBar({bool showActions = true}) => AppBar(
    backgroundColor: Colors.black,
    elevation: 0,
    titleSpacing: 16,
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Welcome back',
            style: TextStyle(fontSize: 12, color: Colors.white54)),
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

// ─── Locked screen ────────────────────────────────────────────────────────────

class _LockedScreen extends StatelessWidget {
  final String gymName;
  final String message;
  final VoidCallback onLogout;

  const _LockedScreen({
    required this.gymName,
    required this.message,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          gymName.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
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
                    fontWeight: FontWeight.bold),
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
                'Please contact your gym for more information.',
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

// ─── Check-in button ──────────────────────────────────────────────────────────

class _CheckInButton extends StatelessWidget {
  const _CheckInButton({required this.onTap, this.disabled = false});
  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: disabled ? 0.4 : 1.0,
    child: Material(
      color: disabled ? Colors.grey[800] : Colors.yellowAccent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        // null onTap prevents the ripple and tap in disabled state
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_scanner_rounded,
                  size: 20,
                  color: disabled ? Colors.white38 : Colors.black),
              const SizedBox(width: 10),
              Text(
                disabled ? 'CHECK-IN UNAVAILABLE' : 'CHECK IN',
                style: TextStyle(
                  color: disabled ? Colors.white38 : Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
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
    required this.onPendingTap,
    required this.pendingPaymentId,
    this.isReadOnly = false,
  });

  final String plan, expiryDate, feeStatus;
  final bool   isPaid;
  final double currentFee;
  final VoidCallback onPayTap, onPendingTap;
  final String pendingPaymentId;
  final bool   isReadOnly;

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    final Color statusBg;
    switch (feeStatus.toLowerCase()) {
      case 'paid':
        statusColor = const Color(0xFF4ade80);
        statusBg    = const Color(0xFF4ade80).withOpacity(0.1);
      case 'pending':
        statusColor = const Color(0xFFFFB300);
        statusBg    = const Color(0xFFFFB300).withOpacity(0.1);
      default:
        statusColor = const Color(0xFFf87171);
        statusBg    = const Color(0xFFf87171).withOpacity(0.1);
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Current plan',
                        style: TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text(plan,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text('Expires $expiryDate',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(99)),
                child: Text(feeStatus.toUpperCase(),
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5)),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF1A1A1A)))),
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Monthly fee',
                  style: TextStyle(color: Colors.white38, fontSize: 11)),
              const SizedBox(height: 3),
              Text('Rs ${currentFee.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
            ]),
            const Spacer(),
            _buildAction(),
          ]),
        ),
      ]),
    );
  }

  Widget _buildAction() {
    // In read-only mode hide pay/pending actions — show disabled message
    if (isReadOnly) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orangeAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.block_rounded, size: 13, color: Colors.orangeAccent),
          SizedBox(width: 6),
          Text('Payments disabled',
              style: TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ]),
      );
    }

    switch (feeStatus.toLowerCase()) {
      case 'paid':
        return const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_circle_rounded,
              color: Color(0xFF4ade80), size: 16),
          SizedBox(width: 6),
          Text('All clear',
              style: TextStyle(
                  color: Color(0xFF4ade80),
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ]);

      case 'pending':
        if (pendingPaymentId.isEmpty) {
          return const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFFFFB300)));
        }
        if (pendingPaymentId == 'NOT_FOUND') {
          return GestureDetector(
            onTap: onPendingTap,
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.refresh_rounded,
                  size: 15, color: Color(0xFFFFB300)),
              SizedBox(width: 5),
              Text('Retry',
                  style: TextStyle(
                      color: Color(0xFFFFB300),
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ]),
          );
        }
        return Material(
          color: const Color(0xFFFFB300).withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onPendingTap,
            borderRadius: BorderRadius.circular(10),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.hourglass_top_rounded,
                    size: 14, color: Color(0xFFFFB300)),
                SizedBox(width: 6),
                Text('View status',
                    style: TextStyle(
                        color: Color(0xFFFFB300),
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        );

      default:
        return Material(
          color: Colors.yellowAccent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onPayTap,
            borderRadius: BorderRadius.circular(10),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text('Pay now',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        );
    }
  }
}

// ─── Stats row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.sessionCount, required this.plan});
  final int    sessionCount;
  final String plan;

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(
        child: _StatCard(
            label: 'Sessions this month',
            value: '$sessionCount',
            sub:   'total check-ins')),
    const SizedBox(width: 8),
    Expanded(
        child: _StatCard(
            label: 'Plan',
            value: plan,
            sub:   'active membership')),
  ]);
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.label, required this.value, required this.sub});
  final String label, value, sub;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF141414),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withOpacity(0.06)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(color: Colors.white38, fontSize: 11)),
      const SizedBox(height: 8),
      Text(value,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1)),
      const SizedBox(height: 4),
      Text(sub,
          style:
              const TextStyle(color: Color(0xFF444444), fontSize: 11)),
    ]),
  );
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
  final IconData     icon;
  final Color        iconColor;
  final String       label, subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF141414),
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
                color: iconColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 18)),
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
        ]),
      ),
    ),
  );
}

// ─── Calendar section ─────────────────────────────────────────────────────────

class _CalendarSection extends StatelessWidget {
  const _CalendarSection({
    required this.focusedDay,
    required this.selectedDay,
    required this.presentDates,
    required this.onDaySelected,
  });
  final DateTime          focusedDay, selectedDay;
  final Set<String>       presentDates;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF141414),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.06)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ATTENDANCE',
            style: TextStyle(
                color: Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2)),
        const SizedBox(height: 12),
        AttendanceCalendar(
          focusedDay:    focusedDay,
          selectedDay:   selectedDay,
          presentDates:  presentDates,
          onDaySelected: onDaySelected,
        ),
      ],
    ),
  );
}