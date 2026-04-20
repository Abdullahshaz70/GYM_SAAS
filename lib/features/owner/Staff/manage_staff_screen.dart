import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/skeleton_loaders.dart';

class ManageStaffScreen extends StatefulWidget {
  final String gymId;
  final List<Map<String, dynamic>> allMembers;

  const ManageStaffScreen({
    super.key,
    required this.gymId,
    required this.allMembers,
  });

  @override
  State<ManageStaffScreen> createState() => _ManageStaffScreenState();
}

class _ManageStaffScreenState extends State<ManageStaffScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _staffMembers = [];
  List<Map<String, dynamic>> _regularMembers = [];
  String? _updatingId;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() => _isLoading = true);
    try {
      final firestore = FirebaseFirestore.instance;

      final staffSnap = await firestore
          .collection('users')
          .where('gymId', isEqualTo: widget.gymId)
          .where('role', isEqualTo: 'staff')
          .get();

      final staff = <Map<String, dynamic>>[];
      for (final doc in staffSnap.docs) {
        final memberDoc = await firestore
            .collection('gyms')
            .doc(widget.gymId)
            .collection('members')
            .doc(doc.id)
            .get();

        staff.add({
          'uid': doc.id,
          'name': doc.data()['name'] ?? 'Unknown',
          'plan': memberDoc.data()?['plan'] ?? 'Member',
          'feeStatus': memberDoc.data()?['feeStatus'] ?? 'unpaid',
          'permissions': doc.data()['permissions'] as Map<String, dynamic>? ??
              {'canMarkAttendance': true, 'canCollectFees': true},
        });
      }

      setState(() {
        _staffMembers = staff;
        _regularMembers = widget.allMembers
            .where((m) => m['isDeleted'] != true)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _promoteToStaff(Map<String, dynamic> member) async {
    final confirmed = await _confirmDialog(
      title: "Promote to Staff?",
      body: "${member['name']} will be able to mark attendance and record fee payments.",
      confirmLabel: "PROMOTE",
      confirmColor: Colors.yellowAccent,
    );
    if (!confirmed) return;

    setState(() => _updatingId = member['uid']);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(member['uid'])
          .update({
        'role': 'staff',
        'permissions': {'canMarkAttendance': true, 'canCollectFees': true},
      });

      setState(() {
        _regularMembers.removeWhere((m) => m['uid'] == member['uid']);
        _staffMembers.add(member);
      });
      _showSnack("${member['name']} promoted to staff ✅", Colors.yellowAccent);
    } catch (e) {
      _showSnack("Error: $e", Colors.redAccent);
    } finally {
      setState(() => _updatingId = null);
    }
  }

  Future<void> _demoteToMember(Map<String, dynamic> member) async {
    final confirmed = await _confirmDialog(
      title: "Remove Staff Role?",
      body: "${member['name']} will be reverted to a regular member.",
      confirmLabel: "REMOVE",
      confirmColor: Colors.redAccent,
    );
    if (!confirmed) return;

    setState(() => _updatingId = member['uid']);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(member['uid'])
          .update({'role': 'member'});

      setState(() {
        _staffMembers.removeWhere((m) => m['uid'] == member['uid']);
        _regularMembers.add(member);
      });
      _showSnack("${member['name']} reverted to member", Colors.orange);
    } catch (e) {
      _showSnack("Error: $e", Colors.redAccent);
    } finally {
      setState(() => _updatingId = null);
    }
  }

  Future<void> _editPermissions(Map<String, dynamic> member) async {
    final currentPerms = Map<String, dynamic>.from(
      member['permissions'] as Map<String, dynamic>? ??
          {'canMarkAttendance': true, 'canCollectFees': true},
    );

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => _PermissionsSheet(
        staffName: member['name'] as String,
        initialPerms: currentPerms,
      ),
    );

    if (result == null || !mounted) return;

    setState(() => _updatingId = member['uid'] as String);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(member['uid'] as String)
          .update({'permissions': result});

      setState(() {
        final idx = _staffMembers.indexWhere((m) => m['uid'] == member['uid']);
        if (idx != -1) {
          _staffMembers[idx] = Map<String, dynamic>.from(_staffMembers[idx])
            ..['permissions'] = result;
        }
      });
      _showSnack('Permissions updated for ${member['name']}', Colors.yellowAccent);
    } catch (e) {
      _showSnack('Error: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _updatingId = null);
    }
  }

  Future<bool> _confirmDialog({
    required String title,
    required String body,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.grey[900],
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Text(title,
                style: const TextStyle(color: Colors.white)),
            content: Text(body,
                style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("CANCEL",
                      style: TextStyle(color: Colors.white38))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: confirmColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                onPressed: () => Navigator.pop(context, true),
                child: Text(confirmLabel,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold)),
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
        behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text("MANAGE STAFF",
            style:
                TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const MemberListSkeleton()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(
                    "CURRENT STAFF",
                    "${_staffMembers.length} members",
                    Colors.yellowAccent,
                    Icons.badge_rounded,
                  ),
                  const SizedBox(height: 12),
                  if (_staffMembers.isEmpty)
                    _emptyHint("No staff members yet.\nPromote a member below.")
                  else
                    ..._staffMembers.map((m) => _staffTile(
                          member: m,
                          isStaff: true,
                          onAction: () => _demoteToMember(m),
                        )),

                  const SizedBox(height: 28),

                  _sectionHeader(
                    "MEMBERS",
                    "Tap to promote",
                    Colors.white38,
                    Icons.people_alt_rounded,
                  ),
                  const SizedBox(height: 12),
                  if (_regularMembers.isEmpty)
                    _emptyHint("All members are staff.")
                  else
                    ..._regularMembers.map((m) => _staffTile(
                          member: m,
                          isStaff: false,
                          onAction: () => _promoteToStaff(m),
                        )),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _sectionHeader(
      String title, String sub, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2)),
        const Spacer(),
        Text(sub,
            style:
                const TextStyle(color: Colors.white38, fontSize: 11)),
      ],
    );
  }

  Widget _staffTile({
    required Map<String, dynamic> member,
    required bool isStaff,
    required VoidCallback onAction,
  }) {
    final bool isThisOneUpdating = _updatingId == member['uid'];
    final perms = isStaff
        ? (member['permissions'] as Map<String, dynamic>? ??
            {'canMarkAttendance': true, 'canCollectFees': true})
        : <String, dynamic>{};

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isStaff
            ? Colors.yellowAccent.withOpacity(0.06)
            : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isStaff
              ? Colors.yellowAccent.withOpacity(0.2)
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
                backgroundColor: Colors.yellowAccent.withOpacity(0.15),
                child: Text(
                  (member['name'] as String)[0].toUpperCase(),
                  style: const TextStyle(
                      color: Colors.yellowAccent,
                      fontWeight: FontWeight.bold),
                ),
              ),
              if (isStaff)
                Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                      color: Colors.yellowAccent,
                      shape: BoxShape.circle),
                  child: const Icon(Icons.star, color: Colors.black, size: 9),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member['name'],
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                Text(
                  isStaff ? 'Staff Member' : member['plan'] ?? 'Member',
                  style: TextStyle(
                      color: isStaff ? Colors.yellowAccent : Colors.white38,
                      fontSize: 11),
                ),
                if (isStaff) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    _permBadge('ATTENDANCE', perms['canMarkAttendance'] == true),
                    const SizedBox(width: 4),
                    _permBadge('FEES', perms['canCollectFees'] == true),
                  ]),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isThisOneUpdating)
            const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.yellowAccent))
          else if (isStaff)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _updatingId != null ? null : () => _editPermissions(member),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.yellowAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: Colors.yellowAccent.withOpacity(0.2)),
                    ),
                    child: const Text('PERMISSIONS',
                        style: TextStyle(
                            color: Colors.yellowAccent,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.4)),
                  ),
                ),
                const SizedBox(height: 5),
                GestureDetector(
                  onTap: _updatingId != null ? null : onAction,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Text('REMOVE',
                        style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5)),
                  ),
                ),
              ],
            )
          else
            GestureDetector(
              onTap: _updatingId != null ? null : onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.yellowAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('PROMOTE',
                    style: TextStyle(
                        color: Colors.yellowAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _permBadge(String label, bool enabled) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: enabled
              ? Colors.yellowAccent.withOpacity(0.1)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
              color: enabled
                  ? Colors.yellowAccent.withOpacity(0.25)
                  : Colors.white12),
        ),
        child: Text(label,
            style: TextStyle(
                color: enabled ? Colors.yellowAccent : Colors.white24,
                fontSize: 8,
                fontWeight: FontWeight.bold)),
      );

  Widget _emptyHint(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(text,
          textAlign: TextAlign.center,
          style:
              const TextStyle(color: Colors.white24, fontSize: 13)),
    );
  }
}

