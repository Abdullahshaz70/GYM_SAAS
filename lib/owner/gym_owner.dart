// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:qr_flutter/qr_flutter.dart';
// import 'package:intl/intl.dart';
// import 'pending_payments_screen.dart';

// import '../auth/login.dart';
// import 'member_detail.dart';
// import 'manage_staff_screen.dart';
// import '../user/screens/skeleton_loaders.dart';

// class GymOwner extends StatefulWidget {
//   const GymOwner({super.key});

//   @override
//   State<GymOwner> createState() => _GymOwnerState();
// }

// class _GymOwnerState extends State<GymOwner> {
//   final TextEditingController _searchController = TextEditingController();

//   bool _isLoggingOut = false;

//   double totalRevenue = 0;
//   double cashRevenue = 0;
//   double onlineRevenue = 0;
//   int pendingOnlineCount = 0;

//   int totalMembers = 0;
//   String? gymId;
//   bool loadingStats = true;

//   String? name;
//   String? gymCode;

//   List<Map<String, dynamic>> allMembers = [];
//   List<Map<String, dynamic>> filteredMembers = [];
//   bool loadingMembers = true;

//   int todayAttendanceCount = 0;

// Future<void> fetchGymStats() async {
//     if (!loadingStats) setState(() => loadingMembers = true);

//     final uid = FirebaseAuth.instance.currentUser!.uid;
//     final firestore = FirebaseFirestore.instance;


//     final gymQuery = await firestore
//         .collection('gyms')
//         .where('ownerUid', isEqualTo: uid)
//         .limit(1)
//         .get();


//     if (gymQuery.docs.isEmpty) {
//       setState(() => loadingStats = false);
//       return;
//     }

//     gymId = gymQuery.docs.first.id;

//     // Attendance
//     final today = DateTime.now();
//     final todayKey =
//         "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
//     final attendanceSnapshot = await firestore
//         .collection('gyms')
//         .doc(gymId)
//         .collection('attendance')
//         .where('date', isEqualTo: todayKey)
//         .get();
//     todayAttendanceCount = attendanceSnapshot.size;

//     // All payments → revenue breakdown
//     final paymentsSnapshot = await firestore
//         .collection('gyms')
//         .doc(gymId)
//         .collection('payments')
//         .get();

//     gymId = gymQuery.docs.first.id;
//     print('DEBUG gymId: $gymId');
//     print('DEBUG payments count: ${paymentsSnapshot.docs.length}');
    

//     double revenue = 0;
//     double cashRev = 0;
//     double onlineRev = 0;
//     int pendingCount = 0;

//     for (final doc in paymentsSnapshot.docs) {
//       final data = doc.data();
//       final amount = (data['amount'] as num).toDouble();
//       final method = (data['method'] ?? '').toString().toLowerCase();
//       final status = (data['status'] ?? '').toString().toLowerCase();

//       // Count pending online payments (awaiting owner approval)
//       if (status == 'pending' &&
//           (method == 'easypaisa' || method == 'jazzcash')) {
//         pendingCount++;
//       }

//       // Only count completed payments in revenue
//       if (status == 'completed' || status == '') {
//         revenue += amount;
//         if (method == 'easypaisa' || method == 'jazzcash') {
//           onlineRev += amount;
//         } else {
//           cashRev += amount;
//         }
//       }
//     }

//     print('DEBUG revenue: $revenue, cash: $cashRev, online: $onlineRev');

//     setState(() {
//       totalRevenue = revenue;
//       cashRevenue = cashRev;
//       onlineRevenue = onlineRev;
//       pendingOnlineCount = pendingCount;
//       loadingStats = false;
//       name = gymQuery.docs.first['gymName'] ?? 'Owner';
//       gymCode = gymQuery.docs.first['registrationCode'] ?? '';
//     });

//     // Fetch members count
//     final membersSnapshot = await firestore
//         .collection('gyms')
//         .doc(gymId)
//         .collection('members')
//         .get();
//     setState(() => totalMembers = membersSnapshot.size);

//     await fetchMembers();
//   }
//   Future<void> fetchMembers() async {
//     if (gymId == null) return;

//     setState(() => loadingMembers = true);
//     final firestore = FirebaseFirestore.instance;

//     try {
//       final membersSnapshot = await firestore
//           .collection('gyms')
//           .doc(gymId)
//           .collection('members')
//           .get();

//       List<Map<String, dynamic>> members = [];

//       for (var doc in membersSnapshot.docs) {
//         final uid = doc.id;
//         final data = doc.data();

