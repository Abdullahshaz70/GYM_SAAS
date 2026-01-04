  import 'package:flutter/material.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:intl/intl.dart';
  import 'package:url_launcher/url_launcher.dart';
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
    String contactNumber = '';

    List<Map<String, dynamic>> feesList = [];
    bool loadingFees = true;

    bool feesLoading = true;
    List<Map<String, dynamic>> fees = [];



    List<Map<String, dynamic>> payments = [];

    @override
    void initState() {
      super.initState();
      fetchMemberDetails().then((_) => fetchFees());
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
          contactNumber = userData['contactNumber'] ?? '--';

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

    Future<void> _makePhoneCall(String phoneNumber) async {
    final String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri launchUri = Uri(scheme: 'tel', path: cleanNumber);
    
    try {
      await launchUrl(launchUri);
    } catch (e) {
      debugPrint("Could not launch dialer: $e");
    }
  }

    Future<void> _launchWhatsApp(String phoneNumber) async {
    
    final String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final Uri whatsappUri = Uri.parse("https://wa.me/$cleanNumber?text=${Uri.encodeComponent("AOA! $name , your gym membership fee of Rs  is due. Please pay by [Due Date] to continue enjoying your membership. - [Gym Name]!")}");

    try {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Could not launch WhatsApp: $e");
    }
  } 

  Future<void> fetchFees() async {
  setState(() => feesLoading = true);

  try {
    final feesSnapshot = await FirebaseFirestore.instance
        .collection('gyms')
        .doc(widget.gymId)
        .collection('members')
        .doc(widget.uid)
        .collection('fees')
        .orderBy('dueDate', descending: true)
        .get();

    setState(() {
      fees = feesSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'amount': data['amount'] ?? 0,
          'plan': data['plan'] ?? '--',
          'dueDate': (data['dueDate'] as Timestamp?)?.toDate(),
          'paid': data['paid'] ?? false,
          'paidAt': (data['paidAt'] as Timestamp?)?.toDate(),
        };
      }).toList();

      feesLoading = false;
    });
  } catch (e) {
    debugPrint("Error fetching fees: $e");
    setState(() => feesLoading = false);
  }
}

  Future<void> togglePaidStatus(String feeId, bool currentStatus) async {
    final docRef = FirebaseFirestore.instance
        .collection('gyms')
        .doc(widget.gymId)
        .collection('members')
        .doc(widget.uid)
        .collection('fees')
        .doc(feeId);

    await docRef.update({
      'paid': !currentStatus,
      'paidAt': !currentStatus ? Timestamp.now() : null,
    });

    fetchFees();
  }

  Future<void> addOrEditFee({String? feeId, num? currentAmount, String? currentPlan, DateTime? currentDue}) async {
    final amountController = TextEditingController(text: currentAmount?.toString() ?? '');
    final planController = TextEditingController(text: currentPlan ?? '');
    DateTime? dueDate = currentDue;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(feeId == null ? "Add Fee" : "Edit Fee"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Amount"),
            ),
            TextField(
              controller: planController,
              decoration: const InputDecoration(labelText: "Plan"),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text("Due Date: "),
                Text(dueDate != null ? DateFormat('dd MMM yyyy').format(dueDate!) : "--"),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: dueDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (selected != null) dueDate = selected;
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'amount': num.tryParse(amountController.text) ?? 0,
                'plan': planController.text,
                'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
                'paid': false,
                'paidAt': null,
              };
              final collectionRef = FirebaseFirestore.instance
                  .collection('gyms')
                  .doc(widget.gymId)
                  .collection('members')
                  .doc(widget.uid)
                  .collection('fees');

              if (feeId == null) {
                await collectionRef.add(data);
              } else {
                await collectionRef.doc(feeId).update(data);
              }

              Navigator.pop(context);
              fetchFees();
            },
            child: Text(feeId == null ? "Add" : "Save"),
          ),
        ],
      ),
    );
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




  Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      _buildActionButton(
        Icons.phone,
        "Call",
        Colors.blueAccent,
        contactNumber.isNotEmpty && contactNumber != '--'
            ? () async {
                final Uri telUri = Uri(scheme: 'tel', path: contactNumber);
                try {
                  await launchUrl(telUri);
                } catch (e) {
                  debugPrint("Call failed: $e");
                }
              }
            : () => debugPrint("No valid contact number"),
      ),
      _buildActionButton(
        Icons.message,
        "WhatsApp",
        Colors.greenAccent,
        contactNumber.isNotEmpty && contactNumber != '--'
            ? () async {
                final cleanNumber = contactNumber.replaceAll(RegExp(r'[^0-9]'), '');
                final Uri whatsappUri = Uri.parse(
                    "https://wa.me/$cleanNumber?text=${Uri.encodeComponent("Hello!")}");
                try {
                  await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
                } catch (e) {
                  debugPrint("WhatsApp failed: $e");
                }
              }
            : () => debugPrint("No valid WhatsApp number"),
      ),
    ],
  ),


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


              const SizedBox(height: 40),
              
              
              _sectionHeader("FEES"),

feesLoading
    ? const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: Colors.yellowAccent),
        ),
      )
    : fees.isEmpty
        ? const Text(
            "No fees assigned",
            style: TextStyle(color: Colors.white38),
          )
        : Column(
            children: fees.map((f) {
              return _feeTile(
                f['plan'],
                f['amount'],
                f['dueDate'],
                f['paid'],
              );
            }).toList(),
          ),



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

  _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }


  Widget _feeTile(String plan, num amount, DateTime? dueDate, bool paid) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: paid ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: paid ? Colors.green : Colors.red, width: 0.5),
    ),
    child: Row(
      children: [
        Text(plan, style: const TextStyle(color: Colors.white)),
        const Spacer(),
        Text("Rs $amount", style: const TextStyle(color: Colors.white70)),
        const SizedBox(width: 10),
        Text(
          dueDate != null ? DateFormat('dd MMM yyyy').format(dueDate) : "--",
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
        const SizedBox(width: 10),
        Icon(
          paid ? Icons.check_circle : Icons.error_outline,
          color: paid ? Colors.green : Colors.red,
          size: 16,
        ),
      ],
    ),
  );
}


  }