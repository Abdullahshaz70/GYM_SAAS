import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login.dart';
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

  List<Map<String, dynamic>> allMembers = [];
  List<Map<String, dynamic>> filteredMembers = [];
  bool loadingMembers = true;



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
      title: Text(
        "Welcome,\n$name",
        style: const TextStyle(
          color: Colors.yellowAccent,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      actions: [
        IconButton(
          onPressed: _logout,
          icon: const Icon(Icons.logout, color: Colors.redAccent),
        )
      ],
    ),
    body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.yellowAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.yellowAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user, color: Colors.yellowAccent),
                  const SizedBox(width: 12),
                  const Text(
                    "SaaS Service: ",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    "ACTIVE",
                    style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            Row(
              children: [
              loadingStats
              ? _buildStatCard("REVENUE", "--", Icons.monetization_on, Colors.greenAccent)
              : _buildStatCard(
                  "REVENUE",
                  "Rs ${totalRevenue.toStringAsFixed(0)}",
                  Icons.monetization_on,
                  Colors.greenAccent,
                ),

          const SizedBox(width: 15),

          loadingStats
              ? _buildStatCard("MEMBERS", "--", Icons.group, Colors.blueAccent)
              : _buildStatCard(
                  "MEMBERS",
                  totalMembers.toString(),
                  Icons.group,
                  Colors.blueAccent,
                ),



              ],
            ),
            const SizedBox(height: 30),


            const Text(
              "MANAGE MEMBERS",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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

            
            const SizedBox(height: 20),


  loadingMembers
    ? const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: CircularProgressIndicator(
            color: Colors.yellowAccent,
          ),
        ),
      )
    : filteredMembers.isEmpty
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: Text(
                "No members found",
                style: TextStyle(color: Colors.white38),
              ),
            ),
          )
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


}



