// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// class MemberDetailScreen extends StatefulWidget {
//   final String uid;
//   final String gymId;

//   const MemberDetailScreen({
//     super.key,
//     required this.uid,
//     required this.gymId,
//   });

//   @override
//   State<MemberDetailScreen> createState() => _MemberDetailScreenState();
// }

// class _MemberDetailScreenState extends State<MemberDetailScreen> {
//   bool loading = true;

//   String name = 'Loading...';
//   String status = '';
//   String plan = '';
//   DateTime? joinedAt;
//   DateTime? validUntil;
//   num totalFees = 0;

//   List<Map<String, dynamic>> payments = [];

//   @override
//   void initState() {
//     super.initState();
//     fetchMemberDetails();
//   }

// Future<void> fetchMemberDetails() async {
//   try {
//     final firestore = FirebaseFirestore.instance;

//     // 1️⃣ Get user document
//     final userDoc = await firestore.collection('users').doc(widget.uid).get();
//     final userData = userDoc.data() ?? {};

//     // 2️⃣ Get member document
//     final memberDoc = await firestore
//         .collection('gyms')
//         .doc(widget.gymId)
//         .collection('members')
//         .doc(widget.uid)
//         .get();
//     final memberData = memberDoc.data() ?? {};

//     // 3️⃣ Get payments
//     QuerySnapshot paymentsSnapshot = const QuerySnapshot();
//     try {
//       paymentsSnapshot = await firestore
//           .collection('gyms')
//           .doc(widget.gymId)
//           .collection('payments')
//           .where('memberId', isEqualTo: widget.uid)
//           .orderBy('timestamp', descending: true)
//           .get();
//     } catch (e) {
//       print("Payments fetch error: $e (check Firestore index)");
//     }

//     setState(() {
//       name = userData['name'] ?? 'Unknown';
//       status = memberData['status'] ?? 'Pending';
//       plan = memberData['membershipPlan'] ?? '--';
//       joinedAt = (memberData['createdAt'] as Timestamp?)?.toDate();
//       validUntil = (memberData['validUntil'] as Timestamp?)?.toDate();
//       totalFees = memberData['totalFeesPaid'] ?? 0;

//       payments = paymentsSnapshot.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         final ts = data['timestamp'] as Timestamp?;
//         return {
//           'amount': data['amount'] ?? 0,
//           'date': ts?.toDate() ?? DateTime.now(),
//           'method': data['method'] ?? '--',
//         };
//       }).toList();

//       loading = false;
//     });
//   } catch (e) {
//     print("Error fetching member details: $e");
//     setState(() => loading = false);
//   }
// }

//   @override
//   Widget build(BuildContext context) {
//     if (loading) {
//       return const Scaffold(
//         backgroundColor: Colors.black,
//         body: Center(
//           child: CircularProgressIndicator(color: Colors.yellowAccent),
//         ),
//       );
//     }

//     bool isActive = status.toLowerCase() == 'active';

//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text(
//           "MEMBER PROFILE",
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//             letterSpacing: 1.2,
//           ),
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.symmetric(horizontal: 20),
//         child: Column(
//           children: [
//             const SizedBox(height: 20),

