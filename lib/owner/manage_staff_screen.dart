import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../user/screens/skeleton_loaders.dart';

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
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
  setState(() => _isLoading = true);
  try {
    final firestore = FirebaseFirestore.instance;

    // 1. Get staff from users collection (independent query)
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
      });
    }

    // 2. Regular members = allMembers (already filtered — no staff here)
    setState(() {
      _staffMembers = staff;
      _regularMembers = List.from(widget.allMembers); // already clean
      _isLoading = false;
    });
  } catch (e) {
    setState(() => _isLoading = false);
  }
}

  // Future<void> _loadStaff() async {
  //   setState(() => _isLoading = true);
  //   try {
  //     // Get all users in this gym with role = staff
  //     final staffSnap = await FirebaseFirestore.instance
  //         .collection('users')
  //         .where('gymId', isEqualTo: widget.gymId)
  //         .where('role', isEqualTo: 'staff')
  //         .get();

  //     final staffUids =
  //         staffSnap.docs.map((d) => d.id).toSet();

  //     final staff = <Map<String, dynamic>>[];
  //     final regular = <Map<String, dynamic>>[];

  //     for (final m in widget.allMembers) {
  //       if (staffUids.contains(m['uid'])) {
  //         staff.add(m);
  //       } else {
  //         regular.add(m);
  //       }
  //     }

  //     setState(() {
  //       _staffMembers = staff;
  //       _regularMembers = regular;
  //       _isLoading = false;
  //     });
  //   } catch (e) {
  //     setState(() => _isLoading = false);
  //   }
  // }

  Future<void> _promoteToStaff(Map<String, dynamic> member) async {
    final confirmed = await _confirmDialog(
      title: "Promote to Staff?",
      body:
          "${member['name']} will be able to mark attendance and record fee payments.",
      confirmLabel: "PROMOTE",
      confirmColor: Colors.blueAccent,
    );
    if (!confirmed) return;

    setState(() => _isUpdating = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(member['uid'])
          .update({'role': 'staff'});

      setState(() {
        _regularMembers.remove(member);
        _staffMembers.add(member);
      });
      _showSnack("${member['name']} promoted to staff ✅",
          Colors.blueAccent);
    } catch (e) {
      _showSnack("Error: $e", Colors.redAccent);
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _demoteToMember(Map<String, dynamic> member) async {
    final confirmed = await _confirmDialog(
      title: "Remove Staff Role?",
      body:
          "${member['name']} will be reverted to a regular member.",
      confirmLabel: "REMOVE",
      confirmColor: Colors.redAccent,
    );
    if (!confirmed) return;

    setState(() => _isUpdating = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(member['uid'])
          .update({'role': 'member'});

      setState(() {
        _staffMembers.remove(member);
        _regularMembers.add(member);
      });
      _showSnack(
          "${member['name']} reverted to member", Colors.orange);
    } catch (e) {
      _showSnack("Error: $e", Colors.redAccent);
    } finally {
      setState(() => _isUpdating = false);
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
                    foregroundColor: Colors.white,
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
                  // ── Current Staff ──────────────────────────
                  _sectionHeader(
                    "CURRENT STAFF",
                    "${_staffMembers.length} members",
                    Colors.blueAccent,
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

                  // ── Regular Members ────────────────────────
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isStaff
            ? Colors.blueAccent.withOpacity(0.06)
            : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isStaff
              ? Colors.blueAccent.withOpacity(0.2)
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
                backgroundColor: isStaff
                    ? Colors.blueAccent.withOpacity(0.15)
                    : Colors.yellowAccent.withOpacity(0.1),
                child: Text(
                  (member['name'] as String)[0].toUpperCase(),
                  style: TextStyle(
                      color: isStaff
                          ? Colors.blueAccent
                          : Colors.yellowAccent,
                      fontWeight: FontWeight.bold),
                ),
              ),
              if (isStaff)
                Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle),
                  child: const Icon(Icons.star,
                      color: Colors.white, size: 9),
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
                  isStaff ? "Staff Member" : member['plan'] ?? 'Member',
                  style: TextStyle(
                      color: isStaff
                          ? Colors.blueAccent
                          : Colors.white38,
                      fontSize: 11),
                ),
              ],
            ),
          ),
          _isUpdating
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.blueAccent))
              : GestureDetector(
                  onTap: onAction,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isStaff
                          ? Colors.redAccent.withOpacity(0.1)
                          : Colors.blueAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isStaff ? "REMOVE" : "PROMOTE",
                      style: TextStyle(
                          color: isStaff
                              ? Colors.redAccent
                              : Colors.blueAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

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