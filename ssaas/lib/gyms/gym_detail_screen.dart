// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import '../add_edit_gym_screen.dart';

// class GymDetailScreen extends StatefulWidget {
//   final String gymId;
//   final String gymName;

//   const GymDetailScreen({
//     super.key,
//     required this.gymId,
//     required this.gymName,
//   });

//   @override
//   State<GymDetailScreen> createState() => _GymDetailScreenState();
// }

// class _GymDetailScreenState extends State<GymDetailScreen> {
//   final _fs = FirebaseFirestore.instance;

//   bool _loading = true;
//   double _totalOnlineCollected = 0;
//   double _pendingPayoutAmount = 0;
//   bool _hasPendingPayout = false;
//   String? _pendingPayoutId;

//   List<Map<String, dynamic>> _payouts = [];
//   List<Map<String, dynamic>> _unpaidOnlinePayments = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadData();
//   }

//   Future<void> _loadData() async {
//     setState(() => _loading = true);
//     try {
//       // 1. Fetch all online payments (markedBy == 'online')
//       final paymentsSnap = await _fs
//           .collection('gyms')
//           .doc(widget.gymId)
//           .collection('payments')
//           .where('markedBy', isEqualTo: 'online')
//           .get();

//       double totalOnline = 0;
//       for (final doc in paymentsSnap.docs) {
//         totalOnline += (doc['amount'] as num).toDouble();
//       }

//       // 2. Fetch payouts subcollection
//       final payoutsSnap = await _fs
//           .collection('gyms')
//           .doc(widget.gymId)
//           .collection('payouts')
//           .orderBy('requestedAt', descending: true)
//           .get();

//       double alreadyPaidOut = 0;
//       bool hasPending = false;
//       String? pendingId;
//       final List<Map<String, dynamic>> payoutList = [];

//       for (final doc in payoutsSnap.docs) {
//         final data = doc.data();
//         payoutList.add({...data, 'id': doc.id});
//         if (data['status'] == 'completed') {
//           alreadyPaidOut += (data['amount'] as num).toDouble();
//         } else if (data['status'] == 'pending') {
//           hasPending = true;
//           pendingId = doc.id;
//         }
//       }

//       // 3. Collect online payment IDs already covered by completed payouts
//       final Set<String> coveredIds = {};
//       for (final p in payoutList) {
//         if (p['status'] == 'completed') {
//           final ids = List<String>.from(p['coveredPaymentIds'] ?? []);
//           coveredIds.addAll(ids);
//         }
//       }

//       // 4. Unpaid online payments = those not covered by any completed payout
//       final List<Map<String, dynamic>> unpaid = [];
//       double pendingAmount = 0;
//       for (final doc in paymentsSnap.docs) {
//         if (!coveredIds.contains(doc.id)) {
//           unpaid.add({...doc.data(), 'id': doc.id});
//           pendingAmount += (doc['amount'] as num).toDouble();
//         }
//       }

//       setState(() {
//         _totalOnlineCollected = totalOnline;
//         _pendingPayoutAmount = pendingAmount;
//         _hasPendingPayout = hasPending;
//         _pendingPayoutId = pendingId;
//         _payouts = payoutList;
//         _unpaidOnlinePayments = unpaid;
//         _loading = false;
//       });
//     } catch (e) {
//       setState(() => _loading = false);
//       _snack("Error loading data: $e", Colors.redAccent);
//     }
//   }

//   Future<void> _requestPayout() async {
//     if (_unpaidOnlinePayments.isEmpty) {
//       _snack("No online payments to payout.", Colors.orange);
//       return;
//     }
//     if (_hasPendingPayout) {
//       _snack("A payout request is already pending.", Colors.orange);
//       return;
//     }

