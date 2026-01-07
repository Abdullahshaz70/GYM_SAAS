import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'attendance_screen.dart';
import 'payment_history_screen.dart';
import 'membership_screen.dart';

class MemberDetailScreen extends StatefulWidget {
  final String uid;
  final String gymId;

  const MemberDetailScreen({super.key, required this.uid, required this.gymId});

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  bool loading = true;
  String name = 'Loading...';
  String plan = '';
  DateTime? joinedAt;
  DateTime? validUntil;
  num currentFee = 0;
  String feeStatus = '';
  String contactNumber = '';
  List<Map<String, dynamic>> fees = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final firestore = FirebaseFirestore.instance;
    try {
      final userDoc = await firestore.collection('users').doc(widget.uid).get();
      final memberDoc = await firestore.collection('gyms').doc(widget.gymId).collection('members').doc(widget.uid).get();
      
      final feesSnapshot = await firestore
          .collection('gyms')
          .doc(widget.gymId)
          .collection('members')
          .doc(widget.uid)
          .collection('fees')
          .orderBy('dueDate', descending: true)
          .get();

      setState(() {
        name = userDoc.data()?['name'] ?? 'Unknown';
        contactNumber = userDoc.data()?['contactNumber'] ?? '--';
        plan = memberDoc.data()?['plan'] ?? 'free';
        currentFee = memberDoc.data()?['currentFee'] ?? 0;
        feeStatus = memberDoc.data()?['feeStatus'] ?? 'unpaid';
        joinedAt = (memberDoc.data()?['createdAt'] as Timestamp?)?.toDate();
        validUntil = (memberDoc.data()?['validUntil'] as Timestamp?)?.toDate();
        fees = feesSnapshot.docs.map((doc) => doc.data()).toList();
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      debugPrint('Member fetch error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.yellowAccent)),
      );
    }

    bool isPaid = feeStatus.toLowerCase() == 'paid';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text("MEMBER PROFILE", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildProfileHeader(isPaid),
            const SizedBox(height: 25),
            _buildActionRow(),
            const SizedBox(height: 30),
            
            // Navigation Section
            _buildNavigationTile("Attendance History", Icons.calendar_today_rounded, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => AttendanceScreen(uid: widget.uid, gymId: widget.gymId)));
            }),
            _buildNavigationTile("Payment History", Icons.account_balance_wallet_rounded, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentHistoryScreen(uid: widget.uid, gymId: widget.gymId)));
            }),

            const SizedBox(height: 25),

            // Subscription Details Card
            _buildSubscriptionCard(),

            const SizedBox(height: 30),

            // Recent Transactions Section
            _sectionHeader("RECENT TRANSACTIONS"),
            const SizedBox(height: 12),
            if (fees.isEmpty)
              const Center(child: Text("No records found", style: TextStyle(color: Colors.white24, fontSize: 12)))
            else
              ...fees.take(3).map((f) => _feeTile(f['plan'] ?? 'Monthly Fee', f['amount'] ?? 0, f['paid'] ?? false)),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(bool isPaid) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 55,
              backgroundColor: Colors.yellowAccent.withOpacity(0.1),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 45, color: Colors.yellowAccent, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
              child: Icon(
                isPaid ? Icons.check_circle : Icons.error,
                color: isPaid ? Colors.greenAccent : Colors.redAccent,
                size: 28,
              ),
            )
          ],
        ),
        const SizedBox(height: 15),
        Text(name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isPaid ? Colors.greenAccent.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isPaid ? Colors.greenAccent.withOpacity(0.5) : Colors.redAccent.withOpacity(0.5)),
          ),
          child: Text(
            feeStatus.toUpperCase(),
            style: TextStyle(
              color: isPaid ? Colors.greenAccent : Colors.redAccent,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _actionCircle(Icons.phone_rounded, "Call", Colors.blue, _makeCall),
        const SizedBox(width: 40),
        _actionCircle(Icons.chat_bubble_rounded, "WhatsApp", Colors.greenAccent, _sendWhatsApp),
      ],
    );
  }

  Widget _actionCircle(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildNavigationTile(String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        tileColor: Colors.white.withOpacity(0.04),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white10)),
        leading: Icon(icon, color: Colors.yellowAccent, size: 22),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
      ),
    );
  }

Widget _buildSubscriptionCard() {
  return Column(
    children: [
      _sectionHeader("MEMBERSHIP DETAILS"),
      const SizedBox(height: 12),
      _membershipListTile(
        Icons.fitness_center_rounded, 
        "Plan Type", 
        plan, 
        Colors.blueAccent,
        () => _navigateToEdit("plan", plan),
      ),
      _membershipListTile(
        Icons.currency_rupee_rounded, 
        "Fees Amount", 
        "Rs $currentFee", 
        Colors.orangeAccent,
        () => _navigateToEdit("fee", currentFee.toString()),
      ),
      _membershipListTile(
        Icons.calendar_month_rounded, 
        "Valid Until", 
        validUntil != null ? DateFormat('dd MMM yyyy').format(validUntil!) : "--", 
        Colors.purpleAccent,
        () => _navigateToEdit("validity", validUntil.toString()),
      ),
    ],
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
  ).then((_) => fetchData()); // Refresh data when coming back
}

Widget _membershipListTile(IconData icon, String label, String value, Color accentColor, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: accentColor, size: 22),
          const SizedBox(width: 15),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 12),
        ],
      ),
    ),
  );
}
  Widget _subscriptionRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white38),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _feeTile(String planName, num amount, bool paid) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: (paid ? Colors.greenAccent : Colors.redAccent).withOpacity(0.1),
            child: Icon(paid ? Icons.done_rounded : Icons.priority_high_rounded, 
                        color: paid ? Colors.greenAccent : Colors.redAccent, size: 16),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(planName, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
              Text(paid ? "Payment Successful" : "Pending Payment", 
                   style: TextStyle(color: paid ? Colors.white38 : Colors.redAccent.withOpacity(0.7), fontSize: 11)),
            ],
          ),
          const Spacer(),
          Text("Rs $amount", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(color: Colors.yellowAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
      ),
    );
  }

  void _makeCall() async {
    if (contactNumber.isNotEmpty) {
      final Uri url = Uri.parse("tel:$contactNumber");
      if (await canLaunchUrl(url)) await launchUrl(url);
    }
  }

  void _sendWhatsApp() async {
    if (contactNumber.isNotEmpty) {
      String cleanNumber = contactNumber.replaceAll(RegExp(r'[^0-9]'), '');
      final Uri url = Uri.parse("https://wa.me/$cleanNumber");
      if (await canLaunchUrl(url)) await launchUrl(url);
    }
  }
}