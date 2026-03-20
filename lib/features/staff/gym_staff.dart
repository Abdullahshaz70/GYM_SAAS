// // import 'package:flutter/material.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:intl/intl.dart';

// // import '../../auth/login.dart';
// // import 'staff_mark_attendance.dart';
// // import 'staff_mark_fees.dart';
// // import '../../shared/skeleton_loaders.dart';

// // class GymStaff extends StatefulWidget {
// //   const GymStaff({super.key});

// //   @override
// //   State<GymStaff> createState() => _GymStaffState();
// // }

// // class _GymStaffState extends State<GymStaff> {
// //   final _fs = FirebaseFirestore.instance;
// //   final _auth = FirebaseAuth.instance;

// //   bool _isLoading = true;
// //   String staffName = '';
// //   String gymId = '';
// //   String gymName = '';
// //   int todayAttendance = 0;
// //   int totalMembers = 0;
// //   List<Map<String, dynamic>> members = [];

// //   @override
// //   void initState() {
// //     super.initState();
// //     _loadData();
// //   }

// //   Future<void> _loadData() async {
// //     setState(() => _isLoading = true);
// //     try {
// //       final uid = _auth.currentUser!.uid;

// //       // 1. Get staff user profile
// //       final userDoc = await _fs.collection('users').doc(uid).get();
// //       final data = userDoc.data()!;
// //       staffName = data['name'] ?? 'Staff';
// //       gymId = data['gymId'] ?? '';

// //       if (gymId.isEmpty) {
// //         setState(() => _isLoading = false);
// //         return;
// //       }

// //       // 2. Get gym name
// //       final gymDoc = await _fs.collection('gyms').doc(gymId).get();
// //       gymName = gymDoc.data()?['gymName'] ?? 'Gym';

// //       // 3. Today's attendance count
// //       final today = DateTime.now();
// //       final todayKey =
// //           "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
// //       final attSnap = await _fs
// //           .collection('gyms')
// //           .doc(gymId)
// //           .collection('attendance')
// //           .where('date', isEqualTo: todayKey)
// //           .get();
// //       todayAttendance = attSnap.size;

// //       // 4. Members list
// //       final membersSnap = await _fs
// //           .collection('gyms')
// //           .doc(gymId)
// //           .collection('members')
// //           .get();
// //       totalMembers = membersSnap.size;

// //       final List<Map<String, dynamic>> loaded = [];
// //       for (final doc in membersSnap.docs) {
// //         final mData = doc.data();
// //         final uDoc = await _fs.collection('users').doc(doc.id).get();
// //         loaded.add({
// //           'uid': doc.id,
// //           'name': uDoc.data()?['name'] ?? 'Unknown',
// //           'plan': mData['plan'] ?? 'Monthly',
// //           'feeStatus': mData['feeStatus'] ?? 'unpaid',
// //           'currentFee': mData['currentFee'] ?? 0,
// //           'validUntil': mData['validUntil'],
// //         });
// //       }

// //       setState(() {
// //         members = loaded;
// //         _isLoading = false;
// //       });
// //     } catch (e) {
// //       debugPrint('Staff load error: $e');
// //       setState(() => _isLoading = false);
// //     }
// //   }

// //   Future<void> _logout() async {
// //     await _auth.signOut();
// //     if (mounted) {
// //       Navigator.of(context).pushAndRemoveUntil(
// //         MaterialPageRoute(builder: (_) => const Login()),
// //         (_) => false,
// //       );
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Colors.black,
// //       appBar: AppBar(
// //         backgroundColor: Colors.black,
// //         elevation: 0,
// //         title: _isLoading
// //             ? skeletonBox(width: 160, height: 16)
// //             : Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Text(gymName.toUpperCase(),
// //                       style: const TextStyle(
// //                           color: Colors.yellowAccent,
// //                           fontSize: 13,
// //                           fontWeight: FontWeight.bold,
// //                           letterSpacing: 1.5)),
// //                   Text("STAFF · ${staffName.toUpperCase()}",
// //                       style: const TextStyle(
// //                           color: Colors.white54, fontSize: 11)),
// //                 ],
// //               ),
// //         actions: [
// //           IconButton(
// //             icon: const Icon(Icons.logout, color: Colors.redAccent),
// //             onPressed: _logout,
// //           ),
// //         ],
// //       ),
// //       body: _isLoading
// //           ? const GymStaffSkeleton()
// //           : RefreshIndicator(
// //               onRefresh: _loadData,
// //               color: Colors.yellowAccent,
// //               child: SingleChildScrollView(
// //                 physics: const AlwaysScrollableScrollPhysics(),
// //                 padding: const EdgeInsets.all(20),
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     // ── Stats row ──────────────────────────────
// //                     Row(
// //                       children: [
// //                         _statCard("TODAY'S CHECK-INS",
// //                             "$todayAttendance", Icons.how_to_reg,
// //                             Colors.yellowAccent),
// //                         const SizedBox(width: 15),
// //                         _statCard("TOTAL MEMBERS",
// //                             "$totalMembers", Icons.group,
// //                             Colors.blueAccent),
// //                       ],
// //                     ),
// //                     const SizedBox(height: 20),