//     final confirm = await _confirmDialog(
//       title: "Request Payout",
//       message:
//           "Create a payout request for Rs ${_pendingPayoutAmount.toStringAsFixed(0)} covering ${_unpaidOnlinePayments.length} online payment(s)?",
//       confirmLabel: "REQUEST",
//       confirmColor: Colors.greenAccent,
//     );
//     if (!confirm) return;

//     try {
//       final now = Timestamp.now();
//       final ids = _unpaidOnlinePayments.map((p) => p['id'] as String).toList();

//       await _fs
//           .collection('gyms')
//           .doc(widget.gymId)
//           .collection('payouts')
//           .add({
//         'amount': _pendingPayoutAmount,
//         'status': 'pending',
//         'requestedAt': now,
//         'completedAt': null,
//         'coveredPaymentIds': ids,
//         'gymId': widget.gymId,
//       });

//       _snack("✅ Payout request created successfully.", Colors.green);
//       await _loadData();
//     } catch (e) {
//       _snack("Error: $e", Colors.redAccent);
//     }
//   }

//   Future<void> _markPayoutComplete(String payoutId, double amount) async {
//     final confirm = await _confirmDialog(
//       title: "Mark as Paid Out",
//       message:
//           "Confirm that Rs ${amount.toStringAsFixed(0)} has been transferred to the gym owner?",
//       confirmLabel: "CONFIRM",
//       confirmColor: Colors.yellowAccent,
//     );
//     if (!confirm) return;

//     try {
//       await _fs
//           .collection('gyms')
//           .doc(widget.gymId)
//           .collection('payouts')
//           .doc(payoutId)
//           .update({
//         'status': 'completed',
//         'completedAt': Timestamp.now(),
//       });

//       _snack("✅ Payout marked as completed.", Colors.green);
//       await _loadData();
//     } catch (e) {
//       _snack("Error: $e", Colors.redAccent);
//     }
//   }

//   Future<bool> _confirmDialog({
//     required String title,
//     required String message,
//     required String confirmLabel,
//     required Color confirmColor,
//   }) async {
//     return await showDialog<bool>(
//           context: context,
//           builder: (ctx) => AlertDialog(
//             backgroundColor: const Color(0xFF1A1A1A),
//             shape:
//                 RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//             title: Text(title,
//                 style: const TextStyle(
//                     color: Colors.white, fontWeight: FontWeight.bold)),
//             content: Text(message,
//                 style: const TextStyle(color: Colors.white70, fontSize: 14)),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(ctx, false),
//                 child: const Text("CANCEL",
//                     style: TextStyle(color: Colors.white38)),
//               ),
//               ElevatedButton(
//                 onPressed: () => Navigator.pop(ctx, true),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: confirmColor,
//                   foregroundColor: Colors.black,
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10)),
//                 ),
//                 child: Text(confirmLabel,
//                     style: const TextStyle(fontWeight: FontWeight.bold)),
//               ),
//             ],
//           ),
//         ) ??
//         false;
//   }

//   void _snack(String msg, Color color) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//       content: Text(msg),
//       backgroundColor: color,
//       behavior: SnackBarBehavior.floating,
//     ));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF0F0F0F),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF0F0F0F),
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new,
//               color: Colors.white, size: 18),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text("GYM DETAIL",
//                 style: TextStyle(
//                     color: Colors.white54,
//                     fontSize: 11,
//                     letterSpacing: 1.5,
//                     fontWeight: FontWeight.w300)),
//             Text(widget.gymName,
//                 style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 17,
//                     fontWeight: FontWeight.bold)),
//           ],
//         ),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 12),
//             child: IconButton(
//               icon: const Icon(Icons.edit_note_rounded,
//                   color: Colors.yellowAccent),
//               onPressed: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                     builder: (_) =>
//                         AddEditGymScreen(gymId: widget.gymId)),
//               ).then((_) => _loadData()),
//             ),
//           ),
//         ],
//       ),
//       body: _loading
//           ? const Center(
//               child:
//                   CircularProgressIndicator(color: Colors.yellowAccent))
//           : RefreshIndicator(
//               onRefresh: _loadData,
//               color: Colors.yellowAccent,
//               backgroundColor: const Color(0xFF1A1A1A),
//               child: SingleChildScrollView(
//                 physics: const AlwaysScrollableScrollPhysics(),
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _buildPayoutSummaryCards(),
//                     const SizedBox(height: 24),
//                     _buildPayoutActionCard(),
//                     const SizedBox(height: 28),
//                     _buildPayoutHistory(),
//                   ],
//                 ),
//               ),
//             ),
//     );
//   }

