import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

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

class _StaffMarkAttendanceState extends State<StaffMarkAttendance>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _filtered = [];
  final Set<String> _processingUids = {};
  final Set<String> _checkedInTodayUids = {};
  bool _isLoadingCheckins = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    _loadTodayCheckins();
  }

  Future<void> _loadTodayCheckins() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    try {
      final snap = await FirebaseFirestore.instance
          .collection('gyms')
          .doc(widget.gymId)
          .collection('attendance')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .where('timestamp', isLessThan: Timestamp.fromDate(todayEnd))
          .get();
      final uids = snap.docs.map((d) => d['memberId'] as String).toSet();
      setState(() {
        _checkedInTodayUids.addAll(uids);
        _isLoadingCheckins = false;
      });
    } catch (_) {
      setState(() => _isLoadingCheckins = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Mark attendance ──────────────────────────────────────────────────
  Future<void> _doMarkAttendance(Map<String, dynamic> member) async {
    final uid = member['uid'] as String;
    if (_checkedInTodayUids.contains(uid)) {
      _showSnack('${member['name']} already checked in today', Colors.orange);
      return;
    }
    final confirmed = await _confirmDialog(member['name']);
    if (!confirmed) return;

    setState(() => _processingUids.add(uid));
    final now = DateTime.now();
    try {
      await FirebaseFirestore.instance
          .collection('gyms')
          .doc(widget.gymId)
          .collection('attendance')
          .add({
        'memberId': uid,
        'timestamp': FieldValue.serverTimestamp(),
        'markedBy': 'staff',
        'staffName': widget.staffName,
        'status': 'present',
        'date':
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      });
      setState(() => _checkedInTodayUids.add(uid));
      _showSnack('✅ ${member['name']} checked in', Colors.green);
    } catch (e) {
      _showSnack('Error: $e', Colors.redAccent);
    } finally {
      setState(() => _processingUids.remove(uid));
    }
  }

  Future<bool> _confirmDialog(String memberName) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text('Confirm Check-in',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(memberName,
                    style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, dd MMM yyyy').format(DateTime.now()),
                  style:
                      const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CANCEL',
                    style: TextStyle(color: Colors.white38)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('CONFIRM',
                    style: TextStyle(fontWeight: FontWeight.bold)),
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
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Build ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('MARK ATTENDANCE',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5)),
            Text(
              DateFormat('EEE, dd MMM yyyy').format(DateTime.now()),
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.greenAccent.withOpacity(0.4),
                      width: 1),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.greenAccent,
                unselectedLabelColor: Colors.white38,
                labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5),
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_2_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('SHOW QR'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('MANUAL'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQRTab(),
          _buildManualTab(),
        ],
      ),
    );
  }

  // ── QR Tab: display the gym attendance QR for members to scan ────────
  Widget _buildQRTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('gyms')
          .doc(widget.gymId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent));
        }

        final data =
            snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final token = data['currentAttendanceQrToken'] ?? '';
        final expiresAt =
            data['attendanceQrExpiresAt'] as Timestamp?;
        final isExpired = expiresAt != null &&
            expiresAt.toDate().isBefore(DateTime.now());

        return SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              // Stats row
              Row(
                children: [
                  _miniStat(
                    label: 'Checked in today',
                    value: '${_checkedInTodayUids.length}',
                    color: Colors.greenAccent,
                    icon: Icons.how_to_reg_rounded,
                  ),
                  const SizedBox(width: 12),
                  _miniStat(
                    label: 'Total members',
                    value: '${widget.members.length}',
                    color: Colors.blueAccent,
                    icon: Icons.group_rounded,
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // QR display card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    vertical: 32, horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isExpired
                        ? Colors.redAccent.withOpacity(0.3)
                        : Colors.greenAccent.withOpacity(0.25),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isExpired
                              ? Icons.warning_amber_rounded
                              : Icons.qr_code_2_rounded,
                          color: isExpired
                              ? Colors.redAccent
                              : Colors.greenAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isExpired
                              ? 'QR CODE EXPIRED'
                              : 'MEMBER CHECK-IN QR',
                          style: TextStyle(
                            color: isExpired
                                ? Colors.redAccent
                                : Colors.greenAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Members scan this with their app to check in',
                      style:
                          TextStyle(color: Colors.white38, fontSize: 12),
                    ),

                    const SizedBox(height: 28),

                    // QR or placeholder
                    if (token.isEmpty || isExpired)
                      Container(
                        width: 230,
                        height: 230,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.refresh_rounded,
                                color: Colors.white38, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              isExpired
                                  ? 'QR expired\nRotates at midnight'
                                  : 'No QR generated yet',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.greenAccent.withOpacity(0.15),
                              blurRadius: 30,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: QrImageView(
                          data: token,
                          version: QrVersions.auto,
                          size: 220,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Colors.black,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.circle,
                            color: Colors.black,
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Token + expiry info
                    if (token.isNotEmpty && !isExpired)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Text('ACTIVE TOKEN',
                                style: TextStyle(
                                    color: Colors.white24,
                                    fontSize: 9,
                                    letterSpacing: 1.2)),
                            const SizedBox(height: 4),
                            SelectableText(
                              token,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.yellowAccent,
                                fontFamily: 'monospace',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (expiresAt != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Auto-rotates at midnight',
                                style: const TextStyle(
                                    color: Colors.white24,
                                    fontSize: 10),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tip card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.blueAccent.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tips_and_updates_rounded,
                        color: Colors.blueAccent, size: 16),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Keep this screen visible. Members open their app and scan this QR to self-check-in. Use the Manual tab to check in someone without a phone.',
                        style: TextStyle(
                            color: Colors.white54, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _miniStat({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        color: color,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                Text(label,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Manual Tab ───────────────────────────────────────────────────────
  Widget _buildManualTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search member by name...',
              hintStyle:
                  const TextStyle(color: Colors.white38, fontSize: 14),
              prefixIcon: const Icon(Icons.search,
                  color: Colors.white38, size: 20),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 12, horizontal: 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.white12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: Colors.greenAccent),
              ),
            ),
          ),
        ),
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.info_outline,
                  color: Colors.white24, size: 12),
              const SizedBox(width: 6),
              Text(
                '${_checkedInTodayUids.length} of ${widget.members.length} checked in today',
                style: const TextStyle(
                    color: Colors.white24, fontSize: 11),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoadingCheckins
              ? const Center(
                  child: CircularProgressIndicator(
                      color: Colors.greenAccent, strokeWidth: 2))
              : _filtered.isEmpty
                  ? const Center(
                      child: Text('No members found',
                          style: TextStyle(color: Colors.white38)))
                  : ListView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) =>
                          _memberTile(_filtered[i]),
                    ),
        ),
      ],
    );
  }

  Widget _memberTile(Map<String, dynamic> m) {
    final uid = m['uid'] as String;
    final bool alreadyIn = _checkedInTodayUids.contains(uid);
    final bool isProcessing = _processingUids.contains(uid);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: alreadyIn
            ? Colors.greenAccent.withOpacity(0.04)
            : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: alreadyIn
              ? Colors.greenAccent.withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: alreadyIn
                    ? Colors.greenAccent.withOpacity(0.15)
                    : Colors.yellowAccent.withOpacity(0.1),
                child: Text(
                  (m['name'] as String)[0].toUpperCase(),
                  style: TextStyle(
                    color: alreadyIn
                        ? Colors.greenAccent
                        : Colors.yellowAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              if (alreadyIn)
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.black, width: 1.5),
                  ),
                  child: const Icon(Icons.check,
                      color: Colors.black, size: 10),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m['name'],
                  style: TextStyle(
                    color:
                        alreadyIn ? Colors.white54 : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alreadyIn
                      ? 'Checked in today'
                      : (m['plan'] ?? 'Member'),
                  style: TextStyle(
                    color: alreadyIn
                        ? Colors.greenAccent
                        : Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (alreadyIn)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('DONE',
                  style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            )
          else if (isProcessing)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.greenAccent),
            )
          else
            GestureDetector(
              onTap: () => _doMarkAttendance(m),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.greenAccent.withOpacity(0.3)),
                ),
                child: const Text('CHECK IN',
                    style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
}