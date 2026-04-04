// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class StaffMarkFees extends StatefulWidget {
//   final String gymId;
//   final String staffName;
//   final List<Map<String, dynamic>> members;

//   const StaffMarkFees({
//     super.key,
//     required this.gymId,
//     required this.staffName,
//     required this.members,
//   });

//   @override
//   State<StaffMarkFees> createState() => _StaffMarkFeesState();
// }

// class _StaffMarkFeesState extends State<StaffMarkFees> {
//   final TextEditingController _searchCtrl = TextEditingController();

//   // FIX 1: Deep copy — never mutate the parent widget's list
//   late List<Map<String, dynamic>> _allMembers;
//   List<Map<String, dynamic>> _filtered = [];

//   // FIX 2: Per-member processing set — each row has its own loading state
//   final Set<String> _processingUids = {};

//   @override
//   void initState() {
//     super.initState();
//     _allMembers =
//         widget.members.map((m) => Map<String, dynamic>.from(m)).toList();

//     // Default: show only unpaid
//     _filtered = _allMembers
//         .where((m) => m['feeStatus']?.toString().toLowerCase() != 'paid')
//         .toList();

//     _searchCtrl.addListener(_applyFilter);
//   }

//   void _applyFilter() {
//     final q = _searchCtrl.text.toLowerCase();
//     setState(() {
//       if (q.isEmpty) {
//         _filtered = _allMembers
//             .where((m) => m['feeStatus']?.toString().toLowerCase() != 'paid')
//             .toList();
//       } else {
//         _filtered = _allMembers
//             .where((m) => (m['name'] as String).toLowerCase().contains(q))
//             .toList();
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _searchCtrl.removeListener(_applyFilter);
//     _searchCtrl.dispose();
//     super.dispose();
//   }

//   Future<void> _markFeePaid(Map<String, dynamic> member) async {
//     final confirmed = await _confirmDialog(member);
//     if (!confirmed) return;

//     final uid = member['uid'] as String;
//     setState(() => _processingUids.add(uid));

//     try {
//       final now = DateTime.now();

//       // FIX 3: Single Timestamp.fromDate(now) for ALL fields.
//       // Using multiple FieldValue.serverTimestamp() inside a single
//       // batch.set() document causes a Firestore write error.
//       final nowTs = Timestamp.fromDate(now);

//       final fee = (member['currentFee'] as num).toDouble();
//       final plan = member['plan'] ?? 'Monthly';

//       int months = 1;
//       if (plan == '6 Months') months = 6;
//       if (plan == 'Yearly') months = 12;
//       final newValidUntil =
//           Timestamp.fromDate(DateTime(now.year, now.month + months, now.day));

//       final db = FirebaseFirestore.instance;
//       final batch = db.batch();

//       // 1. gyms/{gymId}/payments/{auto}
//       final payRef =
//           db.collection('gyms').doc(widget.gymId).collection('payments').doc();
//       batch.set(payRef, {
//         'memberId': uid,
//         'amount': fee,
//         'method': 'cash',
//         'verified': true,
//         'timestamp': nowTs,
//         'transactionId': 'CASH-${now.millisecondsSinceEpoch}',
//         'plan': plan,
//         'validUntil': newValidUntil,
//         'createdAt': nowTs,
//         'status': 'completed',
//         'updatedAt': nowTs,
//         'markedBy': 'staff',
//         'staffName': widget.staffName,
//       });

//       // 2. gyms/{gymId}/members/{uid}
//       final memberRef = db
//           .collection('gyms')
//           .doc(widget.gymId)
//           .collection('members')
//           .doc(uid);
//       batch.update(memberRef, {
//         'feeStatus': 'paid',
//         'validUntil': newValidUntil,
//         'lastPaidAt': nowTs,
//       });

//       await batch.commit();

//       // Update local deep copy then re-apply filter
//       setState(() {
//         final idx = _allMembers.indexWhere((m) => m['uid'] == uid);
//         if (idx != -1) _allMembers[idx]['feeStatus'] = 'paid';
//         _applyFilter();
//       });

