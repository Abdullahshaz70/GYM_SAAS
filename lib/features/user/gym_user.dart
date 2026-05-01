import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'services/firestore_service.dart';
import 'screens/attendance_calendar.dart';
import '../../shared/skeleton_loaders.dart';
import 'screens/pay_fee_screen.dart';
import 'screens/user_payment_history_screen.dart';
import 'screens/user_settings_screen.dart';
import 'screens/payment_pending_screen.dart';
import 'screens/workout_log_screen.dart';
import 'screens/body_measurements_screen.dart';
import '../../shared/qr_scan.dart';
import '../../auth/login.dart';
import '../../shared/gym_status_service.dart';
import '../../shared/utils.dart';

class GymUser extends StatefulWidget {
  const GymUser({super.key});

  @override
  State<GymUser> createState() => _GymUserState();
}

class _GymUserState extends State<GymUser> {
  final _user = FirebaseAuth.instance.currentUser!;
  final _fs   = FirestoreService();

  String  _gymId      = '';
  String  _gymName    = '';
  String  _userName   = 'Athlete';
  String  _feeStatus  = 'unpaid';
  String  _plan       = 'Standard';
  String  _expiryDate = '---';
  double  _currentFee = 0;
  bool    _isPaid     = false;
  bool    _isLoading  = true;
  String? _photoUrl;

  GymStatusResult? _gymStatus;

  String _pendingPaymentId     = '';
  String _pendingReferenceCode = '';
  double _pendingAmount        = 0;

  DateTime      _focusedDay  = DateTime.now();
  DateTime      _selectedDay = DateTime.now();
  Set<DateTime> _presentDates = {};

  bool _isLoggingOut = false;

  bool get _isLocked   => _gymStatus?.access == GymAccessLevel.locked;
  bool get _isReadOnly => _gymStatus?.access == GymAccessLevel.readOnly;

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

      _gymId    = userData['gymId']    ?? '';
      _userName = userData['name']     ?? 'Athlete';
      _photoUrl = userData['photoUrl'] as String?;

      if (_gymId.isNotEmpty) {
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
    _requireFullAccess(() async {
      final code = await Navigator.push<String>(
          context, MaterialPageRoute(builder: (_) => const QRScannerPage()));
      if (code != null && code.isNotEmpty) await _markAttendance();
    });
  }