// //                     // ── Quick action buttons ───────────────────
// //                     _actionButton(
// //                       icon: Icons.qr_code_scanner,
// //                       label: "MARK ATTENDANCE",
// //                       subtitle: "Scan or search to check in a member",
// //                       color: Colors.greenAccent,
// //                       onTap: () => Navigator.push(
// //                         context,
// //                         MaterialPageRoute(
// //                           builder: (_) => StaffMarkAttendance(
// //                               gymId: gymId,
// //                               staffName: staffName,
// //                               members: members),
// //                         ),
// //                       ).then((_) => _loadData()),
// //                     ),
// //                     const SizedBox(height: 12),
// //                     _actionButton(
// //                       icon: Icons.payments_rounded,
// //                       label: "MARK FEES PAID",
// //                       subtitle: "Record a cash payment for a member",
// //                       color: Colors.orangeAccent,
// //                       onTap: () => Navigator.push(
// //                         context,
// //                         MaterialPageRoute(
// //                           builder: (_) => StaffMarkFees(
// //                               gymId: gymId,
// //                               staffName: staffName,
// //                               members: members),
// //                         ),
// //                       ).then((_) => _loadData()),
// //                     ),
// //                     const SizedBox(height: 30),

// //                     // ── Members list (read-only) ───────────────
// //                     const Text("MEMBERS",
// //                         style: TextStyle(
// //                             color: Colors.yellowAccent,
// //                             fontSize: 12,
// //                             fontWeight: FontWeight.bold,
// //                             letterSpacing: 1.5)),
// //                     const SizedBox(height: 12),
// //                     if (members.isEmpty)
// //                       const Center(
// //                           child: Text("No members yet",
// //                               style:
// //                                   TextStyle(color: Colors.white38)))
// //                     else
// //                       ListView.builder(
// //                         shrinkWrap: true,
// //                         physics: const NeverScrollableScrollPhysics(),
// //                         itemCount: members.length,
// //                         itemBuilder: (_, i) =>
// //                             _memberTile(members[i]),
// //                       ),
// //                     const SizedBox(height: 100),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //     );
// //   }