// ─── Permissions Bottom Sheet ─────────────────────────────────────────────────
class _PermissionsSheet extends StatefulWidget {
  final String staffName;
  final Map<String, dynamic> initialPerms;

  const _PermissionsSheet({
    required this.staffName,
    required this.initialPerms,
  });

  @override
  State<_PermissionsSheet> createState() => _PermissionsSheetState();
}

class _PermissionsSheetState extends State<_PermissionsSheet> {
  late bool _canAttend;
  late bool _canFees;

  @override
  void initState() {
    super.initState();
    _canAttend = widget.initialPerms['canMarkAttendance'] as bool? ?? true;
    _canFees   = widget.initialPerms['canCollectFees']   as bool? ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────────────────────────
                Row(children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.yellowAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.manage_accounts_rounded,
                        color: Colors.yellowAccent, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Staff Permissions',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800)),
                      Text(widget.staffName,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ]),

                const SizedBox(height: 8),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.info_outline_rounded,
                        color: Colors.white24, size: 15),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Toggle which actions this staff member can perform in the app.',
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ),
                  ]),
                ),

                // ── Permission cards ───────────────────────────────────────
                _PermCard(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Mark Attendance',
                  description:
                      'Scan QR codes and manually check in members during sessions.',
                  value: _canAttend,
                  onChanged: (v) => setState(() => _canAttend = v),
                ),
                const SizedBox(height: 12),
                _PermCard(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Collect Fees',
                  description:
                      'Record cash and digital payments on behalf of members.',
                  value: _canFees,
                  onChanged: (v) => setState(() => _canFees = v),
                ),

                const SizedBox(height: 28),

                // ── Save button ────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellowAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context, {
                      'canMarkAttendance': _canAttend,
                      'canCollectFees': _canFees,
                    }),
                    child: const Text('SAVE PERMISSIONS',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            letterSpacing: 0.8)),
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

class _PermCard extends StatelessWidget {
  const _PermCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: value
            ? Colors.yellowAccent.withOpacity(0.06)
            : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value
              ? Colors.yellowAccent.withOpacity(0.3)
              : Colors.white.withOpacity(0.07),
          width: value ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon block
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: value
                  ? Colors.yellowAccent.withOpacity(0.15)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: value ? Colors.yellowAccent : Colors.white24,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: value ? Colors.white : Colors.white60,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: value
                        ? Colors.white38
                        : Colors.white.withOpacity(0.2),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Switch
          Transform.scale(
            scale: 0.9,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.yellowAccent,
              activeTrackColor: Colors.yellowAccent.withOpacity(0.25),
              inactiveThumbColor: Colors.white24,
              inactiveTrackColor: Colors.white.withOpacity(0.06),
            ),
          ),
        ],
      ),
    );
  }
}