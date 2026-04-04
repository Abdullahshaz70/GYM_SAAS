import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'Member Attendence/attendance_screen.dart';
import 'Member Payment/payment_history_screen.dart';
import 'Membership Details/membership_screen.dart';
import '../../shared/skeleton_loaders.dart';

class MemberDetailScreen extends StatefulWidget {
  final String uid;
  final String gymId;

  const MemberDetailScreen(
      {super.key, required this.uid, required this.gymId});

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  bool _loading = true;

  String name = '';
  String contactNumber = '';
  String plan = '';
  num currentFee = 0;
  String feeStatus = '';
  DateTime? joinedAt;
  DateTime? validUntil;
  List<Map<String, dynamic>> recentPayments = [];

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    if (!mounted) return;
    setState(() => _loading = true);

    final db = FirebaseFirestore.instance;

    try {
      final results = await Future.wait([
        db.collection('users').doc(widget.uid).get(),
        db
            .collection('gyms')
            .doc(widget.gymId)
            .collection('members')
            .doc(widget.uid)
            .get(),
        db
            .collection('gyms')
            .doc(widget.gymId)
            .collection('payments')
            .where('memberId', isEqualTo: widget.uid)
            .orderBy('timestamp', descending: true)
            .limit(3)
            .get(),
      ]);

      if (!mounted) return;

      final userDoc = results[0] as DocumentSnapshot;
      final memberDoc = results[1] as DocumentSnapshot;
      final paymentsSnap = results[2] as QuerySnapshot;

      setState(() {
        name = userDoc.data() != null
            ? (userDoc.data() as Map)['name'] ?? 'Unknown'
            : 'Unknown';
        contactNumber = userDoc.data() != null
            ? (userDoc.data() as Map)['contactNumber'] ?? '--'
            : '--';

        final md = memberDoc.data() as Map<String, dynamic>?;
        plan = md?['plan'] ?? 'free';
        currentFee = md?['currentFee'] ?? 0;
        feeStatus = md?['feeStatus'] ?? 'unpaid';
        joinedAt = (md?['createdAt'] as Timestamp?)?.toDate();
        validUntil = (md?['validUntil'] as Timestamp?)?.toDate();

        recentPayments = paymentsSnap.docs
            .map((d) => d.data() as Map<String, dynamic>)
            .toList();

        _loading = false;
      });
    } catch (e) {
      debugPrint('MemberDetail fetch error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _loading ? const MemberDetailSkeleton() : _buildContent(),
    );
  }

