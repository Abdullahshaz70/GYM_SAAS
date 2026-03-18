// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../add_edit_gym_screen.dart';

// class GymsListScreen extends StatelessWidget {
//   const GymsListScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<QuerySnapshot>(
//       stream: FirebaseFirestore.instance
//           .collection('gyms')
//           .orderBy('createdAt', descending: true)
//           .snapshots(),
//       builder: (context, snapshot) {
//         if (!snapshot.hasData) {
//           return const Center(
//             child: CircularProgressIndicator(color: Colors.yellowAccent),
//           );
//         }

//         final gyms = snapshot.data!.docs;

//         if (gyms.isEmpty) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Icon(Icons.inventory_2_outlined, size: 60, color: Colors.white24),
//                 const SizedBox(height: 16),
//                 const Text(
//                   "No gyms added yet",
//                   style: TextStyle(color: Colors.white54, fontSize: 16),
//                 ),
//               ],
//             ),
//           );
//         }

//         return ListView.builder(
//           padding: const EdgeInsets.only(top: 8, bottom: 80),
//           itemCount: gyms.length,
//           itemBuilder: (context, index) {
//             final doc = gyms[index];
//             final g = doc.data() as Map<String, dynamic>;
            
//             // Logic for status and SaaS
//             final String status = g['status'] ?? 'active';
//             final bool isSaaSActive = g['isSaaSActive'] ?? false;
//             final bool isActive = status.toLowerCase() == 'active';

//             return Container(
//               margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.05),
//                 borderRadius: BorderRadius.circular(20),
//                 border: Border.all(color: Colors.white10),
//               ),
//               child: ListTile(
//                 contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                 title: Text(
//                   g['gymName'] ?? "--",
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 18,
//                   ),
//                 ),
//                 subtitle: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const SizedBox(height: 10),
//                     Wrap(
//                       spacing: 8,
//                       runSpacing: 8,
//                       children: [
                        
//                         _buildBadge(
//                           isSaaSActive ? "SAAS: ON" : "SAAS: OFF",
//                           isSaaSActive ? Colors.cyanAccent : Colors.redAccent,
//                         ),
                        
//                       ],
//                     ),
//                     const SizedBox(height: 14),
//                     Row(
//                       children: [
//                         const Icon(Icons.payments_outlined, size: 14, color: Colors.white54),
//                         const SizedBox(width: 6),
//                         Text(
//                           "Default Fee: Rs ${g['defaultFee'] ?? 0}",
//                           style: const TextStyle(color: Colors.white70, fontSize: 13),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//                 trailing: Container(
//                   decoration: BoxDecoration(
//                     color: Colors.yellowAccent.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: IconButton(
//                     icon: const Icon(Icons.edit_note_rounded, color: Colors.yellowAccent),
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => AddEditGymScreen(gymId: doc.id),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   Widget _buildBadge(String text, Color color) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Text(
//         text,
//         style: TextStyle(
//           color: color,
//           fontSize: 9,
//           fontWeight: FontWeight.bold,
//           letterSpacing: 0.8,
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../add_edit_gym_screen.dart';
import 'gym_detail_screen.dart'; // ADD THIS IMPORT

class GymsListScreen extends StatelessWidget {
  const GymsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('gyms')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.yellowAccent),
          );
        }

        final gyms = snapshot.data!.docs;

        if (gyms.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inventory_2_outlined,
                    size: 60, color: Colors.white24),
                const SizedBox(height: 16),
                const Text(
                  "No gyms added yet",
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: gyms.length,
          itemBuilder: (context, index) {
            final doc = gyms[index];
            final g = doc.data() as Map<String, dynamic>;

            final String status = g['status'] ?? 'active';
            final bool isSaaSActive = g['isSaaSActive'] ?? false;
            final bool isActive = status.toLowerCase() == 'active';

            return Container(
              margin:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              // ── CHANGED: onTap navigates to GymDetailScreen ──
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GymDetailScreen(
                        gymId: doc.id,
                        gymName: g['gymName'] ?? 'Gym',
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              g['gymName'] ?? "--",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildBadge(
                                  isActive ? "ACTIVE" : status.toUpperCase(),
                                  isActive
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                                ),
                                _buildBadge(
                                  isSaaSActive ? "SAAS: ON" : "SAAS: OFF",
                                  isSaaSActive
                                      ? Colors.cyanAccent
                                      : Colors.redAccent,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                const Icon(Icons.payments_outlined,
                                    size: 14, color: Colors.white54),
                                const SizedBox(width: 6),
                                Text(
                                  "Default Fee: Rs ${g['defaultFee'] ?? 0}",
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 13),
                                ),
                                const SizedBox(width: 16),
                                const Icon(Icons.location_on_outlined,
                                    size: 14, color: Colors.white54),
                                const SizedBox(width: 4),
                                Text(
                                  g['location'] ?? '--',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.white24, size: 14),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}