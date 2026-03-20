import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auth/login.dart';
import 'Staff/manage_staff_screen.dart';
import 'widgets/pending_payments_screen.dart';
import '../../shared/skeleton_loaders.dart';
import 'widgets/action_menu_sheet.dart';
import 'widgets/attendance_card.dart';
import 'widgets/member_list_section.dart';
import 'widgets/pending_banner.dart';
import 'widgets/qr_sheets.dart';
import 'widgets/stats_strip.dart';
import '../../shared/gym_status_service.dart';
import '../../shared/utils.dart';

class GymOwnerScreen extends StatefulWidget {
  const GymOwnerScreen({super.key});

  @override
  State<GymOwnerScreen> createState() => _GymOwnerScreenState();
}

class _GymOwnerScreenState extends State<GymOwnerScreen> {
  GymStatusResult? _gymStatus;

  final _searchController = TextEditingController();

  bool _isLoggingOut = false;
  bool _loadingStats = true;
  bool _loadingMembers = true;

  double _totalRevenue = 0;
  double _cashRevenue = 0;
  double _onlineRevenue = 0;
  int _pendingOnlineCount = 0;
  int _totalMembers = 0;
  int _todayAttendanceCount = 0;

  String? _gymId;
  String? _gymName;
  String? _gymCode;

  List<Map<String, dynamic>> _allMembers = [];
  List<Map<String, dynamic>> _filteredMembers = [];
  String _activeFilter = 'all';

  static const int _pageSize = 15;
  DocumentSnapshot? _lastDocument;
  bool _hasMoreMembers = true;
  bool _loadingMoreMembers = false;

  // ─── Computed helpers ────────────────────────────────────────────────────

  bool get _isReadOnly => _gymStatus?.access == GymAccessLevel.readOnly;
  bool get _isLocked   => _gymStatus?.access == GymAccessLevel.locked;
  bool get _isFull     => _gymStatus?.access == GymAccessLevel.full;

  // ─── Lifecycle ───────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fetchGymStats();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── Data fetching ────────────────────────────────────────────────────────

  Future<void> _fetchGymStats() async {
    if (!_loadingStats) setState(() => _loadingStats = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final firestore = FirebaseFirestore.instance;

    final gymQuery = await firestore
        .collection('gyms')
        .where('ownerUid', isEqualTo: uid)
        .limit(1)
        .get();

    if (gymQuery.docs.isEmpty) {
      setState(() => _loadingStats = false);
      return;
    }

    _gymId = gymQuery.docs.first.id;

    // Check status AFTER we have gymId
    final statusResult = await GymStatusService.checkAccess(_gymId!);

    final today = DateTime.now();
    final todayKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final results = await Future.wait([
      firestore
          .collection('gyms')
          .doc(_gymId)
          .collection('attendance')
          .where('date', isEqualTo: todayKey)
          .get(),
      firestore
          .collection('gyms')
          .doc(_gymId)
          .collection('payments')
          .get(),
      firestore
          .collection('gyms')
          .doc(_gymId)
          .collection('members')
          .get(),
    ]);

    final attendanceSnapshot = results[0];
    final paymentsSnapshot = results[1];
    final membersSnapshot = results[2];

    double revenue = 0, cashRev = 0, onlineRev = 0;
    int pendingCount = 0;

    for (final doc in paymentsSnapshot.docs) {
      final data = doc.data();
      final amount = (data['amount'] as num).toDouble();
      final method = (data['method'] ?? '').toString().toLowerCase();
      final status = (data['status'] ?? '').toString().toLowerCase();
      final isOnline = method == 'easypaisa' || method == 'jazzcash';

      if (status == 'pending' && isOnline) pendingCount++;

      if (status == 'completed' || status == '') {
        revenue += amount;
        if (isOnline) {
          onlineRev += amount;
        } else {
          cashRev += amount;
        }
      }
    }

    setState(() {
      _gymStatus = statusResult;
      _todayAttendanceCount = attendanceSnapshot.size;
      _totalRevenue = revenue;
      _cashRevenue = cashRev;
      _onlineRevenue = onlineRev;
      _pendingOnlineCount = pendingCount;
      _totalMembers = membersSnapshot.size;
      _gymName = gymQuery.docs.first['gymName'] ?? 'Owner';
      _gymCode = gymQuery.docs.first['registrationCode'] ?? '';
      _loadingStats = false;
    });

    await _fetchMembers(refresh: true);
  }

  Future<void> _fetchMembers({bool refresh = false}) async {
    if (_gymId == null) return;

    if (refresh) {
      setState(() {
        _allMembers = [];
        _lastDocument = null;
        _hasMoreMembers = true;
        _loadingMembers = true;
      });
    } else {
      if (!_hasMoreMembers || _loadingMoreMembers) return;
      setState(() => _loadingMoreMembers = true);
    }

    try {
      Query query = FirebaseFirestore.instance
          .collection('gyms')
          .doc(_gymId)
          .collection('members')
          .limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          _hasMoreMembers = false;
          _loadingMembers = false;
          _loadingMoreMembers = false;
        });
        return;
      }

      _lastDocument = snapshot.docs.last;

      final futures = snapshot.docs.map((doc) async {
        final uid = doc.id;
        final data = doc.data() as Map<String, dynamic>;

        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();

        if (!userDoc.exists) return null;
        if ((userDoc.data()?['role'] ?? 'member') == 'staff') return null;

        return {
          'uid': uid,
          'name': userDoc.data()?['name'] ?? data['name'] ?? 'Unknown',
          'plan': data['plan'] ?? 'Monthly',
          'feeStatus': data['feeStatus'] ?? 'unpaid',
          'validUntil': data['validUntil'],
        };
      });

