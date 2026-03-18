// import 'package:flutter/material.dart';

// class PaymentCard extends StatelessWidget {
//   final String feeStatus;
//   final bool isPaid;
//   final String expiryDate;
//   final VoidCallback onPay;

//   const PaymentCard({super.key, required this.feeStatus, required this.isPaid, required this.expiryDate, required this.onPay});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.05),
//         borderRadius: BorderRadius.circular(25),
//         border: Border.all(color: Colors.white10),
//       ),
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text("STATUS", style: TextStyle(color: Colors.white38, fontSize: 11)),
//                   const SizedBox(height: 5),
//                   Text(feeStatus.toUpperCase(), style: TextStyle(color: isPaid ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 18)),
//                 ],
//               ),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: [
//                   const Text("EXPIRES ON", style: TextStyle(color: Colors.white38, fontSize: 11)),
//                   const SizedBox(height: 5),
//                   Text(expiryDate, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//                 ],
//               ),
//             ],
//           ),
//           const SizedBox(height: 20),
//           SizedBox(
//             width: double.infinity,
//             height: 55,
//             child: ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: isPaid ? Colors.white10 : Colors.yellowAccent,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//               ),
//               onPressed: isPaid ? null : onPay,
//               child: Text(isPaid ? "MEMBERSHIP ACTIVE" : "PAY FEES NOW", style: TextStyle(color: isPaid ? Colors.white38 : Colors.black, fontWeight: FontWeight.bold)),
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }



import 'package:flutter/material.dart';

class PaymentCard extends StatelessWidget {
  final String feeStatus;
  final bool isPaid;
  final String expiryDate;
  final VoidCallback onPay;

  const PaymentCard({
    super.key,
    required this.feeStatus,
    required this.isPaid,
    required this.expiryDate,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPending = feeStatus.toLowerCase() == 'pending';

    Color statusColor;
    if (isPaid) {
      statusColor = Colors.greenAccent;
    } else if (isPending) {
      statusColor = Colors.orangeAccent;
    } else {
      statusColor = Colors.redAccent;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('STATUS',
                      style:
                          TextStyle(color: Colors.white38, fontSize: 11)),
                  const SizedBox(height: 5),
                  Text(
                    feeStatus.toUpperCase(),
                    style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('EXPIRES ON',
                      style:
                          TextStyle(color: Colors.white38, fontSize: 11)),
                  const SizedBox(height: 5),
                  Text(expiryDate,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.orangeAccent.withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.hourglass_top_rounded,
                      color: Colors.orangeAccent, size: 14),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Payment submitted — awaiting verification',
                      style: TextStyle(
                          color: Colors.orangeAccent, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isPaid || isPending
                    ? Colors.white10
                    : Colors.yellowAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: isPaid || isPending ? null : onPay,
              child: Text(
                isPaid
                    ? 'MEMBERSHIP ACTIVE'
                    : isPending
                        ? 'AWAITING APPROVAL'
                        : 'PAY FEES NOW',
                style: TextStyle(
                    color: isPaid || isPending
                        ? Colors.white38
                        : Colors.black,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}