//         final userDoc = await firestore.collection('users').doc(uid).get();
//         final role = userDoc.data()?['role'] ?? 'member';

//         if (role == 'staff') continue;

//         members.add({
//           'uid': uid,
//           'name': userDoc.exists
//               ? (userDoc.data()?['name'] ?? 'Unknown')
//               : 'Unknown',
//           'plan': data['plan'] ?? 'Monthly',
//           'feeStatus': data['feeStatus'] ?? 'unpaid',
//           'validUntil': data['validUntil'],
//         });
//       }

//       setState(() {
//         allMembers = members;
//         filteredMembers = members;
//         loadingMembers = false;
//       });
//     } catch (e) {
//       setState(() => loadingMembers = false);
//     }
//   }

//   void _onSearchChanged(String query) {
//     query = query.toLowerCase();
//     setState(() {
//       filteredMembers = allMembers.where((member) {
//         return member['name'].toLowerCase().contains(query);
//       }).toList();
//     });
//   }

//   void _showAttendanceQR() {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (_) {
//         return StreamBuilder<DocumentSnapshot>(
//           stream: FirebaseFirestore.instance
//               .collection('gyms')
//               .doc(gymId)
//               .snapshots(),
//           builder: (context, snapshot) {
//             if (!snapshot.hasData) {
//               return const Center(
//                   child: CircularProgressIndicator(color: Colors.yellowAccent));
//             }

//             final data = snapshot.data!.data() as Map<String, dynamic>;
//             final token = data['currentAttendanceQrToken'] ?? 'no-token';