  Future<void> _markAttendance() async {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_presentDates.contains(today)) {
      _showSnackBar('Already checked in today', Colors.orange);
      return;
    }
    await _fs.markAttendance(_gymId, _user.uid);
    setState(() => _presentDates.add(today));
    _showSnackBar('Attendance marked', Colors.green);
  }

  void _openPayFeeScreen() {
    _requireFullAccess(() {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => PayFeeScreen(
            gymId:      _gymId,
            memberId:   _user.uid,
            plan:       _plan,
            currentFee: _currentFee),
      )).then((_) => _loadUserData());
    });
  }

  void _openPendingScreen() {
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

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _gymStatus == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        appBar: _buildAppBar(showActions: false),
        body: const GymUserSkeleton(),
      );
    }

    if (_isLocked) {
      return _LockedScreen(
        gymName:  _gymName,
        message:  _gymStatus!.message,
        onLogout: _logout,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (_isReadOnly) _ReadOnlyBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadUserData,
              color: Colors.yellowAccent,
              backgroundColor: const Color(0xFF1A1A1A),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile header
                    _ProfileBanner(
                      userName: _userName,
                      gymName:  _gymName,
                      photoUrl: _photoUrl,
                    ),
                    const SizedBox(height: 20),

                    // Check-in CTA
                    _CheckInButton(onTap: _openQRScanner, disabled: _isReadOnly),
                    const SizedBox(height: 20),

                    // Membership
                    _sectionLabel('MEMBERSHIP'),
                    const SizedBox(height: 8),
                    _MembershipCard(
                      plan:             _plan,
                      expiryDate:       _expiryDate,
                      feeStatus:        _feeStatus,
                      isPaid:           _isPaid,
                      currentFee:       _currentFee,
                      onPayTap:         _openPayFeeScreen,
                      onPendingTap:     _openPendingScreen,
                      pendingPaymentId: _pendingPaymentId,
                      isReadOnly:       _isReadOnly,
                    ),
                    const SizedBox(height: 12),
                    _StatsRow(sessionCount: _presentDates.length, plan: _plan),
                    const SizedBox(height: 20),

                    // Quick links
                    _sectionLabel('QUICK LINKS'),
                    const SizedBox(height: 8),
                    _NavItem(
                      icon:      Icons.receipt_long_rounded,
                      iconColor: const Color(0xFF60a5fa),
                      label:     'Payment History',
                      subtitle:  'View transactions & receipts',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const UserPaymentHistoryScreen()),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _NavItem(
                      icon:      Icons.fitness_center_rounded,
                      iconColor: Colors.yellowAccent,
                      label:     'Workout Log',
                      subtitle:  'Track your training sessions',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const WorkoutLogScreen()),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _NavItem(
                      icon:      Icons.monitor_weight_rounded,
                      iconColor: const Color(0xFF4ADE80),
                      label:     'Body Tracker',
                      subtitle:  'Weight, BMI & measurements',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const BodyMeasurementsScreen()),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Attendance calendar
                    _sectionLabel('ATTENDANCE'),
                    const SizedBox(height: 8),
                    _CalendarCard(
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

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(left: 2),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.8,
      ),
    ),
  );

  void _openMenuSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserMenuSheet(
        userName:     _userName,
        gymName:      _gymName,
        isLoggingOut: _isLoggingOut,
        photoUrl:     _photoUrl,
        onSettingsTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserSettingsScreen(
                gymId:    _gymId,
                userName: _userName,
                photoUrl: _photoUrl,
              ),
            ),
          ).then((_) => _loadUserData());
        },
        onLogoutTap: () {
          Navigator.pop(context);
          _logout();
        },
      ),
    );
  }

  AppBar _buildAppBar({bool showActions = true}) => AppBar(
    backgroundColor: const Color(0xFF0A0A0A),
    elevation: 0,
    title: Text(
      _gymName.isNotEmpty ? _gymName.toUpperCase() : 'GYM',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    ),
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(
          height: 1, color: Colors.white.withOpacity(0.05)),
    ),
    actions: showActions
        ? [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded,
                  color: Colors.white54),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
              onPressed: _openMenuSheet,
            ),
          ]
        : null,
  );
}

// ─── User menu sheet ─────────────────────────────────────────────────────────

class _UserMenuSheet extends StatelessWidget {
  const _UserMenuSheet({
    required this.userName,
    required this.gymName,
    required this.isLoggingOut,
    required this.onSettingsTap,
    required this.onLogoutTap,
    this.photoUrl,
  });

  final String       userName, gymName;
  final bool         isLoggingOut;
  final VoidCallback onSettingsTap, onLogoutTap;
  final String?      photoUrl;

  String get _initials {
    final words = userName.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words[0].isEmpty) return 'A';
    if (words.length == 1) return words[0].substring(0, words[0].length.clamp(0, 2)).toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top:   BorderSide(color: Color(0xFF1E1E1E)),
          left:  BorderSide(color: Color(0xFF1E1E1E)),
          right: BorderSide(color: Color(0xFF1E1E1E)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF222222),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 20),

          // User identity header
          Container(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF181818))),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.yellowAccent.withOpacity(0.15),
                    border: Border.all(
                        color: Colors.yellowAccent.withOpacity(0.3),
                        width: 1.5),
                  ),
                  child: photoUrl != null
                      ? ClipOval(
                          child: Image.network(
                            photoUrl!,
                            fit: BoxFit.cover,
                            width: 44,
                            height: 44,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(_initials,
                                  style: const TextStyle(
                                      color: Colors.yellowAccent,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800)),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(_initials,
                              style: const TextStyle(
                                  color: Colors.yellowAccent,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800)),
                        ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      gymName.isNotEmpty ? '$gymName · Member' : 'Member',
                      style: const TextStyle(
                        color: Color(0xFF555555),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Settings
          _SheetItem(
            icon:      Icons.settings_rounded,
            iconColor: Colors.white54,
            label:     'Settings',
            subtitle:  'Account preferences & deletion',
            onTap:     onSettingsTap,
          ),

          const _SheetDivider(),

          // Logout
          _LogoutItem(isLoading: isLoggingOut, onTap: onLogoutTap),
        ],
      ),
    );
  }
}

