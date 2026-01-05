import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';


import 'auth/login.dart';
import 'member_detail.dart';


class GymOwner extends StatefulWidget {
  const GymOwner({super.key});

  @override
  State<GymOwner> createState() => _GymOwnerState();
}

class _GymOwnerState extends State<GymOwner> {
  
  final TextEditingController _searchController = TextEditingController();


  bool _isLoggingOut = false;


  double totalRevenue = 0;
  int totalMembers = 0;
  String? gymId;
  bool loadingStats = true;

  String? name;
  String? gymCode;

  List<Map<String, dynamic>> allMembers = [];
  List<Map<String, dynamic>> filteredMembers = [];
  bool loadingMembers = true;

  int todayAttendanceCount = 0;



Future<void> fetchGymStats() async {

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

  final membersSnapshot = await firestore
      .collection('gyms')
      .doc(gymId)
      .collection('members')
      .get();

  
  final today = DateTime.now();
final todayKey =
    "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

final attendanceSnapshot = await firestore
    .collection('gyms')
    .doc(gymId)
    .collection('attendance')
    .where('date', isEqualTo: todayKey)
    .get();

todayAttendanceCount = attendanceSnapshot.size;




  final paymentsSnapshot = await firestore
      .collection('gyms')
      .doc(gymId)
      .collection('payments')
      .get();

  double revenue = 0;
  for (var doc in paymentsSnapshot.docs) {
    revenue += (doc['amount'] as num).toDouble();
  }

  setState(() {
    totalMembers = membersSnapshot.size;
    totalRevenue = revenue;
    loadingStats = false;
    name = gymQuery.docs.first['gymName'] ?? 'Owner';
    gymCode = gymQuery.docs.first['registrationCode'] ?? '';
  });

  await fetchMembers();
}

Future<void> fetchMembers() async {
  if (gymId == null) return;

  setState(() {
    loadingMembers = true;
  });

  final firestore = FirebaseFirestore.instance;

  final membersSnapshot = await firestore
      .collection('gyms')
      .doc(gymId)
      .collection('members')
      .get();

  List<Map<String, dynamic>> members = [];

  for (var doc in membersSnapshot.docs) {
    final uid = doc.id;
    final data = doc.data();

    final userDoc =
        await firestore.collection('users').doc(uid).get();

    members.add({
      'id': uid.substring(0, 6).toUpperCase(),
      'uid': uid,
      'name': userDoc.exists ? userDoc['name'] ?? 'Unknown' : 'Unknown',
      'status': data['status'] ?? 'Pending',
      'membershipPlan': data['membershipPlan'],
      'validUntil': data['validUntil'],
      'totalFeesPaid': data['totalFeesPaid'] ?? 0,
    });
  }

  setState(() {
    allMembers = members;
    filteredMembers = members;
    loadingMembers = false;
  });
}


void _onSearchChanged(String query) {
  query = query.toLowerCase();

  setState(() {
    filteredMembers = allMembers.where((member) {
      return member['name'].toLowerCase().contains(query) ||
             member['id'].toLowerCase().contains(query);
    }).toList();
  });
}


void _showAttendanceQR() {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('gyms')
            .doc(gymId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final token = data['currentAttendanceQrToken'];

          return Container(
            padding: const EdgeInsets.all(30),
            decoration: const BoxDecoration(
              color: Color(0xFF121212),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "SCAN TO MARK ATTENDANCE",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(15),
                  child: QrImageView(
                    data: "$gymId|$token",
                    size: 220,
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}


@override

void initState() {
  super.initState();
  fetchGymStats();
}



  Future<void> _logout() async {
    setState(() {
      _isLoggingOut = true;
    });

    try {
      await FirebaseAuth.instance.signOut();
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const Login()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
      }
      setState(() {
        _isLoggingOut = false;
      });
    }
  }





  @override



@override
  Widget build(BuildContext context) {
    if (loadingStats) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.yellowAccent,
            strokeWidth: 2,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          "Welcome,\n$name".toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _showRegistrationQR(context),
            icon: const Icon(Icons.qr_code_2, color: Colors.yellowAccent, size: 28),
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.redAccent),
          )
        ],
      ),
      
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAttendanceQR,
        backgroundColor: Colors.yellowAccent,
        icon: const Icon(Icons.qr_code, color: Colors.black),
        label: const Text(
          "SHOW ATTENDANCE QR",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),


      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAttendanceStatusCard(),
            const SizedBox(height: 25),