//   Widget _buildPayoutSummaryCards() {
//     return Row(
//       children: [
//         Expanded(
//           child: _summaryCard(
//             "TOTAL ONLINE",
//             "Rs ${_totalOnlineCollected.toStringAsFixed(0)}",
//             Icons.account_balance_wallet_rounded,
//             Colors.cyanAccent,
//           ),
//         ),
//         const SizedBox(width: 14),
//         Expanded(
//           child: _summaryCard(
//             "PENDING PAYOUT",
//             "Rs ${_pendingPayoutAmount.toStringAsFixed(0)}",
//             Icons.pending_actions_rounded,
//             _pendingPayoutAmount > 0 ? Colors.orangeAccent : Colors.white24,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _summaryCard(
//       String label, String value, IconData icon, Color color) {
//     return Container(
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.07),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: color.withOpacity(0.2)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(icon, color: color, size: 22),
//           const SizedBox(height: 10),
//           Text(label,
//               style: const TextStyle(
//                   color: Colors.white38,
//                   fontSize: 10,
//                   letterSpacing: 1,
//                   fontWeight: FontWeight.bold)),
//           const SizedBox(height: 4),
//           Text(value,
//               style: TextStyle(
//                   color: color,
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold)),
//         ],
//       ),
//     );
//   }

//   Widget _buildPayoutActionCard() {
//     // Show pending payout card if exists
//     if (_hasPendingPayout && _pendingPayoutId != null) {
//       final payout = _payouts.firstWhere(
//           (p) => p['id'] == _pendingPayoutId,
//           orElse: () => {});
//       final amount = (payout['amount'] as num?)?.toDouble() ?? 0;
//       final requestedAt = (payout['requestedAt'] as Timestamp?)?.toDate();
//       final dateStr = requestedAt != null
//           ? DateFormat('dd MMM yyyy · hh:mm a').format(requestedAt)
//           : '--';

//       return Container(
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           color: Colors.orangeAccent.withOpacity(0.07),
//           borderRadius: BorderRadius.circular(18),
//           border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 const Icon(Icons.schedule_rounded,
//                     color: Colors.orangeAccent, size: 18),
//                 const SizedBox(width: 8),
//                 const Text("PENDING PAYOUT REQUEST",
//                     style: TextStyle(
//                         color: Colors.orangeAccent,
//                         fontSize: 11,
//                         fontWeight: FontWeight.bold,
//                         letterSpacing: 1)),
//               ],
//             ),
//             const SizedBox(height: 14),
//             Text("Rs ${amount.toStringAsFixed(0)}",
//                 style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 28,
//                     fontWeight: FontWeight.bold)),
//             const SizedBox(height: 4),
//             Text("Requested on $dateStr",
//                 style:
//                     const TextStyle(color: Colors.white38, fontSize: 12)),
//             const SizedBox(height: 18),
//             SizedBox(
//               width: double.infinity,
//               height: 48,
//               child: ElevatedButton.icon(
//                 onPressed: () =>
//                     _markPayoutComplete(_pendingPayoutId!, amount),
//                 icon: const Icon(Icons.check_circle_rounded, size: 18),
//                 label: const Text("MARK AS PAID OUT",
//                     style: TextStyle(
//                         fontWeight: FontWeight.bold, letterSpacing: 0.5)),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.yellowAccent,
//                   foregroundColor: Colors.black,
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12)),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       );
//     }