// ─── Sheet item ───────────────────────────────────────────────────────────────

class _SheetItem extends StatelessWidget {
  const _SheetItem({
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
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(11),
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
                          fontSize: 15,
                          fontWeight: FontWeight.w500)),
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

// ─── Sheet divider ────────────────────────────────────────────────────────────

class _SheetDivider extends StatelessWidget {
  const _SheetDivider();

  @override
  Widget build(BuildContext context) => Container(
    height: 1,
    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    color: const Color(0xFF181818),
  );
}

// ─── Sheet logout ─────────────────────────────────────────────────────────────

class _LogoutItem extends StatelessWidget {
  const _LogoutItem({required this.isLoading, required this.onTap});

  final bool         isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      splashColor: Colors.redAccent.withOpacity(0.08),
      highlightColor: Colors.redAccent.withOpacity(0.04),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(11),
              ),
              child: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                          strokeWidth: 1.8, color: Colors.redAccent),
                    )
                  : const Icon(Icons.logout_rounded,
                      color: Colors.redAccent, size: 18),
            ),
            const SizedBox(width: 14),
            const Text(
              'Log out',
              style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 15,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    ),
  );
}

// ─── Read-only banner ─────────────────────────────────────────────────────────

class _ReadOnlyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    color: Colors.orangeAccent,
    child: const Row(
      children: [
        Icon(Icons.warning_amber_rounded, color: Colors.black, size: 18),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Online services are disabled. Visit your gym in person.',
            style: TextStyle(
                color: Colors.black, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

// ─── Profile banner ───────────────────────────────────────────────────────────

class _ProfileBanner extends StatelessWidget {
  const _ProfileBanner({
    required this.userName,
    required this.gymName,
    this.photoUrl,
  });
  final String  userName, gymName;
  final String? photoUrl;

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: Colors.yellowAccent.withOpacity(0.12),
          shape: BoxShape.circle,
          border: Border.all(
              color: Colors.yellowAccent.withOpacity(0.35), width: 1.5),
        ),
        child: photoUrl != null
            ? ClipOval(
                child: Image.network(
                  photoUrl!,
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
                      style: const TextStyle(
                        color: Colors.yellowAccent,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              )
            : Center(
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
                  style: const TextStyle(
                    color: Colors.yellowAccent,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _greeting(),
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              userName.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                height: 1.15,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (gymName.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      size: 11, color: Colors.white38),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      gymName,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ],
  );
}

// ─── Locked screen ────────────────────────────────────────────────────────────

class _LockedScreen extends StatelessWidget {
  final String       gymName, message;
  final VoidCallback onLogout;

  const _LockedScreen({
    required this.gymName,
    required this.message,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0A0A0A),
    appBar: AppBar(
      backgroundColor: const Color(0xFF0A0A0A),
      elevation: 0,
      title: Text(
        gymName.toUpperCase(),
        style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5),
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
            const Text('Gym Unavailable',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 14, height: 1.6)),
            const SizedBox(height: 12),
            const Text(
              'Please contact your gym for more information.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 36),
            OutlinedButton(
              onPressed: onLogout,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
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

// ─── Check-in button ──────────────────────────────────────────────────────────

class _CheckInButton extends StatelessWidget {
  const _CheckInButton({required this.onTap, this.disabled = false});
  final VoidCallback onTap;
  final bool         disabled;

  @override
  Widget build(BuildContext context) {
    final bgColor =
        disabled ? const Color(0xFF1C1C1C) : Colors.yellowAccent;
    final fgColor = disabled ? Colors.white24 : Colors.black;

    return Opacity(
      opacity: disabled ? 0.6 : 1.0,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: disabled
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.qr_code_scanner_rounded,
                      size: 22, color: fgColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        disabled ? 'CHECK-IN UNAVAILABLE' : 'CHECK IN TODAY',
                        style: TextStyle(
                          color: fgColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        disabled
                            ? 'Online services are disabled'
                            : 'Scan the QR code at the entrance',
                        style: TextStyle(
                          color: disabled
                              ? Colors.white24
                              : Colors.black.withOpacity(0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: fgColor),
              ],
            ),
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
    final Color accentColor;
    switch (feeStatus.toLowerCase()) {
      case 'paid':
        statusColor = const Color(0xFF4ade80);
        statusBg    = const Color(0xFF4ade80).withOpacity(0.1);
        accentColor = const Color(0xFF4ade80);
      case 'pending':
        statusColor = const Color(0xFFFFB300);
        statusBg    = const Color(0xFFFFB300).withOpacity(0.1);
        accentColor = const Color(0xFFFFB300);
      default:
        statusColor = const Color(0xFFf87171);
        statusBg    = const Color(0xFFf87171).withOpacity(0.1);
        accentColor = const Color(0xFFf87171);
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          // Accent strip
          Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentColor, accentColor.withOpacity(0)],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CURRENT PLAN',
                          style: TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                              letterSpacing: 1.2)),
                      const SizedBox(height: 6),
                      Text(plan,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 11, color: Colors.white38),
                          const SizedBox(width: 4),
                          Text('Expires $expiryDate',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(99)),
                  child: Text(feeStatus.toUpperCase(),
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8)),
                ),
              ],
            ),
          ),

          // Divider + fee + action
          Container(
            margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            height: 1,
            color: Colors.white.withOpacity(0.05),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('FEE',
                        style: TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 4),
                    Text(
                      'Rs ${currentFee.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const Spacer(),
                _buildAction(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAction() {
    if (isReadOnly) {
      return Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              Icon(Icons.refresh_rounded, size: 15, color: Color(0xFFFFB300)),
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
        icon:  Icons.fitness_center_rounded,
        iconColor: Colors.yellowAccent,
        label: 'This Month',
        value: '$sessionCount',
        sub:   'check-ins',
      ),
    ),
    const SizedBox(width: 10),
    Expanded(
      child: _StatCard(
        icon:  Icons.card_membership_rounded,
        iconColor: const Color(0xFF60a5fa),
        label: 'Active Plan',
        value: plan,
        sub:   'membership',
      ),
    ),
  ]);
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.sub,
  });
  final IconData icon;
  final Color    iconColor;
  final String   label, value, sub;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF141414),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.06)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 17),
      ),
      const SizedBox(height: 12),
      Text(label,
          style: const TextStyle(color: Colors.white38, fontSize: 10,
              letterSpacing: 0.5)),
      const SizedBox(height: 4),
      Text(value,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1),
          overflow: TextOverflow.ellipsis),
      const SizedBox(height: 3),
      Text(sub,
          style: const TextStyle(color: Color(0xFF444444), fontSize: 11)),
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
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(11)),
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
              color: Color(0xFF333333), size: 20),
        ]),
      ),
    ),
  );
}

// ─── Calendar card ────────────────────────────────────────────────────────────

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.focusedDay,
    required this.selectedDay,
    required this.presentDates,
    required this.onDaySelected,
  });
  final DateTime          focusedDay, selectedDay;
  final Set<DateTime>     presentDates;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF141414),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.06)),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AttendanceCalendar(
        focusedDay:    focusedDay,
        selectedDay:   selectedDay,
        presentDates:  presentDates,
        onDaySelected: onDaySelected,
      ),
    ),
  );
}