//       _showSnack(
//         "✅ Rs ${fee.toStringAsFixed(0)} recorded for ${member['name']}",
//         Colors.green,
//       );
//     } catch (e) {
//       _showSnack("Error recording payment: $e", Colors.redAccent);
//     } finally {
//       setState(() => _processingUids.remove(uid));
//     }
//   }

//   Future<bool> _confirmDialog(Map<String, dynamic> member) async {
//     final fee = member['currentFee'] ?? 0;
//     final plan = member['plan'] ?? 'Monthly';

//     return await showDialog<bool>(
//           context: context,
//           builder: (_) => AlertDialog(
//             backgroundColor: Colors.grey[900],
//             shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16)),
//             title: const Text("Confirm Cash Payment",
//                 style: TextStyle(color: Colors.white)),
//             content: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _confirmRow("Member", member['name']),
//                 _confirmRow("Plan", plan),
//                 _confirmRow("Amount", "Rs $fee"),
//                 _confirmRow("Method", "Cash"),
//                 _confirmRow("Recorded by", widget.staffName),
//               ],
//             ),
//             actions: [
//               TextButton(
//                   onPressed: () => Navigator.pop(context, false),
//                   child: const Text("CANCEL",
//                       style: TextStyle(color: Colors.white38))),
//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.orangeAccent,
//                     foregroundColor: Colors.black,
//                     shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8))),
//                 onPressed: () => Navigator.pop(context, true),
//                 child: const Text("CONFIRM PAYMENT",
//                     style: TextStyle(fontWeight: FontWeight.bold)),
//               ),
//             ],
//           ),
//         ) ??
//         false;
//   }

