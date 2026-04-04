// // ============================================================================
// //  lib/features/owner/analytics/report_history_screen.dart
// //
// //  Reads from `pos_reports_history` collection.
// //  Only shows reports where gymId == current gym (owner-scoped).
// // ============================================================================

// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// // Reuse palette constants (copy or import from owner_analytics_screen.dart)
// const _navy     = Color(0xFF0D1B2A);
// const _navyCard = Color(0xFF112236);
// const _accent   = Color(0xFF4FC3F7);
// const _green    = Color(0xFF4ADE80);
// const _amber    = Color(0xFFFBBF24);
// const _rose     = Color(0xFFF87171);
// const _textPri  = Color(0xFFE2E8F0);
// const _textSec  = Color(0xFF94A3B8);

// class ReportHistoryScreen extends StatelessWidget {
//   final String gymId;
//   const ReportHistoryScreen({super.key, required this.gymId});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: _navy,
//       appBar: AppBar(
//         backgroundColor: _navy,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new, color: _textPri, size: 18),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('REPORT HISTORY',
//                 style: TextStyle(
//                     color: _textPri,
//                     fontSize: 14,
//                     fontWeight: FontWeight.w800,
//                     letterSpacing: 1.4)),
//             Text('Auto-saved on every PDF export',
//                 style: TextStyle(color: _textSec, fontSize: 10)),
//           ],
//         ),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('pos_reports_history')
//             .where('gymId', isEqualTo: gymId)
//             .orderBy('generatedAt', descending: true)
//             .limit(50)
//             .snapshots(),
//         builder: (context, snap) {
//           if (snap.connectionState == ConnectionState.waiting) {
//             return const Center(
//               child: CircularProgressIndicator(color: _accent, strokeWidth: 2));
//           }
//           if (snap.hasError) {
//             return Center(
//               child: Text('Error: ${snap.error}',
//                   style: const TextStyle(color: _rose)));
//           }
//           final docs = snap.data?.docs ?? [];
//           if (docs.isEmpty) {
//             return const _EmptyHistory();
//           }
//           return ListView.builder(
//             padding: const EdgeInsets.all(16),
//             itemCount: docs.length,
//             itemBuilder: (_, i) {
//               final d = docs[i].data() as Map<String, dynamic>;
//               return _HistoryCard(data: d);
//             },
//           );
//         },
//       ),
//     );
//   }
// }

// class _EmptyHistory extends StatelessWidget {
//   const _EmptyHistory();

//   @override
//   Widget build(BuildContext context) => Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(Icons.history_rounded, color: _textSec.withOpacity(0.3), size: 64),
//             const SizedBox(height: 16),
//             const Text('No reports generated yet',
//                 style: TextStyle(color: _textPri, fontSize: 16, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 8),
//             const Text('Export a PDF from the analytics screen\nto create your first history entry.',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(color: _textSec, fontSize: 13, height: 1.5)),
//           ],
//         ),
//       );
// }

// class _HistoryCard extends StatelessWidget {
//   final Map<String, dynamic> data;
//   const _HistoryCard({required this.data});

//   @override
//   Widget build(BuildContext context) {
//     final ts = data['generatedAt'] as Timestamp?;
//     final dt = ts?.toDate();
//     final dateStr = dt != null ? DateFormat('dd MMM yyyy').format(dt) : '—';
//     final timeStr = dt != null ? DateFormat('hh:mm a').format(dt) : '';
//     final summary = data['summary'] as Map<String, dynamic>? ?? {};
//     final revenue = (summary['totalRevenue'] as num? ?? 0).toDouble();
//     final members = summary['totalMembers'] as int? ?? 0;
//     final active  = summary['activeMembers'] as int? ?? 0;
//     final gymName = data['gymName'] as String? ?? '—';

