import 'package:flutter/material.dart';

class MemberDetailScreen extends StatelessWidget {
  final Map<String, dynamic> member;

  const MemberDetailScreen({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    bool isPaid = member['status'].toString().toLowerCase() == 'paid';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("MEMBER PROFILE", 
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // --- PROFILE HEADER ---
            Center(
              child: Column(
                children: [
                  Hero(
                    tag: member['id'],
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.yellowAccent.withOpacity(0.1),
                      child: Text(
                        member['name'][0],
                        style: const TextStyle(color: Colors.yellowAccent, fontSize: 40, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    member['name'],
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Member ID: ${member['id']}",
                    style: const TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: isPaid ? Colors.greenAccent.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isPaid ? Colors.greenAccent : Colors.redAccent, width: 0.5),
                    ),
                    child: Text(
                      isPaid ? "SUBSCRIPTION ACTIVE" : "PAYMENT OVERDUE",
                      style: TextStyle(
                        color: isPaid ? Colors.greenAccent : Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // --- ACTION BUTTONS ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(Icons.phone, "Call", Colors.blueAccent),
                _buildActionButton(Icons.message, "Text", Colors.orangeAccent),
                _buildActionButton(Icons.edit, "Edit", Colors.white38),
              ],
            ),

            const SizedBox(height: 40),

            // --- INFO SECTION ---
            _buildSectionHeader("DETAILS"),
            _buildInfoTile("Joining Date", "12 Oct 2023"),
            _buildInfoTile("Phone Number", "+92 300 1234567"),
            _buildInfoTile("Plan Type", "Monthly Premium"),

            const SizedBox(height: 30),

            // --- RECENT PAYMENTS ---
            _buildSectionHeader("PAYMENT HISTORY"),
            const SizedBox(height: 10),
            _buildPaymentTile("January 2024", "Rs 5000", "Success"),
            _buildPaymentTile("December 2023", "Rs 5000", "Success"),
            _buildPaymentTile("November 2023", "Rs 5000", "Success"),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(color: Colors.yellowAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
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

  Widget _buildPaymentTile(String month, String amount, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.circle, color: Colors.greenAccent, size: 8),
          const SizedBox(width: 15),
          Text(month, style: const TextStyle(color: Colors.white, fontSize: 14)),
          const Spacer(),
          Text(amount, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}