//   Widget _confirmRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 5),
//       child: Row(
//         children: [
//           Text("$label: ",
//               style: const TextStyle(color: Colors.white54, fontSize: 13)),
//           Expanded(
//             child: Text(value,
//                 style: const TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 13)),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showSnack(String msg, Color color) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//         content: Text(msg),
//         backgroundColor: color,
//         behavior: SnackBarBehavior.floating));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         elevation: 0,
//         title: const Text("MARK FEES PAID",
//             style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new, size: 20),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
//             child: TextField(
//               controller: _searchCtrl,
//               style: const TextStyle(color: Colors.white),
//               decoration: InputDecoration(
//                 hintText: "Search member...",
//                 hintStyle: const TextStyle(color: Colors.white38),
//                 prefixIcon:
//                     const Icon(Icons.search, color: Colors.orangeAccent),
//                 filled: true,
//                 fillColor: Colors.white.withOpacity(0.05),
//                 enabledBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   borderSide: const BorderSide(color: Colors.white24),
//                 ),
//                 focusedBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   borderSide: const BorderSide(color: Colors.orangeAccent),
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20),
//             child: Row(
//               children: [
//                 const Icon(Icons.info_outline,
//                     color: Colors.white24, size: 13),
//                 const SizedBox(width: 6),
//                 Text(
//                   _searchCtrl.text.isEmpty
//                       ? "Showing unpaid members · Search to see all"
//                       : "Showing all members matching search",
//                   style:
//                       const TextStyle(color: Colors.white24, fontSize: 11),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 10),
//           Expanded(
//             child: _filtered.isEmpty
//                 ? Center(
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: const [
//                         Icon(Icons.check_circle_outline,
//                             color: Colors.greenAccent, size: 48),
//                         SizedBox(height: 12),
//                         Text("All members are paid up!",
//                             style: TextStyle(
//                                 color: Colors.white54, fontSize: 14)),
//                       ],
//                     ),
//                   )
//                 : ListView.builder(
//                     padding: const EdgeInsets.symmetric(horizontal: 20),
//                     itemCount: _filtered.length,
//                     itemBuilder: (_, i) => _memberRow(_filtered[i]),
//                   ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _memberRow(Map<String, dynamic> m) {
//     final uid = m['uid'] as String;
//     final bool isPaid = m['feeStatus']?.toString().toLowerCase() == 'paid';
//     final fee = m['currentFee'] ?? 0;
//     final bool isThisProcessing = _processingUids.contains(uid);

//     return Container(
//       margin: const EdgeInsets.only(bottom: 10),
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.04),
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(
//             color: isPaid
//                 ? Colors.greenAccent.withOpacity(0.1)
//                 : Colors.white.withOpacity(0.05)),
//       ),
//       child: Row(
//         children: [
//           CircleAvatar(
//             radius: 20,
//             backgroundColor: isPaid
//                 ? Colors.greenAccent.withOpacity(0.1)
//                 : Colors.orangeAccent.withOpacity(0.1),
//             child: Text(
//               (m['name'] as String)[0].toUpperCase(),
//               style: TextStyle(
//                   color: isPaid ? Colors.greenAccent : Colors.orangeAccent,
//                   fontWeight: FontWeight.bold),
//             ),
//           ),
//           const SizedBox(width: 14),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(m['name'],
//                     style: const TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.w600,
//                         fontSize: 15)),
//                 Text("Rs $fee · ${m['plan'] ?? 'Monthly'}",
//                     style: const TextStyle(
//                         color: Colors.white38, fontSize: 11)),
//               ],
//             ),
//           ),
//           const SizedBox(width: 10),
//           if (isPaid)
//             Container(
//               padding:
//                   const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//               decoration: BoxDecoration(
//                 color: Colors.greenAccent.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: const Text("PAID",
//                   style: TextStyle(
//                       color: Colors.greenAccent,
//                       fontSize: 10,
//                       fontWeight: FontWeight.bold)),
//             )
//           else if (isThisProcessing)
//             const SizedBox(
//               width: 24,
//               height: 24,
//               child: CircularProgressIndicator(
//                   strokeWidth: 2, color: Colors.orangeAccent),
//             )
//           else
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.orangeAccent.withOpacity(0.15),
//                 foregroundColor: Colors.orangeAccent,
//                 elevation: 0,
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10)),
//                 padding: const EdgeInsets.symmetric(
//                     horizontal: 12, vertical: 8),
//               ),
//               onPressed: () => _markFeePaid(m),
//               child: const Text("MARK PAID",
//                   style:
//                       TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
//             ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StaffMarkFees extends StatefulWidget {
  final String gymId;
  final String staffName;
  final List<Map<String, dynamic>> members;

  const StaffMarkFees({
    super.key,
    required this.gymId,
    required this.staffName,
    required this.members,
  });

  @override
  State<StaffMarkFees> createState() => _StaffMarkFeesState();
}

class _StaffMarkFeesState extends State<StaffMarkFees> {
  final TextEditingController _searchCtrl = TextEditingController();

  late List<Map<String, dynamic>> _allMembers;
  List<Map<String, dynamic>> _filtered = [];
  final Set<String> _processingUids = {};