//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: _navyCard,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.white.withOpacity(0.07)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // ── Header row ──────────────────────────────────────────────────
//           Row(
//             children: [
//               Container(
//                 width: 40,
//                 height: 40,
//                 decoration: BoxDecoration(
//                   color: _accent.withOpacity(0.12),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: const Icon(Icons.picture_as_pdf_rounded, color: _accent, size: 20),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(gymName,
//                         style: const TextStyle(
//                             color: _textPri, fontSize: 14, fontWeight: FontWeight.w700)),
//                     Text('$dateStr  ·  $timeStr',
//                         style: const TextStyle(color: _textSec, fontSize: 11)),
//                   ],
//                 ),
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//                 decoration: BoxDecoration(
//                   color: _green.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: _green.withOpacity(0.3)),
//                 ),
//                 child: const Text('SAVED',
//                     style: TextStyle(color: _green, fontSize: 9, fontWeight: FontWeight.bold)),
//               ),
//             ],
//           ),
//           const SizedBox(height: 14),
//           const Divider(color: Colors.white12, height: 1),
//           const SizedBox(height: 12),

//           // ── Snapshot metrics ────────────────────────────────────────────
//           Row(
//             children: [
//               _mini('Revenue', 'Rs ${NumberFormat('#,##0').format(revenue)}', _green),
//               _mini('Members', '$members', _accent),
//               _mini('Active', '$active', _amber),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _mini(String label, String value, Color color) => Expanded(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(value,
//                 style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800)),
//             const SizedBox(height: 2),
//             Text(label, style: const TextStyle(color: _textSec, fontSize: 10)),
//           ],
//         ),
//       );
// }


// lib/features/owner/analytics/report_history_screen.dart
//
// Each card shows a saved report from Firestore pos_reports_history.
// Tap → opens the Firebase Storage downloadUrl directly in the device's
//        PDF viewer / browser (url_launcher externalApplication mode).
// No local files, no regeneration — always opens the original cloud copy.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

const _navy     = Color(0xFF0D1B2A);
const _navyCard = Color(0xFF112236);
const _accent   = Color(0xFF4FC3F7);
const _green    = Color(0xFF4ADE80);
const _amber    = Color(0xFFFBBF24);
const _rose     = Color(0xFFF87171);
const _textPri  = Color(0xFFE2E8F0);
const _textSec  = Color(0xFF94A3B8);

class ReportHistoryScreen extends StatelessWidget {
  final String gymId;
  const ReportHistoryScreen({super.key, required this.gymId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        backgroundColor: _navy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _textPri, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('REPORT HISTORY',
              style: TextStyle(color: _textPri, fontSize: 14,
                  fontWeight: FontWeight.w800, letterSpacing: 1.4)),
          Text('Tap any card to open its PDF',
              style: TextStyle(color: _textSec, fontSize: 10)),
        ]),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Single-field orderBy — no composite index needed
        stream: FirebaseFirestore.instance
            .collection('pos_reports_history')
            .orderBy('sortKey', descending: true)
            .limit(100)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _accent, strokeWidth: 2));
          }
          if (snap.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline_rounded, color: _rose, size: 40),
                const SizedBox(height: 12),
                Text('${snap.error}',
                    style: const TextStyle(color: _textSec, fontSize: 12),
                    textAlign: TextAlign.center),
              ]),
            ));
          }

          // Client-side filter by gymId (no composite index required)
          final docs = (snap.data?.docs ?? [])
              .where((d) =>
                  (d.data() as Map<String, dynamic>)['gymId'] == gymId)
              .toList();

          if (docs.isEmpty) return const _Empty();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return _Card(data: data);
            },
          );
        },
      ),
    );
  }
}

// ─── Empty ────────────────────────────────────────────────────────────────────
class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.history_rounded, color: _textSec.withOpacity(0.25), size: 64),
      const SizedBox(height: 16),
      const Text('No reports yet',
          style: TextStyle(color: _textPri, fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('Tap the PDF icon on the analytics screen\nto generate your first report.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _textSec, fontSize: 13, height: 1.5)),
    ]),
  );
}