//             return Container(
//               padding:
//                   const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
//               decoration: BoxDecoration(
//                 color: const Color(0xFF1A1A1A),
//                 borderRadius:
//                     const BorderRadius.vertical(top: Radius.circular(35)),
//                 border: Border.all(color: Colors.white10),
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Container(
//                     width: 40,
//                     height: 5,
//                     decoration: BoxDecoration(
//                       color: Colors.white24,
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                   const SizedBox(height: 25),
//                   const Text(
//                     "MEMBER CHECK-IN",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 18,
//                       fontWeight: FontWeight.w900,
//                       letterSpacing: 1.5,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   const Text(
//                     "Scan the QR code to mark your attendance",
//                     style: TextStyle(color: Colors.white54, fontSize: 13),
//                   ),
//                   const SizedBox(height: 30),
//                   Container(
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(20),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.yellowAccent.withOpacity(0.15),
//                           blurRadius: 30,
//                           spreadRadius: 5,
//                         )
//                       ],
//                     ),
//                     padding: const EdgeInsets.all(20),
//                     child: QrImageView(
//                       data: token,
//                       version: QrVersions.auto,
//                       size: 240,
//                       eyeStyle: const QrEyeStyle(
//                         eyeShape: QrEyeShape.square,
//                         color: Colors.black,
//                       ),
//                       dataModuleStyle: const QrDataModuleStyle(
//                         dataModuleShape: QrDataModuleShape.circle,
//                         color: Colors.black,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 30),
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 16, vertical: 12),
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.05),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Column(
//                       children: [
//                         const Text(
//                           "ACTIVE TOKEN",
//                           style: TextStyle(
//                               color: Colors.white38,
//                               fontSize: 10,
//                               fontWeight: FontWeight.bold),
//                         ),
//                         const SizedBox(height: 4),
//                         SelectableText(
//                           token,
//                           textAlign: TextAlign.center,
//                           style: const TextStyle(
//                             color: Colors.yellowAccent,
//                             fontFamily: 'monospace',
//                             fontWeight: FontWeight.w600,
//                             fontSize: 14,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   @override
//   void initState() {
//     super.initState();
//     fetchGymStats();
//   }

//   Future<void> _logout() async {
//     setState(() => _isLoggingOut = true);
//     try {
//       await FirebaseAuth.instance.signOut();
//       if (mounted) {
//         Navigator.of(context).pushAndRemoveUntil(
//           MaterialPageRoute(builder: (context) => const Login()),
//           (Route<dynamic> route) => false,
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error logging out: $e')),
//         );
//       }
//       setState(() => _isLoggingOut = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (loadingStats) {
//       return Scaffold(
//         backgroundColor: Colors.black,
//         appBar: AppBar(
//           backgroundColor: Colors.black,
//           elevation: 0,
//           title: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               skeletonBox(width: 80, height: 11),
//               const SizedBox(height: 5),
//               skeletonBox(width: 140, height: 16),
//             ],
//           ),
//         ),
//         body: const GymOwnerSkeleton(),
//       );
//     }

//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         elevation: 0,
//         title: Text(
//           "Welcome,\n$name".toUpperCase(),
//           style: const TextStyle(
//             color: Colors.white,
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             letterSpacing: 1.0,
//           ),
//         ),
//         actions: [
//           IconButton(
//             tooltip: "Manage Staff",
//             onPressed: () => Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (_) => ManageStaffScreen(
//                   gymId: gymId!,
//                   allMembers: allMembers,
//                 ),
//               ),
//             ),
//             icon: const Icon(Icons.badge_rounded,
//                 color: Colors.blueAccent, size: 26),
//           ),
//           IconButton(
//             onPressed: () => _showRegistrationQR(context),
//             icon: const Icon(Icons.qr_code_2,
//                 color: Colors.yellowAccent, size: 28),
//           ),
//           IconButton(
//             onPressed: _logout,
//             icon: const Icon(Icons.logout, color: Colors.redAccent),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: _showAttendanceQR,
//         backgroundColor: Colors.yellowAccent,
//         icon: const Icon(Icons.qr_code, color: Colors.black),
//         label: const Text(
//           "SHOW ATTENDANCE QR",
//           style: TextStyle(
//               color: Colors.black,
//               fontWeight: FontWeight.bold,
//               letterSpacing: 1),
//         ),
//       ),
      
      
//       body: RefreshIndicator(
//         onRefresh: () async => fetchGymStats(),
//         color: Colors.yellowAccent,
//         backgroundColor: Colors.grey[900],
//         child: SingleChildScrollView(
//           physics: const AlwaysScrollableScrollPhysics(),
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildAttendanceStatusCard(),
//               const SizedBox(height: 25),
//              Row(
//   children: [
//     _buildStatCard(
//       "TOTAL REVENUE",
//       "Rs ${totalRevenue.toStringAsFixed(0)}",
//       Icons.monetization_on_rounded,
//       Colors.greenAccent,
//     ),
//     const SizedBox(width: 15),
//     _buildStatCard(
//       "MEMBERS",
//       totalMembers.toString(),
//       Icons.group_rounded,
//       Colors.blueAccent,
//     ),
//   ],
// ),
// const SizedBox(height: 15),
// Row(
//   children: [
//     _buildStatCard(
//       "ONLINE REVENUE",
//       "Rs ${onlineRevenue.toStringAsFixed(0)}",
//       Icons.account_balance_wallet_rounded,
//       Colors.purpleAccent,
//     ),
//     const SizedBox(width: 15),
//     _buildStatCard(
//       "CASH REVENUE",
//       "Rs ${cashRevenue.toStringAsFixed(0)}",
//       Icons.payments_rounded,
//       Colors.tealAccent,
//     ),
//   ],
// ),
             
//               const SizedBox(height: 15),
//               Row(
//                 children: [
//                   const SizedBox(width: 15),
//                   GestureDetector(
//                         onTap: pendingOnlineCount > 0
//                             ? () => Navigator.push(
//                                   context,
//                                   MaterialPageRoute(
//                                     builder: (_) =>
//                                         PendingPaymentsScreen(gymId: gymId!),
//                                   ),
//                                 ).then((_) => fetchGymStats())
//                             : null,
//                         child: _buildStatCard(
//                           "PENDING ONLINE",
//                           pendingOnlineCount > 0
//                               ? "$pendingOnlineCount payment${pendingOnlineCount > 1 ? 's' : ''}"
//                               : "None",
//                           Icons.hourglass_top_rounded,
//                           pendingOnlineCount > 0 ? Colors.orangeAccent : Colors.white38,
//                         ),
//                       ),
//                 ],
//               ),
//               const SizedBox(height: 30),
//               _buildSearchSection(),
//               const SizedBox(height: 20),
//               if (loadingMembers)
//                 const MemberListSkeleton()
//               else if (filteredMembers.isEmpty)
//                 const Center(
//                     child: Text("No members found",
//                         style: TextStyle(color: Colors.white38)))
//               else
//                 ListView.builder(
//                   shrinkWrap: true,
//                   physics: const NeverScrollableScrollPhysics(),
//                   itemCount: filteredMembers.length,
//                   itemBuilder: (context, index) {
//                     final member = filteredMembers[index];
//                     return _buildMemberTile(member: member);
//                   },
//                 ),


//                 SizedBox(height: 50,)

//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildAttendanceStatusCard() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.yellowAccent,
//         borderRadius: BorderRadius.circular(15),
//       ),
//       child: Row(
//         children: [
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text("TODAY'S ATTENDANCE",
//                   style: TextStyle(
//                       color: Colors.black,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 12)),
//               const SizedBox(height: 5),
//               Text(
//                 "$todayAttendanceCount Members",
//                 style: const TextStyle(
//                   color: Colors.black,
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//           const Spacer(),
//           Container(
//             padding: const EdgeInsets.all(10),
//             decoration: BoxDecoration(
//               color: Colors.black.withOpacity(0.1),
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(Icons.how_to_reg, color: Colors.black, size: 30),
//           )
//         ],
//       ),
//     );
//   }

//   Widget _buildSearchSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           "MANAGE MEMBERS",
//           style: TextStyle(
//               color: Colors.yellowAccent,
//               fontSize: 14,
//               fontWeight: FontWeight.bold,
//               letterSpacing: 1.5),
//         ),
//         const SizedBox(height: 15),
//         TextField(
//           controller: _searchController,
//           onChanged: _onSearchChanged,
//           style: const TextStyle(color: Colors.white),
//           decoration: InputDecoration(
//             hintText: "Search member name or ID...",
//             hintStyle: const TextStyle(color: Colors.white38),
//             prefixIcon: const Icon(Icons.search, color: Colors.yellowAccent),
//             filled: true,
//             fillColor: Colors.white.withOpacity(0.05),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: const BorderSide(color: Colors.white24),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: const BorderSide(color: Colors.yellowAccent),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildStatCard(
//       String title, String value, IconData icon, Color color) {
//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           color: Colors.white.withOpacity(0.05),
//           borderRadius: BorderRadius.circular(15),
//           border: Border.all(color: Colors.white10),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Icon(icon, color: color, size: 30),
//             const SizedBox(height: 15),
//             Text(title,
//                 style: const TextStyle(color: Colors.white60, fontSize: 12)),
//             Text(value,
//                 style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 22,
//                     fontWeight: FontWeight.bold)),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMemberTile({required Map<String, dynamic> member}) {
//     String status = member['feeStatus']?.toString().toLowerCase() ?? 'unpaid';

//     bool isPaid = status == 'paid';
//     bool isPending = status == 'pending';

//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => MemberDetailScreen(
//               uid: member['uid'] ?? '',
//               gymId: gymId!,
//             ),
//           ),
//         );
//       },
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 12, left: 2, right: 2),
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: Colors.white.withOpacity(0.05),
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: Colors.white.withOpacity(0.05)),
//         ),
//         child: Row(
//           children: [
//             Stack(
//               alignment: Alignment.center,
//               children: [
//                 Container(
//                   width: 50,
//                   height: 50,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     border: Border.all(
//                       color: isPaid
//                           ? Colors.greenAccent
//                           : isPending
//                               ? Colors.orangeAccent
//                               : Colors.redAccent,
//                       width: 2,
//                     ),
//                   ),
//                 ),
//                 CircleAvatar(
//                   radius: 21,
//                   backgroundColor: Colors.yellowAccent.withOpacity(0.1),
//                   child: Text(
//                     (member['name'] ?? "G")[0].toUpperCase(),
//                     style: const TextStyle(
//                       color: Colors.yellowAccent,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(width: 15),
//             Expanded(
//               child: Text(
//                 member['name'] ?? "New Member",
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                 ),
//               ),
//             ),
//             Container(
//               padding:
//                   const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//               decoration: BoxDecoration(
//                 color: isPaid
//                     ? Colors.greenAccent.withOpacity(0.1)
//                     : isPending
//                         ? Colors.orangeAccent.withOpacity(0.1)
//                         : Colors.redAccent.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Text(
//                 status.toUpperCase(),
//                 style: TextStyle(
//                   color: isPaid
//                       ? Colors.greenAccent
//                       : isPending
//                           ? Colors.orangeAccent
//                           : Colors.redAccent,
//                   fontSize: 9,
//                   fontWeight: FontWeight.bold,
//                   letterSpacing: 0.5,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showRegistrationQR(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       isScrollControlled: true,
//       builder: (context) {
//         return Container(
//           decoration: BoxDecoration(
//             color: const Color(0xFF121212),
//             borderRadius:
//                 const BorderRadius.vertical(top: Radius.circular(30)),
//             border: Border.all(color: Colors.white10, width: 1),
//           ),
//           padding:
//               const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 width: 50,
//                 height: 5,
//                 decoration: BoxDecoration(
//                   color: Colors.white24,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//               const SizedBox(height: 30),
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.yellowAccent.withOpacity(0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(Icons.qr_code_scanner,
//                     color: Colors.yellowAccent, size: 30),
//               ),
//               const SizedBox(height: 15),
//               const Text(
//                 "GYM ACCESS CODE",
//                 style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 18,
//                     fontWeight: FontWeight.w900,
//                     letterSpacing: 1.5),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 "Let the member scan this to join your gym",
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                     color: Colors.white.withOpacity(0.4), fontSize: 13),
//               ),
//               const SizedBox(height: 35),
//               Container(
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(25),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.yellowAccent.withOpacity(0.15),
//                       blurRadius: 30,
//                       spreadRadius: 5,
//                     )
//                   ],
//                 ),
//                 child: QrImageView(
//                   data: gymCode ?? "NO-CODE",
//                   version: QrVersions.auto,
//                   size: 180.0,
//                   eyeStyle: const QrEyeStyle(
//                     eyeShape: QrEyeShape.square,
//                     color: Colors.black,
//                   ),
//                   dataModuleStyle: const QrDataModuleStyle(
//                     dataModuleShape: QrDataModuleShape.square,
//                     color: Colors.black,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 30),
//               GestureDetector(
//                 onTap: () => _showCustomToast(context, "Code Copied"),
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(
//                       horizontal: 20, vertical: 15),
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.05),
//                     borderRadius: BorderRadius.circular(15),
//                     border: Border.all(color: Colors.white10),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Text(
//                         gymCode ?? "---",
//                         style: const TextStyle(
//                           color: Colors.yellowAccent,
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                           letterSpacing: 5,
//                         ),
//                       ),
//                       const SizedBox(width: 15),
//                       const Icon(Icons.copy_rounded,
//                           color: Colors.white38, size: 18),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 40),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: () => Navigator.pop(context),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.yellowAccent,
//                     foregroundColor: Colors.black,
//                     padding: const EdgeInsets.symmetric(vertical: 15),
//                     shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(15)),
//                     elevation: 0,
//                   ),
//                   child: const Text("DONE",
//                       style: TextStyle(
//                           fontWeight: FontWeight.bold, letterSpacing: 1)),
//                 ),
//               ),
//               const SizedBox(height: 10),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   void _showCustomToast(BuildContext context, String message) {
//     OverlayEntry? overlayEntry;
//     overlayEntry = OverlayEntry(
//       builder: (context) => _ToastWidget(
//         message: message,
//         onDismissed: () => overlayEntry?.remove(),
//       ),
//     );
//     Overlay.of(context).insert(overlayEntry);
//   }
// }

// class _ToastWidget extends StatefulWidget {
//   final String message;
//   final VoidCallback onDismissed;

//   const _ToastWidget({required this.message, required this.onDismissed});

//   @override
//   State<_ToastWidget> createState() => _ToastWidgetState();
// }

// class _ToastWidgetState extends State<_ToastWidget>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _fadeAnimation;
//   late Animation<Offset> _slideAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );

//     _fadeAnimation =
//         CurvedAnimation(parent: _controller, curve: Curves.easeIn);
//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, 0.5),
//       end: Offset.zero,
//     ).animate(
//         CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

//     _controller.forward();

//     Future.delayed(const Duration(milliseconds: 1500), () {
//       if (mounted) {
//         _controller.reverse().then((value) => widget.onDismissed());
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Positioned(
//       bottom: MediaQuery.of(context).size.height * 0.12,
//       left: 0,
//       right: 0,
//       child: Material(
//         color: Colors.transparent,
//         child: FadeTransition(
//           opacity: _fadeAnimation,
//           child: SlideTransition(
//             position: _slideAnimation,
//             child: Center(
//               child: Container(
//                 padding:
//                     const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.95),
//                   borderRadius: BorderRadius.circular(30),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.2),
//                       blurRadius: 10,
//                       offset: const Offset(0, 5),
//                     )
//                   ],
//                 ),
//                 child: Text(
//                   widget.message,
//                   style: const TextStyle(
//                     color: Colors.black,
//                     fontSize: 14,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }







import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../auth/login.dart';
import 'member_detail.dart';
import 'manage_staff_screen.dart';
import 'pending_payments_screen.dart';
import '../user/screens/skeleton_loaders.dart';

class GymOwner extends StatefulWidget {
  const GymOwner({super.key});

  @override
  State<GymOwner> createState() => _GymOwnerState();
}

class _GymOwnerState extends State<GymOwner> {
  final TextEditingController _searchController = TextEditingController();

  bool _isLoggingOut = false;
  bool loadingStats = true;
  bool loadingMembers = true;

  double totalRevenue = 0;
  double cashRevenue = 0;
  double onlineRevenue = 0;
  int pendingOnlineCount = 0;
  int totalMembers = 0;
  int todayAttendanceCount = 0;

  String? gymId;
  String? name;
  String? gymCode;

  List<Map<String, dynamic>> allMembers = [];
  List<Map<String, dynamic>> filteredMembers = [];

  String _activeFilter = 'all'; // 'all', 'paid', 'unpaid', 'pending'

  // ─── Data fetching ────────────────────────────────────────────────────────

  Future<void> fetchGymStats() async {
    if (!loadingStats) setState(() => loadingStats = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final firestore = FirebaseFirestore.instance;

    final gymQuery = await firestore
        .collection('gyms')
        .where('ownerUid', isEqualTo: uid)
        .limit(1)
        .get();

    if (gymQuery.docs.isEmpty) {
      setState(() => loadingStats = false);
      return;
    }

    gymId = gymQuery.docs.first.id;

    // Today's attendance
    final today = DateTime.now();
    final todayKey =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    final attendanceSnapshot = await firestore
        .collection('gyms')
        .doc(gymId)
        .collection('attendance')
        .where('date', isEqualTo: todayKey)
        .get();

    // Revenue breakdown
    final paymentsSnapshot = await firestore
        .collection('gyms')
        .doc(gymId)
        .collection('payments')
        .get();

    double revenue = 0, cashRev = 0, onlineRev = 0;
    int pendingCount = 0;

    for (final doc in paymentsSnapshot.docs) {
      final data = doc.data();
      final amount = (data['amount'] as num).toDouble();
      final method = (data['method'] ?? '').toString().toLowerCase();
      final status = (data['status'] ?? '').toString().toLowerCase();

      if (status == 'pending' &&
          (method == 'easypaisa' || method == 'jazzcash')) {
        pendingCount++;
      }

      if (status == 'completed' || status == '') {
        revenue += amount;
        if (method == 'easypaisa' || method == 'jazzcash') {
          onlineRev += amount;
        } else {
          cashRev += amount;
        }
      }
    }

    final membersSnapshot = await firestore
        .collection('gyms')
        .doc(gymId)
        .collection('members')
        .get();

    setState(() {
      todayAttendanceCount = attendanceSnapshot.size;
      totalRevenue = revenue;
      cashRevenue = cashRev;
      onlineRevenue = onlineRev;
      pendingOnlineCount = pendingCount;
      totalMembers = membersSnapshot.size;
      name = gymQuery.docs.first['gymName'] ?? 'Owner';
      gymCode = gymQuery.docs.first['registrationCode'] ?? '';
      loadingStats = false;
    });

    await fetchMembers();
  }

  Future<void> fetchMembers() async {
    if (gymId == null) return;
    setState(() => loadingMembers = true);

    final firestore = FirebaseFirestore.instance;

    try {
      final membersSnapshot = await firestore
          .collection('gyms')
          .doc(gymId)
          .collection('members')
          .get();

      List<Map<String, dynamic>> members = [];

      for (var doc in membersSnapshot.docs) {
        final uid = doc.id;
        final data = doc.data();
        final userDoc = await firestore.collection('users').doc(uid).get();
        final role = userDoc.data()?['role'] ?? 'member';
        if (role == 'staff') continue;

        members.add({
          'uid': uid,
          'name': userDoc.exists
              ? (userDoc.data()?['name'] ?? 'Unknown')
              : 'Unknown',
          'plan': data['plan'] ?? 'Monthly',
          'feeStatus': data['feeStatus'] ?? 'unpaid',
          'validUntil': data['validUntil'],
        });
      }

      setState(() {
        allMembers = members;
        _applyFilter();
        loadingMembers = false;
      });
    } catch (e) {
      setState(() => loadingMembers = false);
    }
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase();
    filteredMembers = allMembers.where((m) {
      final matchName = m['name'].toString().toLowerCase().contains(query);
      final status = m['feeStatus']?.toString().toLowerCase() ?? 'unpaid';
      final matchFilter =
          _activeFilter == 'all' || status == _activeFilter;
      return matchName && matchFilter;
    }).toList();
  }

  void _onSearchChanged(String _) => setState(() => _applyFilter());

  void _setFilter(String filter) {
    setState(() {
      _activeFilter = filter;
      _applyFilter();
    });
  }

  // ─── Auth ─────────────────────────────────────────────────────────────────

  Future<void> _logout() async {
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

  // ─── Lifecycle ───────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    fetchGymStats();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        title:
            Text(title, style: const TextStyle(color: Colors.white)),
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
            child: Text(confirmLabel,
                style: TextStyle(
                    color: isDestructive
                        ? Colors.redAccent
                        : Colors.yellowAccent,
                    fontWeight: FontWeight.bold)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─── Modals ───────────────────────────────────────────────────────────────

  void _showAttendanceQR() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('gyms')
            .doc(gymId)
            .snapshots(),
        builder: (context, snapshot) {
          final token = snapshot.hasData
              ? ((snapshot.data!.data()
                      as Map<String, dynamic>)['currentAttendanceQrToken'] ??
                  'no-token')
              : 'loading...';

          return _BottomSheet(
            children: [
              const _SheetTitle(
                icon: Icons.qr_code_rounded,
                iconColor: Colors.yellowAccent,
                title: 'Member Check-In',
                subtitle: 'Scan to mark attendance',
              ),
              const SizedBox(height: 24),
              _QrCard(data: token),
              const SizedBox(height: 20),
              _TokenBox(
                label: 'Active Token',
                value: token,
                onCopy: () => _copyToClipboard(token, 'Token'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRegistrationQR() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BottomSheet(
        children: [
          const _SheetTitle(
            icon: Icons.qr_code_scanner_rounded,
            iconColor: Colors.yellowAccent,
            title: 'Gym Access Code',
            subtitle: 'Members scan this to join your gym',
          ),
          const SizedBox(height: 24),
          _QrCard(data: gymCode ?? 'NO-CODE'),
          const SizedBox(height: 20),
          _TokenBox(
            label: 'Gym Code',
            value: gymCode ?? '---',
            largeText: true,
            onCopy: () => _copyToClipboard(gymCode ?? '', 'Gym code'),
          ),
        ],
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (loadingStats) {
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
      floatingActionButton: _buildFAB(),
      body: RefreshIndicator(
        onRefresh: fetchGymStats,
        color: Colors.yellowAccent,
        backgroundColor: Colors.grey[900],
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AttendanceCard(count: todayAttendanceCount),
              const SizedBox(height: 16),
              _buildStatsGrid(),
              if (pendingOnlineCount > 0) ...[
                const SizedBox(height: 12),
                _PendingBanner(
                  count: pendingOnlineCount,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PendingPaymentsScreen(gymId: gymId!),
                    ),
                  ).then((_) => fetchGymStats()),
                ),
              ],
              const SizedBox(height: 28),
              _buildMembersSection(),
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
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Welcome,',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
          Text(
            (name ?? 'Owner').toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
      actions: [
        _AppBarButton(
          icon: Icons.badge_rounded,
          color: Colors.blueAccent,
          tooltip: 'Manage Staff',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ManageStaffScreen(gymId: gymId!, allMembers: allMembers),
            ),
          ),
        ),
        _AppBarButton(
          icon: Icons.qr_code_2_rounded,
          color: Colors.yellowAccent,
          tooltip: 'Registration QR',
          onTap: _showRegistrationQR,
        ),
        _AppBarButton(
          icon: _isLoggingOut ? Icons.hourglass_top : Icons.logout_rounded,
          color: Colors.redAccent,
          tooltip: 'Log out',
          onTap: _isLoggingOut ? null : _logout,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: _showAttendanceQR,
      backgroundColor: Colors.yellowAccent,
      elevation: 0,
      icon: const Icon(Icons.qr_code_rounded, color: Colors.black),
      label: const Text(
        'ATTENDANCE QR',
        style: TextStyle(
            color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(children: [
          _StatCard(
            label: 'Total Revenue',
            value: 'Rs ${totalRevenue.toStringAsFixed(0)}',
            icon: Icons.monetization_on_rounded,
            color: Colors.greenAccent,
          ),
          const SizedBox(width: 12),
          _StatCard(
            label: 'Members',
            value: totalMembers.toString(),
            icon: Icons.group_rounded,
            color: Colors.blueAccent,
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _StatCard(
            label: 'Online Revenue',
            value: 'Rs ${onlineRevenue.toStringAsFixed(0)}',
            icon: Icons.account_balance_wallet_rounded,
            color: Colors.purpleAccent,
          ),
          const SizedBox(width: 12),
          _StatCard(
            label: 'Cash Revenue',
            value: 'Rs ${cashRevenue.toStringAsFixed(0)}',
            icon: Icons.payments_rounded,
            color: Colors.tealAccent,
          ),
        ]),
      ],
    );
  }

  Widget _buildMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MANAGE MEMBERS',
          style: TextStyle(
              color: Colors.yellowAccent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5),
        ),
        const SizedBox(height: 14),
        // Search bar
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search member name...',
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon:
                const Icon(Icons.search, color: Colors.yellowAccent, size: 20),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.yellowAccent),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['all', 'paid', 'unpaid', 'pending'].map((f) {
              final isActive = _activeFilter == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => _setFilter(f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.yellowAccent
                          : Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: isActive
                            ? Colors.yellowAccent
                            : Colors.white12,
                      ),
                    ),
                    child: Text(
                      f[0].toUpperCase() + f.substring(1),
                      style: TextStyle(
                        color: isActive ? Colors.black : Colors.white60,
                        fontSize: 13,
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        // Member list
        if (loadingMembers)
          const MemberListSkeleton()
        else if (filteredMembers.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No members found',
                  style: TextStyle(color: Colors.white38)),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredMembers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) =>
                _MemberTile(member: filteredMembers[i], gymId: gymId!),
          ),
      ],
    );
  }
}

// ─── Sub-Widgets ─────────────────────────────────────────────────────────────

class _AppBarButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onTap;

  const _AppBarButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: onTap == null ? color.withOpacity(0.4) : color,
            size: 24),
        splashRadius: 22,
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final int count;
  const _AttendanceCard({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.yellowAccent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("TODAY'S ATTENDANCE",
                  style: TextStyle(
                      color: Colors.black87,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
              const SizedBox(height: 6),
              Text(
                '$count Members',
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 26,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                'Checked in today',
                style: TextStyle(
                    color: Colors.black.withOpacity(0.55), fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.how_to_reg_rounded,
                color: Colors.black, size: 28),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(label,
                style:
                    const TextStyle(color: Colors.white54, fontSize: 11)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _PendingBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _PendingBanner({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.orangeAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  color: Colors.orangeAccent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count pending online payment${count > 1 ? 's' : ''}',
                    style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Easypaisa / JazzCash — tap to review',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.orangeAccent, size: 20),
          ],
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final Map<String, dynamic> member;
  final String gymId;

  const _MemberTile({required this.member, required this.gymId});

  @override
  Widget build(BuildContext context) {
    final status = (member['feeStatus'] ?? 'unpaid').toString().toLowerCase();
    final isPaid = status == 'paid';
    final isPending = status == 'pending';

    final statusColor = isPaid
        ? Colors.greenAccent
        : isPending
            ? Colors.orangeAccent
            : Colors.redAccent;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              MemberDetailScreen(uid: member['uid'] ?? '', gymId: gymId),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            // Avatar with status ring
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: statusColor, width: 2),
                  ),
                ),
                CircleAvatar(
                  radius: 19,
                  backgroundColor: Colors.yellowAccent.withOpacity(0.1),
                  child: Text(
                    (member['name'] ?? 'G')[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.yellowAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 13),
            // Name + plan
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member['name'] ?? 'New Member',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    member['plan'] ?? 'Monthly',
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            // Status badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white24, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom Sheet Components ──────────────────────────────────────────────────

class _BottomSheet extends StatelessWidget {
  final List<Widget> children;

  const _BottomSheet({required this.children});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding:
            const EdgeInsets.fromLTRB(24, 16, 24, 24),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 20),
            ...children,
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellowAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Done',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _SheetTitle({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 26),
        ),
        const SizedBox(height: 12),
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: const TextStyle(color: Colors.white54, fontSize: 13)),
      ],
    );
  }
}

class _QrCard extends StatelessWidget {
  final String data;

  const _QrCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.yellowAccent.withOpacity(0.12),
              blurRadius: 30,
              spreadRadius: 4,
            ),
          ],
        ),
        child: QrImageView(
          data: data,
          version: QrVersions.auto,
          size: 200,
          eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square, color: Colors.black),
          dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.circle, color: Colors.black),
        ),
      ),
    );
  }
}

class _TokenBox extends StatelessWidget {
  final String label;
  final String value;
  final bool largeText;
  final VoidCallback onCopy;

  const _TokenBox({
    required this.label,
    required this.value,
    this.largeText = false,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCopy,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.yellowAccent,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: largeText ? 22 : 14,
                    letterSpacing: largeText ? 4 : 1,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            const Icon(Icons.copy_rounded, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }
}