      final results = await Future.wait(futures);
      final newMembers = results.whereType<Map<String, dynamic>>().toList();

      setState(() {
        _allMembers.addAll(newMembers);
        _hasMoreMembers = snapshot.docs.length == _pageSize;
        _applyFilter();
        _loadingMembers = false;
        _loadingMoreMembers = false;
      });
    } catch (_) {
      setState(() {
        _loadingMembers = false;
        _loadingMoreMembers = false;
      });
    }
  }

  // ─── Filtering ────────────────────────────────────────────────────────────

  void _applyFilter() {
    final query = _searchController.text.toLowerCase();
    _filteredMembers = _allMembers.where((m) {
      final matchName =
          m['name'].toString().toLowerCase().contains(query);
      final status =
          m['feeStatus']?.toString().toLowerCase() ?? 'unpaid';
      final matchFilter =
          _activeFilter == 'all' || status == _activeFilter;
      return matchName && matchFilter;
    }).toList();
  }

  void _onSearchChanged(String _) => setState(_applyFilter);

  void _onFilterChanged(String filter) => setState(() {
        _activeFilter = filter;
        _applyFilter();
      });

  // ─── Auth ─────────────────────────────────────────────────────────────────

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

  // ─── Helpers ──────────────────────────────────────────────────────────────


  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        backgroundColor: const Color(0xFF1A1A1A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─── Write-gated action helper ────────────────────────────────────────────

  void _requireFullAccess(VoidCallback action) {
    if (!_isFull) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isLocked
                ? 'Gym is locked. Contact support.'
                : 'Platform access is disabled. View-only mode.',
          ),
          backgroundColor: Colors.orangeAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    action();
  }

  // ─── Sheet triggers ───────────────────────────────────────────────────────

  void _showAttendanceQR() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AttendanceQrSheet(
        gymId: _gymId!,
        onCopyToken: (token) => _copyToClipboard(token, 'Token'),
      ),
    );
  }

  void _showRegistrationQR() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RegistrationQrSheet(
        gymCode: _gymCode ?? 'NO-CODE',
        onCopyCode: () => _copyToClipboard(_gymCode ?? '', 'Gym code'),
      ),
    );
  }

  void _showActionMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ActionMenuSheet(
        gymName: _gymName ?? 'My Gym',
        isLoggingOut: _isLoggingOut,
        // Registration QR is always viewable
        onRegistrationQrTap: _showRegistrationQR,
        // Staff manager blocked in read-only / locked
        onStaffManagerTap: () => _requireFullAccess(
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ManageStaffScreen(
                  gymId: _gymId!, allMembers: _allMembers),
            ),
          ),
        ),
        onLogoutTap: _logout,
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Single loading gate
    if (_loadingStats || _gymStatus == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              skeletonBox(width: 80, height: 11),
              const SizedBox(height: 5),
              skeletonBox(width: 140, height: 16),
            ],
          ),
        ),
        body: const GymOwnerSkeleton(),
      );
    }

    // Full lockout screen — status != active
    if (_isLocked) {
      return _LockedScreen(
        gymName: _gymName ?? 'Gym',
        message: _gymStatus!.message,
        onLogout: _logout,
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: (){FocusScope.of(context).unfocus();},
        child:       Column(
        children: [
          // Read-only banner
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
                      'Digital platform is disabled — view-only mode.',
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
              onRefresh: _fetchGymStats,
              color: Colors.yellowAccent,
              backgroundColor: Colors.grey[900],
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AttendanceCard(
                      count: _todayAttendanceCount,
                      // Scan QR blocked in read-only
                      onScanTap: () =>
                          _requireFullAccess(_showAttendanceQR),
                    ),
                    const SizedBox(height: 16),
                    StatsStrip(
                      totalRevenue: _totalRevenue,
                      onlineRevenue: _onlineRevenue,
                      cashRevenue: _cashRevenue,
                      totalMembers: _totalMembers,
                    ),
                    if (_pendingOnlineCount > 0) ...[
                      const SizedBox(height: 12),
                      PendingBanner(
                        count: _pendingOnlineCount,
                        onTap: () => _requireFullAccess(
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PendingPaymentsScreen(gymId: _gymId!),
                            ),
                          ).then((_) => _fetchGymStats()),
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    MemberListSection(
                      members: _filteredMembers,
                      gymId: _gymId!,
                      isLoading: _loadingMembers,
                      activeFilter: _activeFilter,
                      searchController: _searchController,
                      // Search still works in read-only (view only)
                      onSearchChanged: _onSearchChanged,
                      onFilterChanged: _onFilterChanged,
                      totalCount: _totalMembers,
                      hasMore: _hasMoreMembers,
                      isLoadingMore: _loadingMoreMembers,
                      onLoadMore: () => _fetchMembers(),
                      // Pass read-only so MemberTile disables detail nav
                      isReadOnly: _isReadOnly,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    
      )
      
      
      
      
      

    
    
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      title: Text(
        (_gymName ?? 'Guest').toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded,
              color: Colors.white70),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white),
          onPressed: _showActionMenu,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
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
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.redAccent),
            ),
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
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: Colors.redAccent,
                  size: 40,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Access Restricted',
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
                  color: Colors.white54,
                  fontSize: 14,
                  height: 1.6,
                ),
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
                child: const Text(
                  'Log Out',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}