// ─── Card ─────────────────────────────────────────────────────────────────────
class _Card extends StatefulWidget {
  final Map<String, dynamic> data;
  const _Card({required this.data});
  @override State<_Card> createState() => _CardState();
}

class _CardState extends State<_Card> {
  bool _opening = false;

  DateTime? get _dt {
    final sk = widget.data['sortKey'] as String?;
    if (sk != null) { try { return DateTime.parse(sk); } catch (_) {} }
    return (widget.data['generatedAt'] as Timestamp?)?.toDate();
  }

  Future<void> _open() async {
    if (_opening) return;

    final url = widget.data['downloadUrl'] as String?;

    // Guard: old record has no URL yet
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No PDF stored for this record — regenerate from analytics screen.'),
        backgroundColor: Color(0xFF92400E),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _opening = true);
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('No PDF viewer found on this device.'),
            backgroundColor: _rose,
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error opening PDF: $e'),
          backgroundColor: _rose,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dt      = _dt;
    final dateStr = dt != null ? DateFormat('dd MMM yyyy').format(dt) : '—';
    final timeStr = dt != null ? DateFormat('hh:mm a').format(dt)     : '';
    final summary = widget.data['summary'] as Map<String, dynamic>? ?? {};
    final revenue = (summary['totalRevenue'] as num? ?? 0).toDouble();
    final members = summary['totalMembers']  as int? ?? 0;
    final active  = summary['activeMembers'] as int? ?? 0;
    final gymName = widget.data['gymName']   as String? ?? '—';
    final hasUrl  = (widget.data['downloadUrl'] as String?)?.isNotEmpty == true;

    return GestureDetector(
      onTap: _open,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _navyCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _opening ? _accent.withOpacity(0.5) : Colors.white.withOpacity(0.07),
            width: _opening ? 1.5 : 1.0,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Header ──────────────────────────────────────────────────────
          Row(children: [
            // PDF icon / spinner
            AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: _accent.withOpacity(_opening ? 0.22 : 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _opening
                  ? const Padding(padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: _accent))
                  : const Icon(Icons.picture_as_pdf_rounded, color: _accent, size: 20),
            ),
            const SizedBox(width: 12),

            // Gym name + date
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(gymName, style: const TextStyle(color: _textPri, fontSize: 14, fontWeight: FontWeight.w700)),
              Text('$dateStr  ·  $timeStr', style: const TextStyle(color: _textSec, fontSize: 11)),
            ])),

            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: hasUrl ? _green.withOpacity(0.1) : _amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: hasUrl ? _green.withOpacity(0.3) : _amber.withOpacity(0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(hasUrl ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                    color: hasUrl ? _green : _amber, size: 11),
                const SizedBox(width: 4),
                Text(hasUrl ? 'OPEN' : 'NO FILE',
                    style: TextStyle(
                        color: hasUrl ? _green : _amber,
                        fontSize: 9,
                        fontWeight: FontWeight.bold)),
              ]),
            ),
          ]),

          const SizedBox(height: 14),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),

          // ── Snapshot metrics ────────────────────────────────────────────
          Row(children: [
            _mini('Revenue', 'Rs ${NumberFormat('#,##0').format(revenue)}', _green),
            _mini('Members', '$members', _accent),
            _mini('Active',  '$active',  _amber),
          ]),

          // Tap hint
          if (hasUrl) ...[
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.touch_app_rounded, color: _textSec.withOpacity(0.4), size: 13),
              const SizedBox(width: 4),
              Text('Tap to open PDF', style: TextStyle(color: _textSec.withOpacity(0.4), fontSize: 10)),
            ]),
          ],
        ]),
      ),
    );
  }

  Widget _mini(String label, String value, Color color) => Expanded(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: _textSec, fontSize: 10)),
    ]));
}