  // ── Main content ─────────────────────────────────────────────────────
  Widget _buildContent() {
    final isPaid = feeStatus.toLowerCase() == 'paid';
    final statusColor = isPaid ? Colors.greenAccent : Colors.redAccent;

    return CustomScrollView(
      slivers: [
        // ── Sticky hero header ───────────────────────────────
        SliverAppBar(
          expandedHeight: 260,
          pinned: true,
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withOpacity(0.4)),
              ),
              child: Text(
                feeStatus.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: _buildHeroHeader(isPaid, statusColor),
          ),
        ),

        // ── Body ─────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: 8),

              // ── Quick stats row ──────────────────────────
              _buildStatsRow(),
              const SizedBox(height: 24),

              // ── Action buttons ───────────────────────────
              _buildActionRow(),
              const SizedBox(height: 28),

              // ── Quick nav cards ──────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _quickNavCard(
                        icon: Icons.calendar_today_rounded,
                        label: "Attendance",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AttendanceScreen(
                                uid: widget.uid, gymId: widget.gymId),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _quickNavCard(
                        icon: Icons.account_balance_wallet_rounded,
                        label: "Payments",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PaymentHistoryScreen(
                                uid: widget.uid, gymId: widget.gymId),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _quickNavCard(
                        icon: Icons.payments_rounded,
                        label: "Record",
                        accent: Colors.greenAccent,
                        onTap: _showRecordPaymentSheet,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Membership details ───────────────────────
              _buildMembershipSection(),
              const SizedBox(height: 28),

              // ── Recent transactions ──────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader("RECENT TRANSACTIONS"),
                    const SizedBox(height: 12),
                    if (recentPayments.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.06)),
                        ),
                        child: Column(
                          children: const [
                            Icon(Icons.receipt_long_rounded,
                                color: Colors.white24, size: 32),
                            SizedBox(height: 8),
                            Text("No transactions yet",
                                style: TextStyle(
                                    color: Colors.white38, fontSize: 12)),
                          ],
                        ),
                      )
                    else
                      ...recentPayments.map((p) => _paymentTile(p)),
                  ],
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ],
    );
  }

  // ── Hero header (SliverAppBar background) ────────────────────────────
  Widget _buildHeroHeader(bool isPaid, Color statusColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      child: Stack(
        children: [
          // Subtle glow behind avatar
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.yellowAccent.withOpacity(0.08),
                      blurRadius: 60,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // Avatar
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.yellowAccent.withOpacity(0.08),
                        border: Border.all(
                            color: Colors.yellowAccent.withOpacity(0.25),
                            width: 2),
                      ),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                              fontSize: 36,
                              color: Colors.yellowAccent,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                          color: Colors.black, shape: BoxShape.circle),
                      child: Icon(
                        isPaid
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: statusColor,
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Name
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),

                // Contact
                if (contactNumber != '--')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.phone_rounded,
                          color: Colors.white38, size: 12),
                      const SizedBox(width: 4),
                      Text(contactNumber,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12)),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats row ────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    final daysLeft = validUntil != null
        ? validUntil!.difference(DateTime.now()).inDays
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              _statCell("PLAN", plan.isEmpty ? '--' : plan),
              _verticalDivider(),
              _statCell("FEE", "Rs $currentFee"),
              _verticalDivider(),
              _statCell(
                "EXPIRES",
                daysLeft == null
                    ? '--'
                    : daysLeft < 0
                        ? 'Expired'
                        : '$daysLeft days',
                valueColor: daysLeft != null && daysLeft <= 5
                    ? Colors.redAccent
                    : daysLeft != null && daysLeft <= 10
                        ? Colors.orangeAccent
                        : Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCell(String label, String value, {Color? valueColor}) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: valueColor ?? Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      color: Colors.white.withOpacity(0.08),
    );
  }

  // ── Action row ───────────────────────────────────────────────────────
  Widget _buildActionRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _actionButton(
              icon: Icons.phone_rounded,
              label: "Call",
              color: Colors.yellowAccent,
              onTap: _makeCall,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _actionButton(
              icon: Icons.chat_rounded,
              label: "WhatsApp",
              color: Colors.greenAccent,
              onTap: _sendWhatsApp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ── Quick nav card ───────────────────────────────────────────────────
  Widget _quickNavCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color accent = Colors.yellowAccent,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: accent, size: 22),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ── Membership section ───────────────────────────────────────────────
  Widget _buildMembershipSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader("MEMBERSHIP DETAILS"),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              children: [
                _membershipRow(
                  icon: Icons.fitness_center_rounded,
                  label: "Plan Type",
                  value: plan,
                  iconColor: Colors.yellowAccent,
                  onTap: () => _navigateToEdit("plan", plan),
                  showDivider: true,
                ),
                _membershipRow(
                  icon: Icons.currency_rupee_rounded,
                  label: "Fees Amount",
                  value: "Rs $currentFee",
                  iconColor: Colors.orangeAccent,
                  onTap: () => _navigateToEdit("fee", currentFee.toString()),
                  showDivider: true,
                ),
                _membershipRow(
                  icon: Icons.calendar_month_rounded,
                  label: "Valid Until",
                  value: validUntil != null
                      ? DateFormat('dd MMM yyyy').format(validUntil!)
                      : "--",
                  iconColor: Colors.yellowAccent,
                  onTap: () =>
                      _navigateToEdit("validity", validUntil.toString()),
                  showDivider: joinedAt != null,
                ),
                if (joinedAt != null)
                  _membershipRow(
                    icon: Icons.person_add_alt_1_rounded,
                    label: "Member Since",
                    value: DateFormat('dd MMM yyyy').format(joinedAt!),
                    iconColor: Colors.white38,
                    onTap: null,
                    showDivider: false,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _membershipRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    required VoidCallback? onTap,
    required bool showDivider,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 18),
                const SizedBox(width: 14),
                Text(label,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 13)),
                const Spacer(),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                if (onTap != null) ...[
                  const SizedBox(width: 10),
                  const Icon(Icons.edit_rounded,
                      color: Colors.white24, size: 12),
                ],
              ],
            ),
          ),
          if (showDivider)
            Divider(
                height: 1,
                color: Colors.white.withOpacity(0.06),
                indent: 48,
                endIndent: 16),
        ],
      ),
    );
  }

  void _navigateToEdit(String fieldType, String currentValue) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MembershipEditScreen(
          uid: widget.uid,
          gymId: widget.gymId,
          fieldType: fieldType,
          currentValue: currentValue,
        ),
      ),
    ).then((_) => _fetchAll());
  }

  // ── Payment tile ─────────────────────────────────────────────────────
  Widget _paymentTile(Map<String, dynamic> p) {
    final amount = p['amount'] ?? 0;
    final method = (p['method'] ?? 'cash').toString().toUpperCase();
    final tilePlan = p['plan'] ?? 'Monthly';
    final markedBy = p['markedBy'] ?? 'owner';
    final ts = p['timestamp'] as Timestamp?;
    final date = ts != null
        ? DateFormat('dd MMM yyyy').format(ts.toDate())
        : '--';

    Color methodColor;
    switch ((p['method'] ?? '').toString().toLowerCase()) {
      case 'easypaisa':
        methodColor = Colors.greenAccent;
        break;
      case 'jazzcash':
        methodColor = Colors.redAccent;
        break;
      default:
        methodColor = Colors.yellowAccent;
    }

    String recordedBy;
    if (markedBy == 'online') {
      recordedBy = 'Online payment';
    } else if (markedBy == 'staff') {
      recordedBy = 'By staff · ${p['staffName'] ?? ''}';
    } else {
      recordedBy = 'By owner';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.done_rounded,
                color: Colors.greenAccent, size: 14),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tilePlan,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(recordedBy,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("Rs $amount",
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              const SizedBox(height: 5),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: methodColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(method,
                        style: TextStyle(
                            color: methodColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5)),
                  ),
                  const SizedBox(width: 6),
                  Text(date,
                      style: const TextStyle(
                          color: Colors.white24, fontSize: 10)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Section header ───────────────────────────────────────────────────
  Widget _sectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.yellowAccent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                color: Colors.yellowAccent,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1)),
      ],
    );
  }

  // ── Record Payment sheet ─────────────────────────────────────────────
  void _showRecordPaymentSheet() {
    String selectedMethod = 'cash';
    final txnController = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
                decoration: const BoxDecoration(
                  color: Color(0xFF111111),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.payments_rounded,
                              color: Colors.greenAccent, size: 18),
                        ),
                        const SizedBox(width: 12),
                        const Text("RECORD PAYMENT",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 1)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Text(
                        "$name  ·  $plan  ·  Rs $currentFee",
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text("PAYMENT METHOD",
                        style: TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _methodChip("cash", "💵 Cash", selectedMethod,
                            (v) => setSheetState(
                                () => selectedMethod = v)),
                        const SizedBox(width: 8),
                        _methodChip(
                            "easypaisa",
                            "🟢 Easypaisa",
                            selectedMethod,
                            (v) => setSheetState(
                                () => selectedMethod = v)),
                        const SizedBox(width: 8),
                        _methodChip(
                            "jazzcash",
                            "🔴 JazzCash",
                            selectedMethod,
                            (v) => setSheetState(
                                () => selectedMethod = v)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: txnController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: selectedMethod == 'cash'
                            ? "Transaction ID (optional)"
                            : "Transaction ID *",
                        labelStyle:
                            const TextStyle(color: Colors.white38),
                        hintText: "e.g. TXN-123456",
                        hintStyle: const TextStyle(
                            color: Colors.white24, fontSize: 12),
                        prefixIcon: const Icon(Icons.tag_rounded,
                            color: Colors.white38, size: 18),
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
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (selectedMethod != 'cash' &&
                                    txnController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text(
                                        "Transaction ID required for online payments"),
                                    backgroundColor: Colors.redAccent,
                                    behavior: SnackBarBehavior.floating,
                                  ));
                                  return;
                                }
                                setSheetState(() => isSaving = true);
                                await _recordPayment(
                                  method: selectedMethod,
                                  txnId: txnController.text.trim(),
                                );
                                if (sheetCtx.mounted) {
                                  Navigator.pop(sheetCtx);
                                }
                              },
                        child: isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.black))
                            : Text(
                                "CONFIRM  ·  Rs $currentFee",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    letterSpacing: 0.5),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _methodChip(String value, String label, String selected,
      ValueChanged<String> onSelect) {
    final bool isSelected = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.greenAccent.withOpacity(0.12)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: isSelected
                    ? Colors.greenAccent.withOpacity(0.5)
                    : Colors.white12),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    color:
                        isSelected ? Colors.greenAccent : Colors.white54,
                    fontSize: 11,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal)),
          ),
        ),
      ),
    );
  }

  // ── Firestore write ──────────────────────────────────────────────────
  Future<void> _recordPayment({
    required String method,
    required String txnId,
  }) async {
    try {
      final now = DateTime.now();
      final nowTs = Timestamp.fromDate(now);

      int months = 1;
      if (plan == '6 Months') months = 6;
      if (plan == 'Yearly') months = 12;

      final newValidUntil = Timestamp.fromDate(
          DateTime(now.year, now.month + months, now.day));

      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      final payRef = db
          .collection('gyms')
          .doc(widget.gymId)
          .collection('payments')
          .doc();
      batch.set(payRef, {
        'memberId': widget.uid,
        'amount': currentFee,
        'method': method,
        'verified': true,
        'timestamp': nowTs,
        'transactionId': txnId.isEmpty
            ? 'CASH-${now.millisecondsSinceEpoch}'
            : txnId,
        'plan': plan,
        'validUntil': newValidUntil,
        'createdAt': nowTs,
        'status': 'completed',
        'updatedAt': nowTs,
        'markedBy': 'owner',
      });

      final memberRef = db
          .collection('gyms')
          .doc(widget.gymId)
          .collection('members')
          .doc(widget.uid);
      batch.update(memberRef, {
        'feeStatus': 'paid',
        'validUntil': newValidUntil,
        'lastPaidAt': nowTs,
      });

      await batch.commit();
      await _fetchAll();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              "✅ Rs $currentFee recorded via ${method.toUpperCase()}"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  // ── Contact helpers ──────────────────────────────────────────────────
  Future<void> _makeCall() async {
    if (contactNumber == '--' || contactNumber.isEmpty) return;
    final uri = Uri.parse("tel:$contactNumber");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _sendWhatsApp() async {
    if (contactNumber == '--' || contactNumber.isEmpty) return;
    final clean = contactNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse("https://wa.me/$clean");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}