            Row(
              children: [
                _buildStatCard(
                  "REVENUE",
                  "Rs ${totalRevenue.toStringAsFixed(0)}",
                  Icons.monetization_on,
                  Colors.greenAccent,
                ),
                const SizedBox(width: 15),
                _buildStatCard(
                  "MEMBERS",
                  totalMembers.toString(),
                  Icons.group,
                  Colors.blueAccent,
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            _buildSearchSection(),
            const SizedBox(height: 20),

            loadingMembers
                ? const Center(child: CircularProgressIndicator(color: Colors.yellowAccent))
                : filteredMembers.isEmpty
                    ? const Center(child: Text("No members found", style: TextStyle(color: Colors.white38)))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredMembers.length,
                        itemBuilder: (context, index) {
                          final member = filteredMembers[index];
                          return _buildMemberTile(member: member);
                        },
                      ),
          ],
        ),
      ),
    );
  }


  Widget _buildAttendanceStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.yellowAccent,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("TODAY'S ATTENDANCE", 
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
              SizedBox(height: 5),
              Text(
                "$todayAttendanceCount Members",
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.how_to_reg, color: Colors.black, size: 30),
          )
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "MANAGE MEMBERS",
          style: TextStyle(color: Colors.yellowAccent, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Search member name or ID...",
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: const Icon(Icons.search, color: Colors.yellowAccent),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.yellowAccent),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 15),
            Text(title, style: const TextStyle(color: Colors.white60, fontSize: 12)),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberTile({required Map<String, dynamic> member}) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MemberDetailScreen(
            uid: member['uid'],  
            gymId: gymId!,
          ),
        ),
      );
    },
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.yellowAccent,
                child: Text(member['name'][0], style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text("ID: ${member['id']}", style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: member['status'] == "Paid" ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              member['status'],
              style: TextStyle(
                color: member['status'] == "Paid" ? Colors.greenAccent : Colors.orangeAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}


void _showRegistrationQR(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: Colors.white10, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.yellowAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.qr_code_scanner, color: Colors.yellowAccent, size: 30),
            ),
            const SizedBox(height: 15),
            const Text(
              "GYM ACCESS CODE",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Let the member scan this to join your gym",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
            ),
            const SizedBox(height: 35),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.yellowAccent.withOpacity(0.15),
                    blurRadius: 30,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: QrImageView(
                data: gymCode ?? "NO-CODE",
                version: QrVersions.auto,
                size: 180.0,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Colors.black,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: () {
                _showCustomToast(context, "Code Copied");
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      gymCode ?? "---",
                      style: const TextStyle(
                        color: Colors.yellowAccent,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 5,
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Icon(Icons.copy_rounded, color: Colors.white38, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellowAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                child: const Text("DONE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      );
    },
  );
}

void _showCustomToast(BuildContext context, String message) {
  OverlayEntry? overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => _ToastWidget(
      message: message,
      onDismissed: () {
        overlayEntry?.remove();
      },
    ),
  );

  Overlay.of(context).insert(overlayEntry);
}



}



class _ToastWidget extends StatefulWidget {
  final String message;
  final VoidCallback onDismissed;

  const _ToastWidget({required this.message, required this.onDismissed});

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _controller.reverse().then((value) => widget.onDismissed());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: MediaQuery.of(context).size.height * 0.12,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Text(
                  widget.message,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}




