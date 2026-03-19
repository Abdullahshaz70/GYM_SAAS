import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../auth/login.dart';
import 'Staff/manage_staff_screen.dart';
import 'widgets/pending_payments_screen.dart';
import '../user/screens/skeleton_loaders.dart';
import 'widgets/action_menu_sheet.dart';
import 'widgets/attendance_card.dart';
import 'widgets/member_list_section.dart';
import 'widgets/pending_banner.dart';
import 'widgets/qr_sheets.dart';
import 'widgets/stats_strip.dart';

class GymOwnerScreen extends StatefulWidget {
  const GymOwnerScreen({super.key});

  @override
  State<GymOwnerScreen> createState() => _GymOwnerScreenState();
}

class _GymOwnerScreenState extends State<GymOwnerScreen> {
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

  final today = DateTime.now();
  final todayKey =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

  // ✅ All 3 fetches run in parallel
  final results = await Future.wait([
    firestore.collection('gyms').doc(_gymId)
        .collection('attendance')
        .where('date', isEqualTo: todayKey)
        .get(),
    firestore.collection('gyms').doc(_gymId)
        .collection('payments')
        .get(),
    firestore.collection('gyms').doc(_gymId)
        .collection('members')
        .get(),
  ]);

  final attendanceSnapshot = results[0];
  final paymentsSnapshot   = results[1];
  final membersSnapshot    = results[2];

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

    // ✅ Fetch all user docs in parallel instead of sequentially
    final futures = snapshot.docs.map((doc) async {
      final uid = doc.id;
      final data = doc.data() as Map<String, dynamic>;

      if ((data['role'] ?? 'member') == 'staff') return null;

      return {
        'uid': uid,
        'name': data['name'] ?? 'Unknown',
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
      final matchName = m['name'].toString().toLowerCase().contains(query);
      final status = m['feeStatus']?.toString().toLowerCase() ?? 'unpaid';
      final matchFilter = _activeFilter == 'all' || status == _activeFilter;
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

    final confirmed = await _showConfirmDialog(
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

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content:
            Text(message, style: const TextStyle(color: Colors.white60)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              confirmLabel,
              style: TextStyle(
                color: isDestructive ? Colors.redAccent : Colors.yellowAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        backgroundColor: const Color(0xFF1A1A1A),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
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
        onRegistrationQrTap: _showRegistrationQR,
        onStaffManagerTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ManageStaffScreen(
                gymId: _gymId!, allMembers: _allMembers),
          ),
        ),
        onLogoutTap: _logout,
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loadingStats) {
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

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _fetchGymStats,
        color: Colors.yellowAccent,
        backgroundColor: Colors.grey[900],
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AttendanceCard(
                count: _todayAttendanceCount,
                onScanTap: _showAttendanceQR,
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
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PendingPaymentsScreen(gymId: _gymId!),
                    ),
                  ).then((_) => _fetchGymStats()),
                ),
              ],
              const SizedBox(height: 28),
            
              MemberListSection(
                members: _filteredMembers,
                gymId: _gymId!,
                isLoading: _loadingMembers,
                activeFilter: _activeFilter,
                searchController: _searchController,
                onSearchChanged: _onSearchChanged,
                onFilterChanged: _onFilterChanged,
                totalCount: _totalMembers,
                hasMore: _hasMoreMembers,                    
                isLoadingMore: _loadingMoreMembers,          
                onLoadMore: () => _fetchMembers(),  
              ),
            
            ],
          ),
        ),
      ),
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