  @override
  void initState() {
    super.initState();
    _allMembers =
        widget.members.map((m) => Map<String, dynamic>.from(m)).toList();
    _filtered = _allMembers
        .where((m) => m['feeStatus']?.toString().toLowerCase() != 'paid')
        .toList();
    _searchCtrl.addListener(_applyFilter);
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = _allMembers
            .where((m) => m['feeStatus']?.toString().toLowerCase() != 'paid')
            .toList();
      } else {
        _filtered = _allMembers
            .where((m) => (m['name'] as String).toLowerCase().contains(q))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_applyFilter);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _markFeePaid(Map<String, dynamic> member) async {
    final confirmed = await _confirmDialog(member);
    if (!confirmed) return;

    final uid = member['uid'] as String;
    setState(() => _processingUids.add(uid));

    try {
      final now = DateTime.now();
      final nowTs = Timestamp.fromDate(now);
      final fee = (member['currentFee'] as num).toDouble();
      final plan = member['plan'] ?? 'Monthly';

      int months = 1;
      if (plan == '6 Months') months = 6;
      if (plan == 'Yearly') months = 12;
      final newValidUntil =
          Timestamp.fromDate(DateTime(now.year, now.month + months, now.day));

      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      final payRef =
          db.collection('gyms').doc(widget.gymId).collection('payments').doc();
      batch.set(payRef, {
        'memberId': uid,
        'amount': fee,
        'method': 'cash',
        'verified': true,
        'timestamp': nowTs,
        'transactionId': 'CASH-${now.millisecondsSinceEpoch}',
        'plan': plan,
        'validUntil': newValidUntil,
        'createdAt': nowTs,
        'status': 'completed',
        'updatedAt': nowTs,
        'markedBy': 'staff',
        'staffName': widget.staffName,
      });

      final memberRef = db
          .collection('gyms')
          .doc(widget.gymId)
          .collection('members')
          .doc(uid);
      batch.update(memberRef, {
        'feeStatus': 'paid',
        'validUntil': newValidUntil,
        'lastPaidAt': nowTs,
      });

      await batch.commit();

      setState(() {
        final idx = _allMembers.indexWhere((m) => m['uid'] == uid);
        if (idx != -1) _allMembers[idx]['feeStatus'] = 'paid';
        _applyFilter();
      });

      _showSnack(
        "✅ Rs ${fee.toStringAsFixed(0)} recorded for ${member['name']}",
        Colors.greenAccent,
      );
    } catch (e) {
      _showSnack("Error recording payment: $e", Colors.redAccent);
    } finally {
      setState(() => _processingUids.remove(uid));
    }
  }

  Future<bool> _confirmDialog(Map<String, dynamic> member) async {
    final fee = member['currentFee'] ?? 0;
    final plan = member['plan'] ?? 'Monthly';

    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF141414),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withOpacity(0.08))),
            title: const Text("Confirm Cash Payment",
                style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _confirmRow("Member", member['name']),
                _confirmRow("Plan", plan),
                _confirmRow("Amount", "Rs $fee"),
                _confirmRow("Method", "Cash"),
                _confirmRow("Recorded by", widget.staffName),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("CANCEL",
                      style: TextStyle(color: Colors.white38))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellowAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                onPressed: () => Navigator.pop(context, true),
                child: const Text("CONFIRM PAYMENT",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _confirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text("$label: ",
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text("COLLECT FEES",
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 20, color: Colors.white54),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search member...",
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon:
                    const Icon(Icons.search, color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Colors.yellowAccent),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: Colors.white24, size: 13),
                const SizedBox(width: 6),
                Text(
                  _searchCtrl.text.isEmpty
                      ? "Showing unpaid members · Search to see all"
                      : "Showing all members matching search",
                  style:
                      const TextStyle(color: Colors.white24, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline,
                            color: Colors.greenAccent, size: 48),
                        SizedBox(height: 12),
                        Text("All members are paid up!",
                            style: TextStyle(
                                color: Colors.white54, fontSize: 14)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) => _memberRow(_filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _memberRow(Map<String, dynamic> m) {
    final uid = m['uid'] as String;
    final bool isPaid = m['feeStatus']?.toString().toLowerCase() == 'paid';
    final fee = m['currentFee'] ?? 0;
    final bool isThisProcessing = _processingUids.contains(uid);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isPaid
                ? Colors.greenAccent.withOpacity(0.12)
                : Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isPaid
                ? Colors.greenAccent.withOpacity(0.1)
                : Colors.yellowAccent.withOpacity(0.1),
            child: Text(
              (m['name'] as String)[0].toUpperCase(),
              style: TextStyle(
                  color: isPaid ? Colors.greenAccent : Colors.yellowAccent,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m['name'],
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
                Text("Rs $fee · ${m['plan'] ?? 'Monthly'}",
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (isPaid)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text("PAID",
                  style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            )
          else if (isThisProcessing)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.yellowAccent),
            )
          else
            GestureDetector(
              onTap: () => _markFeePaid(m),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.yellowAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.yellowAccent.withOpacity(0.3)),
                ),
                child: const Text("MARK PAID",
                    style: TextStyle(
                        color: Colors.yellowAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
}