//             Center(
//               child: Column(
//                 children: [
//                   CircleAvatar(
//                     radius: 50,
//                     backgroundColor: Colors.yellowAccent.withOpacity(0.1),
//                     child: Text(
//                       name[0],
//                       style: const TextStyle(
//                         color: Colors.yellowAccent,
//                         fontSize: 40,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 15),
//                   Text(
//                     name,
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Container(
//                     padding:
//                         const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//                     decoration: BoxDecoration(
//                       color: isActive
//                           ? Colors.greenAccent.withOpacity(0.1)
//                           : Colors.redAccent.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(20),
//                       border: Border.all(
//                         color: isActive
//                             ? Colors.greenAccent
//                             : Colors.redAccent,
//                         width: 0.5,
//                       ),
//                     ),
//                     child: Text(
//                       isActive ? "SUBSCRIPTION ACTIVE" : "PAYMENT OVERDUE",
//                       style: TextStyle(
//                         color: isActive
//                             ? Colors.greenAccent
//                             : Colors.redAccent,
//                         fontSize: 12,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 40),

//             _sectionHeader("DETAILS"),
//             _infoTile(
//   "Joining Date",
//   joinedAt != null
//       ? DateFormat('dd MMM yyyy').format(joinedAt!)
//       : "--",
// ),
// _infoTile(
//   "Valid Until",
//   validUntil != null
//       ? DateFormat('dd MMM yyyy').format(validUntil!)
//       : "--",
// ),

//             _infoTile("Plan Type", plan),
//             _infoTile("Total Fees Paid", "Rs $totalFees"),

//             const SizedBox(height: 35),

//             _sectionHeader("PAYMENT HISTORY"),
//             const SizedBox(height: 10),

//             payments.isEmpty
//                 ? const Padding(
//                     padding: EdgeInsets.only(top: 20),
//                     child: Text(
//                       "No payments found",
//                       style: TextStyle(color: Colors.white38),
//                     ),
//                   )
//                 : Column(
//                     children: payments.map((p) {
//                       return _paymentTile(
//                         DateFormat('MMMM yyyy').format(p['date']),
//                         "Rs ${p['amount']}",
//                         p['method'],
//                       );
//                     }).toList(),
//                   ),

//             const SizedBox(height: 50),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _sectionHeader(String title) {
//     return Align(
//       alignment: Alignment.centerLeft,
//       child: Text(
//         title,
//         style: const TextStyle(
//           color: Colors.yellowAccent,
//           fontSize: 12,
//           fontWeight: FontWeight.bold,
//           letterSpacing: 1.5,
//         ),
//       ),
//     );
//   }

//   Widget _infoTile(String label, String value) {
//     return Container(
//       margin: const EdgeInsets.only(top: 15),
//       padding: const EdgeInsets.all(15),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.03),
//         borderRadius: BorderRadius.circular(15),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label,
//               style:
//                   const TextStyle(color: Colors.white38, fontSize: 14)),
//           Text(value,
//               style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 14,
//                   fontWeight: FontWeight.bold)),
//         ],
//       ),
//     );
//   }

//   Widget _paymentTile(String month, String amount, String method) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         children: [
//           const Icon(Icons.circle,
//               color: Colors.greenAccent, size: 8),
//           const SizedBox(width: 15),
//           Text(month,
//               style: const TextStyle(color: Colors.white)),
//           const Spacer(),
//           Text(amount,
//               style: const TextStyle(
//                   color: Colors.white70,
//                   fontWeight: FontWeight.bold)),
//         ],
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MemberDetailScreen extends StatefulWidget {
  final String uid;
  final String gymId;

  const MemberDetailScreen({
    super.key,
    required this.uid,
    required this.gymId,
  });

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  bool loading = true;

  String name = 'Loading...';
  String status = '';
  String plan = '';
  DateTime? joinedAt;
  DateTime? validUntil;
  num totalFees = 0;

  List<Map<String, dynamic>> payments = [];

  @override
  void initState() {
    super.initState();
    fetchMemberDetails();
  }

  Future<void> fetchMemberDetails() async {
    try {
      final firestore = FirebaseFirestore.instance;

      final userDoc = await firestore.collection('users').doc(widget.uid).get();
      final userData = userDoc.data() ?? {};


      final memberDoc = await firestore
          .collection('gyms')
          .doc(widget.gymId)
          .collection('members')
          .doc(widget.uid)
          .get();
      final memberData = memberDoc.data() ?? {};


      QuerySnapshot? paymentsSnapshot;
      try {
        paymentsSnapshot = await firestore
            .collection('gyms')
            .doc(widget.gymId)
            .collection('payments')
            .where('memberId', isEqualTo: widget.uid)
            .orderBy('timestamp', descending: true)
            .get();
      } catch (e) {
        print("Payments fetch error: $e (check Firestore index)");
      }

      setState(() {
        name = userData['name'] ?? 'Unknown';
        status = memberData['status'] ?? 'Pending';
        plan = memberData['membershipPlan'] ?? '--';
        joinedAt = (memberData['createdAt'] as Timestamp?)?.toDate();
        validUntil = (memberData['validUntil'] as Timestamp?)?.toDate();
        totalFees = memberData['totalFeesPaid'] ?? 0;

        payments = (paymentsSnapshot?.docs ?? []).map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final ts = data['timestamp'] as Timestamp?;
          return {
            'amount': data['amount'] ?? 0,
            'date': ts?.toDate() ?? DateTime.now(),
            'method': data['method'] ?? '--',
          };
        }).toList();

        loading = false;
      });
    } catch (e) {
      print("Error fetching member details: $e");
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.yellowAccent),
        ),
      );
    }

    bool isActive = status.toLowerCase() == 'active';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "MEMBER PROFILE",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 30),

            // --- PROFILE HEADER ---
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.yellowAccent.withOpacity(0.2), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.yellowAccent.withOpacity(0.1),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : "?",
                        style: const TextStyle(
                          color: Colors.yellowAccent,
                          fontSize: 45,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.greenAccent.withOpacity(0.1)
                          : Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isActive ? Colors.greenAccent.withOpacity(0.5) : Colors.redAccent.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isActive ? Icons.check_circle : Icons.error_outline,
                          size: 14,
                          color: isActive ? Colors.greenAccent : Colors.redAccent,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isActive ? "SUBSCRIPTION ACTIVE" : "PAYMENT OVERDUE",
                          style: TextStyle(
                            color: isActive ? Colors.greenAccent : Colors.redAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            _sectionHeader("MEMBER DETAILS"),
            const SizedBox(height: 5),
            _infoTile(
              "Joining Date",
              joinedAt != null ? DateFormat('dd MMM yyyy').format(joinedAt!) : "--",
            ),
            _infoTile(
              "Valid Until",
              validUntil != null ? DateFormat('dd MMM yyyy').format(validUntil!) : "--",
            ),
            _infoTile("Plan Type", plan),
            _infoTile("Total Fees Paid", "Rs $totalFees"),

            const SizedBox(height: 40),

            _sectionHeader("PAYMENT HISTORY"),
            const SizedBox(height: 15),

            payments.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.history, color: Colors.white10, size: 40),
                        SizedBox(height: 10),
                        Text(
                          "No payment records found",
                          style: TextStyle(color: Colors.white24, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: payments.map((p) {
                      return _paymentTile(
                        DateFormat('MMMM yyyy').format(p['date']),
                        "Rs ${p['amount']}",
                        p['method'] ?? "Cash",
                      );
                    }).toList(),
                  ),

            const SizedBox(height: 60),
          ],
        ),
      ),

    );
  }

  Widget _sectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.yellowAccent,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(top: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _paymentTile(String month, String amount, String method) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.circle, color: Colors.greenAccent, size: 8),
          const SizedBox(width: 15),
          Text(month, style: const TextStyle(color: Colors.white)),
          const Spacer(),
          Text(amount, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