//     // No pending payout — show create button
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.03),
//         borderRadius: BorderRadius.circular(18),
//         border: Border.all(color: Colors.white10),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text("PAYOUT",
//               style: TextStyle(
//                   color: Colors.white38,
//                   fontSize: 11,
//                   fontWeight: FontWeight.bold,
//                   letterSpacing: 1)),
//           const SizedBox(height: 8),
//           Text(
//             _unpaidOnlinePayments.isEmpty
//                 ? "No online payments to payout yet."
//                 : "${_unpaidOnlinePayments.length} online payment(s) worth Rs ${_pendingPayoutAmount.toStringAsFixed(0)} are ready for payout.",
//             style: const TextStyle(color: Colors.white70, fontSize: 13),
//           ),
//           if (_unpaidOnlinePayments.isNotEmpty) ...[
//             const SizedBox(height: 16),
//             SizedBox(
//               width: double.infinity,
//               height: 48,
//               child: ElevatedButton.icon(
//                 onPressed: _requestPayout,
//                 icon: const Icon(Icons.send_rounded, size: 18),
//                 label: const Text("CREATE PAYOUT REQUEST",
//                     style: TextStyle(
//                         fontWeight: FontWeight.bold, letterSpacing: 0.5)),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.greenAccent,
//                   foregroundColor: Colors.black,
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12)),
//                 ),
//               ),
//             ),
//           ]
//         ],
//       ),
//     );
//   }

//   Widget _buildPayoutHistory() {
//     final completed =
//         _payouts.where((p) => p['status'] == 'completed').toList();

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text("PAYOUT HISTORY",
//             style: TextStyle(
//                 color: Colors.white38,
//                 fontSize: 11,
//                 fontWeight: FontWeight.bold,
//                 letterSpacing: 1)),
//         const SizedBox(height: 12),
//         if (completed.isEmpty)
//           const Center(
//             child: Padding(
//               padding: EdgeInsets.symmetric(vertical: 24),
//               child: Text("No completed payouts yet.",
//                   style: TextStyle(color: Colors.white24, fontSize: 13)),
//             ),
//           )
//         else
//           ...completed.map((p) => _payoutHistoryTile(p)),
//       ],
//     );
//   }

//   Widget _payoutHistoryTile(Map<String, dynamic> p) {
//     final amount = (p['amount'] as num?)?.toDouble() ?? 0;
//     final completedAt = (p['completedAt'] as Timestamp?)?.toDate();
//     final dateStr = completedAt != null
//         ? DateFormat('dd MMM yyyy').format(completedAt)
//         : '--';
//     final coveredCount =
//         (p['coveredPaymentIds'] as List?)?.length ?? 0;

//     return Container(
//       margin: const EdgeInsets.only(bottom: 10),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.03),
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: Colors.white.withOpacity(0.06)),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 40,
//             height: 40,
//             decoration: BoxDecoration(
//               color: Colors.greenAccent.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: const Icon(Icons.check_circle_rounded,
//                 color: Colors.greenAccent, size: 20),
//           ),
//           const SizedBox(width: 14),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text("Rs ${amount.toStringAsFixed(0)}",
//                     style: const TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 15)),
//                 Text("$coveredCount payment(s) · $dateStr",
//                     style: const TextStyle(
//                         color: Colors.white38, fontSize: 11)),
//               ],
//             ),
//           ),
//           Container(
//             padding:
//                 const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//             decoration: BoxDecoration(
//               color: Colors.greenAccent.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(6),
//             ),
//             child: const Text("PAID OUT",
//                 style: TextStyle(
//                     color: Colors.greenAccent,
//                     fontSize: 9,
//                     fontWeight: FontWeight.bold,
//                     letterSpacing: 0.5)),
//           ),
//         ],
//       ),
//     );
//   }
// }