// //   Widget _statCard(
// //       String label, String value, IconData icon, Color color) {
// //     return Expanded(
// //       child: Container(
// //         padding: const EdgeInsets.all(18),
// //         decoration: BoxDecoration(
// //           color: Colors.white.withOpacity(0.05),
// //           borderRadius: BorderRadius.circular(16),
// //           border: Border.all(color: Colors.white10),
// //         ),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             Icon(icon, color: color, size: 24),
// //             const SizedBox(height: 10),
// //             Text(label,
// //                 style: const TextStyle(
// //                     color: Colors.white54,
// //                     fontSize: 10,
// //                     fontWeight: FontWeight.bold)),
// //             const SizedBox(height: 4),
// //             Text(value,
// //                 style: const TextStyle(
// //                     color: Colors.white,
// //                     fontSize: 24,
// //                     fontWeight: FontWeight.bold)),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _actionButton({
// //     required IconData icon,
// //     required String label,
// //     required String subtitle,
// //     required Color color,
// //     required VoidCallback onTap,
// //   }) {
// //     return GestureDetector(
// //       onTap: onTap,
// //       child: Container(
// //         padding: const EdgeInsets.all(18),
// //         decoration: BoxDecoration(
// //           color: color.withOpacity(0.07),
// //           borderRadius: BorderRadius.circular(18),
// //           border: Border.all(color: color.withOpacity(0.2)),
// //         ),
// //         child: Row(
// //           children: [
// //             Container(
// //               padding: const EdgeInsets.all(12),
// //               decoration: BoxDecoration(
// //                 color: color.withOpacity(0.15),
// //                 shape: BoxShape.circle,
// //               ),
// //               child: Icon(icon, color: color, size: 24),
// //             ),
// //             const SizedBox(width: 16),
// //             Expanded(
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Text(label,
// //                       style: TextStyle(
// //                           color: color,
// //                           fontWeight: FontWeight.bold,
// //                           fontSize: 14,
// //                           letterSpacing: 0.5)),
// //                   const SizedBox(height: 3),
// //                   Text(subtitle,
// //                       style: const TextStyle(
// //                           color: Colors.white38, fontSize: 12)),
// //                 ],
// //               ),
// //             ),
// //             Icon(Icons.arrow_forward_ios,
// //                 color: color.withOpacity(0.5), size: 16),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _memberTile(Map<String, dynamic> member) {
// //     final bool isPaid =
// //         member['feeStatus']?.toString().toLowerCase() == 'paid';
// //     final validUntil = member['validUntil'] != null
// //         ? DateFormat('dd MMM yyyy')
// //             .format((member['validUntil'] as Timestamp).toDate())
// //         : '--';

// //     return Container(
// //       margin: const EdgeInsets.only(bottom: 10),
// //       padding: const EdgeInsets.all(14),
// //       decoration: BoxDecoration(
// //         color: Colors.white.withOpacity(0.04),
// //         borderRadius: BorderRadius.circular(14),
// //         border: Border.all(color: Colors.white.withOpacity(0.05)),
// //       ),
// //       child: Row(
// //         children: [
// //           CircleAvatar(
// //             radius: 22,
// //             backgroundColor: Colors.yellowAccent.withOpacity(0.1),
// //             child: Text(
// //               (member['name'] as String)[0].toUpperCase(),
// //               style: const TextStyle(
// //                   color: Colors.yellowAccent,
// //                   fontWeight: FontWeight.bold),
// //             ),
// //           ),
// //           const SizedBox(width: 14),
// //           Expanded(
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Text(member['name'],
// //                     style: const TextStyle(
// //                         color: Colors.white,
// //                         fontWeight: FontWeight.bold,
// //                         fontSize: 14)),
// //                 const SizedBox(height: 3),
// //                 Text("Valid: $validUntil",
// //                     style: const TextStyle(
// //                         color: Colors.white38, fontSize: 11)),
// //               ],
// //             ),
// //           ),
// //           Container(
// //             padding:
// //                 const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
// //             decoration: BoxDecoration(
// //               color: isPaid
// //                   ? Colors.greenAccent.withOpacity(0.1)
// //                   : Colors.redAccent.withOpacity(0.1),
// //               borderRadius: BorderRadius.circular(8),
// //             ),
// //             child: Text(
// //               isPaid ? 'PAID' : 'UNPAID',
// //               style: TextStyle(
// //                   color: isPaid ? Colors.greenAccent : Colors.redAccent,
// //                   fontSize: 10,
// //                   fontWeight: FontWeight.bold),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }




// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// import '../../auth/login.dart';
// import 'staff_mark_attendance.dart';
// import 'staff_mark_fees.dart';
// import '../../shared/skeleton_loaders.dart';
// import '../../shared/gym_status_service.dart';

// class GymStaff extends StatefulWidget {
//   const GymStaff({super.key});

//   @override
//   State<GymStaff> createState() => _GymStaffState();
// }

// class _GymStaffState extends State<GymStaff> {
//   final _fs   = FirebaseFirestore.instance;
//   final _auth = FirebaseAuth.instance;

//   bool   _isLoading     = true;
//   String staffName      = '';
//   String gymId          = '';
//   String gymName        = '';
//   int    todayAttendance = 0;
//   int    totalMembers   = 0;
//   List<Map<String, dynamic>> members = [];

//   GymStatusResult? _gymStatus;

//   // ── Computed helpers ──────────────────────────────────────────────────────
//   bool get _isLocked   => _gymStatus?.access == GymAccessLevel.locked;
//   bool get _isReadOnly => _gymStatus?.access == GymAccessLevel.readOnly;

//   @override
//   void initState() {
//     super.initState();
//     _loadData();
//   }

//   Future<void> _loadData() async {
//     setState(() => _isLoading = true);
//     try {
//       final uid = _auth.currentUser!.uid;

//       final userDoc = await _fs.collection('users').doc(uid).get();
//       final data    = userDoc.data()!;
//       staffName = data['name']  ?? 'Staff';
//       gymId     = data['gymId'] ?? '';

//       if (gymId.isEmpty) {
//         setState(() => _isLoading = false);
//         return;
//       }

//       // Gym status check
//       final statusResult = await GymStatusService.checkAccess(gymId);

//       final gymDoc = await _fs.collection('gyms').doc(gymId).get();
//       gymName = gymDoc.data()?['gymName'] ?? 'Gym';

//       final today    = DateTime.now();
//       final todayKey =
//           '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

//       final attSnap = await _fs
//           .collection('gyms').doc(gymId).collection('attendance')
//           .where('date', isEqualTo: todayKey)
//           .get();
//       todayAttendance = attSnap.size;

//       final membersSnap = await _fs
//           .collection('gyms').doc(gymId).collection('members')
//           .get();
//       totalMembers = membersSnap.size;

//       final List<Map<String, dynamic>> loaded = [];
//       for (final doc in membersSnap.docs) {
//         final mData = doc.data();
//         final uDoc  = await _fs.collection('users').doc(doc.id).get();
//         loaded.add({
//           'uid':        doc.id,
//           'name':       uDoc.data()?['name'] ?? 'Unknown',
//           'plan':       mData['plan']         ?? 'Monthly',
//           'feeStatus':  mData['feeStatus']    ?? 'unpaid',
//           'currentFee': mData['currentFee']   ?? 0,
//           'validUntil': mData['validUntil'],
//         });
//       }

//       if (mounted) {
//         setState(() {
//           members    = loaded;
//           _gymStatus = statusResult;
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       debugPrint('Staff load error: $e');
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _logout() async {
//     await _auth.signOut();
//     if (mounted) {
//       Navigator.of(context).pushAndRemoveUntil(
//         MaterialPageRoute(builder: (_) => const Login()),
//         (_) => false,
//       );
//     }
//   }

//   // ── Write-gate helper ─────────────────────────────────────────────────────
//   void _requireFullAccess(VoidCallback action) {
//     if (_isLocked) {
//       _showSnack('Gym is unavailable. Contact your manager.', Colors.redAccent);
//       return;
//     }
//     if (_isReadOnly) {
//       _showSnack(
//         'Online services are disabled by this gym. Actions cannot be recorded.',
//         Colors.orangeAccent,
//       );
//       return;
//     }
//     action();
//   }

//   void _showSnack(String msg, Color color) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//       content: Text(msg,
//           style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
//       backgroundColor: color,
//       behavior: SnackBarBehavior.floating,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       margin: const EdgeInsets.all(16),
//     ));
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Loading gate
//     if (_isLoading || _gymStatus == null) {
//       return Scaffold(
//         backgroundColor: Colors.black,
//         appBar: _buildAppBar(titleWidget: skeletonBox(width: 160, height: 16)),
//         body: const GymStaffSkeleton(),
//       );
//     }

//     // Full lockout — gym suspended/blocked/closed
//     if (_isLocked) {
//       return _LockedScreen(
//         gymName:  gymName,
//         staffName: staffName,
//         message:  _gymStatus!.message,
//         onLogout: _logout,
//       );
//     }

//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: _buildAppBar(),
//       body: Column(
//         children: [
//           // Read-only banner — isSaaSActive=false
//           if (_isReadOnly)
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//               color: Colors.orangeAccent,
//               child: const Row(
//                 children: [
//                   Icon(Icons.warning_amber_rounded,
//                       color: Colors.black, size: 18),
//                   SizedBox(width: 10),
//                   Expanded(
//                     child: Text(
//                       'Online services are disabled. Attendance & fee recording unavailable.',
//                       style: TextStyle(
//                         color: Colors.black,
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//           Expanded(
//             child: RefreshIndicator(
//               onRefresh: _loadData,
//               color: Colors.yellowAccent,
//               child: SingleChildScrollView(
//                 physics: const AlwaysScrollableScrollPhysics(),
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         _statCard("TODAY'S CHECK-INS",
//                             '$todayAttendance', Icons.how_to_reg,
//                             Colors.yellowAccent),
//                         const SizedBox(width: 15),
//                         _statCard('TOTAL MEMBERS',
//                             '$totalMembers', Icons.group,
//                             Colors.blueAccent),
//                       ],
//                     ),
//                     const SizedBox(height: 20),

//                     // Mark attendance — write, blocked in readOnly
//                     _actionButton(
//                       icon:     Icons.qr_code_scanner,
//                       label:    'MARK ATTENDANCE',
//                       subtitle: _isReadOnly
//                           ? 'Unavailable — online services disabled'
//                           : 'Scan or search to check in a member',
//                       color:    _isReadOnly ? Colors.white24 : Colors.greenAccent,
//                       disabled: _isReadOnly,
//                       onTap: () => _requireFullAccess(() {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => StaffMarkAttendance(
//                                 gymId:     gymId,
//                                 staffName: staffName,
//                                 members:   members),
//                           ),
//                         ).then((_) => _loadData());
//                       }),
//                     ),
//                     const SizedBox(height: 12),

//                     // Mark fees — write, blocked in readOnly
//                     _actionButton(
//                       icon:     Icons.payments_rounded,
//                       label:    'MARK FEES PAID',
//                       subtitle: _isReadOnly
//                           ? 'Unavailable — online services disabled'
//                           : 'Record a cash payment for a member',
//                       color:    _isReadOnly ? Colors.white24 : Colors.orangeAccent,
//                       disabled: _isReadOnly,
//                       onTap: () => _requireFullAccess(() {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => StaffMarkFees(
//                                 gymId:     gymId,
//                                 staffName: staffName,
//                                 members:   members),
//                           ),
//                         ).then((_) => _loadData());
//                       }),
//                     ),
//                     const SizedBox(height: 30),

//                     // Members list — read-only, always visible
//                     const Text('MEMBERS',
//                         style: TextStyle(
//                             color: Colors.yellowAccent,
//                             fontSize: 12,
//                             fontWeight: FontWeight.bold,
//                             letterSpacing: 1.5)),
//                     const SizedBox(height: 12),
//                     if (members.isEmpty)
//                       const Center(
//                           child: Text('No members yet',
//                               style: TextStyle(color: Colors.white38)))
//                     else
//                       ListView.builder(
//                         shrinkWrap: true,
//                         physics: const NeverScrollableScrollPhysics(),
//                         itemCount: members.length,
//                         itemBuilder: (_, i) => _memberTile(members[i]),
//                       ),
//                     const SizedBox(height: 100),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   AppBar _buildAppBar({Widget? titleWidget}) => AppBar(
//     backgroundColor: Colors.black,
//     elevation: 0,
//     title: titleWidget ??
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(gymName.toUpperCase(),
//                 style: const TextStyle(
//                     color: Colors.yellowAccent,
//                     fontSize: 13,
//                     fontWeight: FontWeight.bold,
//                     letterSpacing: 1.5)),
//             Text('STAFF · ${staffName.toUpperCase()}',
//                 style: const TextStyle(
//                     color: Colors.white54, fontSize: 11)),
//           ],
//         ),
//     actions: [
//       IconButton(
//         icon: const Icon(Icons.logout, color: Colors.redAccent),
//         onPressed: _logout,
//       ),
//     ],
//   );

//   Widget _statCard(String label, String value, IconData icon, Color color) =>
//       Expanded(
//         child: Container(
//           padding: const EdgeInsets.all(18),
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(0.05),
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(color: Colors.white10),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Icon(icon, color: color, size: 24),
//               const SizedBox(height: 10),
//               Text(label,
//                   style: const TextStyle(
//                       color: Colors.white54,
//                       fontSize: 10,
//                       fontWeight: FontWeight.bold)),
//               const SizedBox(height: 4),
//               Text(value,
//                   style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold)),
//             ],
//           ),
//         ),
//       );

//   Widget _actionButton({
//     required IconData     icon,
//     required String       label,
//     required String       subtitle,
//     required Color        color,
//     required VoidCallback onTap,
//     bool disabled = false,
//   }) =>
//       Opacity(
//         opacity: disabled ? 0.45 : 1.0,
//         child: GestureDetector(
//           onTap: onTap,
//           child: Container(
//             padding: const EdgeInsets.all(18),
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.07),
//               borderRadius: BorderRadius.circular(18),
//               border: Border.all(color: color.withOpacity(0.2)),
//             ),
//             child: Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: color.withOpacity(0.15),
//                     shape: BoxShape.circle,
//                   ),
//                   child: Icon(icon, color: color, size: 24),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(label,
//                           style: TextStyle(
//                               color: color,
//                               fontWeight: FontWeight.bold,
//                               fontSize: 14,
//                               letterSpacing: 0.5)),
//                       const SizedBox(height: 3),
//                       Text(subtitle,
//                           style: const TextStyle(
//                               color: Colors.white38, fontSize: 12)),
//                     ],
//                   ),
//                 ),
//                 Icon(Icons.arrow_forward_ios,
//                     color: color.withOpacity(0.5), size: 16),
//               ],
//             ),
//           ),
//         ),
//       );

//   Widget _memberTile(Map<String, dynamic> member) {
//     final bool isPaid =
//         member['feeStatus']?.toString().toLowerCase() == 'paid';
//     final validUntil = member['validUntil'] != null
//         ? DateFormat('dd MMM yyyy')
//             .format((member['validUntil'] as Timestamp).toDate())
//         : '--';

//     return Container(
//       margin: const EdgeInsets.only(bottom: 10),
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.04),
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: Colors.white.withOpacity(0.05)),
//       ),
//       child: Row(
//         children: [
//           CircleAvatar(
//             radius: 22,
//             backgroundColor: Colors.yellowAccent.withOpacity(0.1),
//             child: Text(
//               (member['name'] as String)[0].toUpperCase(),
//               style: const TextStyle(
//                   color: Colors.yellowAccent, fontWeight: FontWeight.bold),
//             ),
//           ),
//           const SizedBox(width: 14),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(member['name'],
//                     style: const TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 14)),
//                 const SizedBox(height: 3),
//                 Text('Valid: $validUntil',
//                     style: const TextStyle(
//                         color: Colors.white38, fontSize: 11)),
//               ],
//             ),
//           ),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//             decoration: BoxDecoration(
//               color: isPaid
//                   ? Colors.greenAccent.withOpacity(0.1)
//                   : Colors.redAccent.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Text(
//               isPaid ? 'PAID' : 'UNPAID',
//               style: TextStyle(
//                   color: isPaid ? Colors.greenAccent : Colors.redAccent,
//                   fontSize: 10,
//                   fontWeight: FontWeight.bold),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ─── Locked screen ─────────────────────────────────────────────────────────────

// class _LockedScreen extends StatelessWidget {
//   const _LockedScreen({
//     required this.gymName,
//     required this.staffName,
//     required this.message,
//     required this.onLogout,
//   });

//   final String        gymName, staffName, message;
//   final VoidCallback  onLogout;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         elevation: 0,
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(gymName.toUpperCase(),
//                 style: const TextStyle(
//                     color: Colors.yellowAccent,
//                     fontSize: 13,
//                     fontWeight: FontWeight.bold,
//                     letterSpacing: 1.5)),
//             Text('STAFF · ${staffName.toUpperCase()}',
//                 style: const TextStyle(
//                     color: Colors.white54, fontSize: 11)),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: onLogout,
//             child: const Text('Logout',
//                 style: TextStyle(color: Colors.redAccent)),
//           ),
//           const SizedBox(width: 8),
//         ],
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(36),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 width: 90, height: 90,
//                 decoration: BoxDecoration(
//                   color: Colors.redAccent.withOpacity(0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(Icons.lock_outline_rounded,
//                     color: Colors.redAccent, size: 40),
//               ),
//               const SizedBox(height: 28),
//               const Text('Gym Unavailable',
//                   style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 22,
//                       fontWeight: FontWeight.bold)),
//               const SizedBox(height: 12),
//               Text(message,
//                   textAlign: TextAlign.center,
//                   style: const TextStyle(
//                       color: Colors.white54, fontSize: 14, height: 1.6)),
//               const SizedBox(height: 12),
//               const Text(
//                 'Please contact your manager for more information.',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                     color: Colors.white38, fontSize: 13, height: 1.5),
//               ),
//               const SizedBox(height: 36),
//               OutlinedButton(
//                 onPressed: onLogout,
//                 style: OutlinedButton.styleFrom(
//                   side: const BorderSide(color: Colors.redAccent),
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12)),
//                   padding: const EdgeInsets.symmetric(
//                       horizontal: 32, vertical: 14),
//                 ),
//                 child: const Text('Log Out',
//                     style: TextStyle(color: Colors.redAccent)),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../auth/login.dart';
import 'staff_mark_attendance.dart';
import 'staff_mark_fees.dart';
import '../../shared/skeleton_loaders.dart';
import '../../shared/gym_status_service.dart';

class GymStaff extends StatefulWidget {
  const GymStaff({super.key});

  @override
  State<GymStaff> createState() => _GymStaffState();
}

class _GymStaffState extends State<GymStaff> {
  final _fs   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  bool   _isLoading     = true;
  String staffName      = '';
  String gymId          = '';
  String gymName        = '';
  int    todayAttendance = 0;
  int    totalMembers   = 0;
  List<Map<String, dynamic>> members = [];

  GymStatusResult? _gymStatus;

  // ── Computed helpers ──────────────────────────────────────────────────────
  bool get _isLocked   => _gymStatus?.access == GymAccessLevel.locked;
  bool get _isReadOnly => _gymStatus?.access == GymAccessLevel.readOnly;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final uid = _auth.currentUser!.uid;

      final userDoc = await _fs.collection('users').doc(uid).get();
      final data    = userDoc.data()!;
      staffName = data['name']  ?? 'Staff';
      gymId     = data['gymId'] ?? '';

      if (gymId.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      // Gym status check
      final statusResult = await GymStatusService.checkAccess(gymId);

      final gymDoc = await _fs.collection('gyms').doc(gymId).get();
      gymName = gymDoc.data()?['gymName'] ?? 'Gym';

      final today    = DateTime.now();
      final todayKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final attSnap = await _fs
          .collection('gyms').doc(gymId).collection('attendance')
          .where('date', isEqualTo: todayKey)
          .get();
      todayAttendance = attSnap.size;

      final membersSnap = await _fs
          .collection('gyms').doc(gymId).collection('members')
          .get();
      totalMembers = membersSnap.size;

      final List<Map<String, dynamic>> loaded = [];
      for (final doc in membersSnap.docs) {
        final mData = doc.data();
        final uDoc  = await _fs.collection('users').doc(doc.id).get();
        loaded.add({
          'uid':        doc.id,
          'name':       uDoc.data()?['name'] ?? 'Unknown',
          'plan':       mData['plan']         ?? 'Monthly',
          'feeStatus':  mData['feeStatus']    ?? 'unpaid',
          'currentFee': mData['currentFee']   ?? 0,
          'validUntil': mData['validUntil'],
        });
      }

      if (mounted) {
        setState(() {
          members    = loaded;
          _gymStatus = statusResult;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Staff load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const Login()),
        (_) => false,
      );
    }
  }

  // ── Write-gate helper ─────────────────────────────────────────────────────
  void _requireFullAccess(VoidCallback action) {
    if (_isLocked) {
      _showSnack('Gym is unavailable. Contact your manager.', Colors.redAccent);
      return;
    }
    if (_isReadOnly) {
      _showSnack(
        'Online services are disabled by this gym. Actions cannot be recorded.',
        Colors.orangeAccent,
      );
      return;
    }
    action();
  }

  void _showSnack(String msg, Color color) {
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
        appBar: _buildAppBar(titleWidget: skeletonBox(width: 160, height: 16)),
        body: const GymStaffSkeleton(),
      );
    }

    // Full lockout — gym suspended/blocked/closed
    if (_isLocked) {
      return _LockedScreen(
        gymName:  gymName,
        staffName: staffName,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.orangeAccent,
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.black, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Online services are disabled. Attendance & fee recording unavailable.',
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
              onRefresh: _loadData,
              color: Colors.yellowAccent,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _statCard("TODAY'S CHECK-INS",
                            '$todayAttendance', Icons.how_to_reg,
                            Colors.yellowAccent),
                        const SizedBox(width: 15),
                        _statCard('TOTAL MEMBERS',
                            '$totalMembers', Icons.group,
                            Colors.blueAccent),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Mark attendance — write, blocked in readOnly
                    _actionButton(
                      icon:     Icons.qr_code_scanner,
                      label:    'MARK ATTENDANCE',
                      subtitle: _isReadOnly
                          ? 'Unavailable — online services disabled'
                          : 'Scan or search to check in a member',
                      color:    _isReadOnly ? Colors.white24 : Colors.greenAccent,
                      disabled: _isReadOnly,
                      onTap: () => _requireFullAccess(() {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StaffMarkAttendance(
                                gymId:     gymId,
                                staffName: staffName,
                                members:   members),
                          ),
                        ).then((_) => _loadData());
                      }),
                    ),
                    const SizedBox(height: 12),

                    // Mark fees — write, blocked in readOnly
                    _actionButton(
                      icon:     Icons.payments_rounded,
                      label:    'MARK FEES PAID',
                      subtitle: _isReadOnly
                          ? 'Unavailable — online services disabled'
                          : 'Record a cash payment for a member',
                      color:    _isReadOnly ? Colors.white24 : Colors.orangeAccent,
                      disabled: _isReadOnly,
                      onTap: () => _requireFullAccess(() {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StaffMarkFees(
                                gymId:     gymId,
                                staffName: staffName,
                                members:   members),
                          ),
                        ).then((_) => _loadData());
                      }),
                    ),
                    const SizedBox(height: 30),

                    // Members list — read-only, always visible
                    const Text('MEMBERS',
                        style: TextStyle(
                            color: Colors.yellowAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5)),
                    const SizedBox(height: 12),
                    if (members.isEmpty)
                      const Center(
                          child: Text('No members yet',
                              style: TextStyle(color: Colors.white38)))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: members.length,
                        itemBuilder: (_, i) => _memberTile(members[i]),
                      ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar({Widget? titleWidget}) => AppBar(
    backgroundColor: Colors.black,
    elevation: 0,
    title: titleWidget ??
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(gymName.toUpperCase(),
                style: const TextStyle(
                    color: Colors.yellowAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5)),
            Text('STAFF · ${staffName.toUpperCase()}',
                style: const TextStyle(
                    color: Colors.white54, fontSize: 11)),
          ],
        ),
    actions: [
      IconButton(
        icon: const Icon(Icons.logout, color: Colors.redAccent),
        onPressed: _logout,
      ),
    ],
  );

  Widget _statCard(String label, String value, IconData icon, Color color) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 10),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );

  Widget _actionButton({
    required IconData     icon,
    required String       label,
    required String       subtitle,
    required Color        color,
    required VoidCallback onTap,
    bool disabled = false,
  }) =>
      Opacity(
        opacity: disabled ? 0.45 : 1.0,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: color.withOpacity(0.07),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 3),
                      Text(subtitle,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    color: color.withOpacity(0.5), size: 16),
              ],
            ),
          ),
        ),
      );

  Widget _memberTile(Map<String, dynamic> member) {
    final bool isPaid =
        member['feeStatus']?.toString().toLowerCase() == 'paid';
    final validUntil = member['validUntil'] != null
        ? DateFormat('dd MMM yyyy')
            .format((member['validUntil'] as Timestamp).toDate())
        : '--';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.yellowAccent.withOpacity(0.1),
            child: Text(
              (member['name'] as String)[0].toUpperCase(),
              style: const TextStyle(
                  color: Colors.yellowAccent, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member['name'],
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const SizedBox(height: 3),
                Text('Valid: $validUntil',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isPaid
                  ? Colors.greenAccent.withOpacity(0.1)
                  : Colors.redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isPaid ? 'PAID' : 'UNPAID',
              style: TextStyle(
                  color: isPaid ? Colors.greenAccent : Colors.redAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Locked screen ─────────────────────────────────────────────────────────────

class _LockedScreen extends StatelessWidget {
  const _LockedScreen({
    required this.gymName,
    required this.staffName,
    required this.message,
    required this.onLogout,
  });

  final String        gymName, staffName, message;
  final VoidCallback  onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(gymName.toUpperCase(),
                style: const TextStyle(
                    color: Colors.yellowAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5)),
            Text('STAFF · ${staffName.toUpperCase()}',
                style: const TextStyle(
                    color: Colors.white54, fontSize: 11)),
          ],
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
                width: 90, height: 90,
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
                'Please contact your manager for more information.',
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