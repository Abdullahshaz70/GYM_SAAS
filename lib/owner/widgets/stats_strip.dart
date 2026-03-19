// import 'package:flutter/material.dart';

// class StatsStrip extends StatelessWidget {
//   const StatsStrip({
//     super.key,
//     required this.totalRevenue,
//     required this.onlineRevenue,
//     required this.cashRevenue,
//     required this.totalMembers,
//   });

//   final double totalRevenue;
//   final double onlineRevenue;
//   final double cashRevenue;
//   final int totalMembers;

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       scrollDirection: Axis.horizontal,
//       physics: const BouncingScrollPhysics(),
//       child: Row(
//         children: [
//           _StatChip(
//             label: 'Total',
//             value: 'Rs ${totalRevenue.toStringAsFixed(0)}',
//             icon: Icons.monetization_on_rounded,
//             color: Colors.greenAccent,
//           ),
//           _StatChip(
//             label: 'Online',
//             value: 'Rs ${onlineRevenue.toStringAsFixed(0)}',
//             icon: Icons.account_balance_wallet_rounded,
//             color: Colors.purpleAccent,
//           ),
//           _StatChip(
//             label: 'Cash',
//             value: 'Rs ${cashRevenue.toStringAsFixed(0)}',
//             icon: Icons.payments_rounded,
//             color: Colors.tealAccent,
//           ),
//           _StatChip(
//             label: 'Members',
//             value: totalMembers.toString(),
//             icon: Icons.group_rounded,
//             color: Colors.blueAccent,
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _StatChip extends StatelessWidget {
//   const _StatChip({
//     required this.label,
//     required this.value,
//     required this.icon,
//     required this.color,
//   });

//   final String label;
//   final String value;
//   final IconData icon;
//   final Color color;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(left: 5),
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//       decoration: BoxDecoration(
//         color: Colors.grey[900],
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.white10),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, color: color, size: 18),
//           const SizedBox(width: 10),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(label,
//                   style: const TextStyle(color: Colors.white54, fontSize: 10)),
//               Text(
//                 value,
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 14,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }



import 'package:flutter/material.dart';

class StatsStrip extends StatelessWidget {
  const StatsStrip({
    super.key,
    required this.totalRevenue,
    required this.onlineRevenue,
    required this.cashRevenue,
    required this.totalMembers,
  });

  final double totalRevenue;
  final double onlineRevenue;
  final double cashRevenue;
  final int totalMembers;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Primary row — most-glanced numbers get more space
        Row(
          children: [
            _StatCard(
              label: 'Total revenue',
              value: 'Rs ${totalRevenue.toStringAsFixed(0)}',
              dotColor: const Color(0xFF4ade80),
              large: true,
            ),
            const SizedBox(width: 8),
            _StatCard(
              label: 'Members',
              value: totalMembers.toString(),
              dotColor: const Color(0xFF60a5fa),
              large: true,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Secondary row
        Row(
          children: [
            _StatCard(
              label: 'Online',
              value: 'Rs ${onlineRevenue.toStringAsFixed(0)}',
              dotColor: const Color(0xFFc084fc),
            ),
            const SizedBox(width: 8),
            _StatCard(
              label: 'Cash',
              value: 'Rs ${cashRevenue.toStringAsFixed(0)}',
              dotColor: const Color(0xFF2dd4bf),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.dotColor,
    this.large = false,
  });

  final String label;
  final String value;
  final Color dotColor;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    letterSpacing: 0.2,
                  ),
                ),
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: large ? 20 : 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}