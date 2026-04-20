// // ============================================================================
// //  lib/features/owner/analytics/owner_analytics_screen.dart
// //
// //  Strategic Owner's Module — Deep Navy / Slate palette
// //  Requires: pdf ^3.x, printing ^5.x  (already add to pubspec.yaml)
// // ============================================================================

// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';

// import 'report_history_screen.dart';

// // ─── Palette ─────────────────────────────────────────────────────────────────
// const _navy     = Color(0xFF0D1B2A);
// const _navyCard = Color(0xFF112236);
// const _slate    = Color(0xFF1E3A5F);
// const _accent   = Color(0xFF4FC3F7); // ice-blue
// const _green    = Color(0xFF4ADE80);
// const _amber    = Color(0xFFFBBF24);
// const _rose     = Color(0xFFF87171);
// const _textPri  = Color(0xFFE2E8F0);
// const _textSec  = Color(0xFF94A3B8);

// // ─── Model ───────────────────────────────────────────────────────────────────
// class _AnalyticsData {
//   final double totalRevenue;
//   final double cashRevenue;
//   final double onlineRevenue;
//   final int    totalMembers;
//   final int    activeMembers;   // validUntil >= today
//   final int    overdueMembers;
//   final int    todayAttendance;
//   final int    monthAttendance;
//   final Map<String, double> revenueByMonth;   // "Jan" → amount
//   final Map<String, int>    membersByPlan;    // "Monthly" → count
//   final List<Map<String, dynamic>> recentPayments;
//   final List<Map<String, dynamic>> staffList;

//   const _AnalyticsData({
//     required this.totalRevenue,
//     required this.cashRevenue,
//     required this.onlineRevenue,
//     required this.totalMembers,
//     required this.activeMembers,
//     required this.overdueMembers,
//     required this.todayAttendance,
//     required this.monthAttendance,
//     required this.revenueByMonth,
//     required this.membersByPlan,
//     required this.recentPayments,
//     required this.staffList,
//   });
// }

// // ─── Entry point ─────────────────────────────────────────────────────────────
// class OwnerAnalyticsScreen extends StatefulWidget {
//   final String gymId;
//   final String gymName;

//   const OwnerAnalyticsScreen({
//     super.key,
//     required this.gymId,
//     required this.gymName,
//   });

//   @override
//   State<OwnerAnalyticsScreen> createState() => _OwnerAnalyticsScreenState();
// }

// class _OwnerAnalyticsScreenState extends State<OwnerAnalyticsScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tab;
//   _AnalyticsData? _data;
//   bool _loading = true;
//   bool _generatingPdf = false;
//   String? _error;

//   @override
//   void initState() {
//     super.initState();
//     _tab = TabController(length: 3, vsync: this);
//     _load();
//   }

//   @override
//   void dispose() {
//     _tab.dispose();
//     super.dispose();
//   }

//   // ── Data Layer ──────────────────────────────────────────────────────────────
//   Future<void> _load() async {
//     setState(() { _loading = true; _error = null; });
//     try {
//       final fs = FirebaseFirestore.instance;
//       final gymRef = fs.collection('gyms').doc(widget.gymId);
//       final now = DateTime.now();
//       final todayKey =
//           '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';

//       final results = await Future.wait([
//         gymRef.collection('payments').get(),
//         gymRef.collection('members').get(),
//         gymRef.collection('attendance')
//             .where('date', isEqualTo: todayKey).get(),
//         gymRef.collection('attendance')
//             .where('date', isGreaterThanOrEqualTo:
//                 '${now.year}-${now.month.toString().padLeft(2,'0')}-01').get(),
//         fs.collection('users')
//             .where('gymId', isEqualTo: widget.gymId)
//             .where('role', isEqualTo: 'staff').get(),
//       ]);

//       final paymentsSnap  = results[0] as QuerySnapshot;
//       final membersSnap   = results[1] as QuerySnapshot;
//       final todayAttSnap  = results[2] as QuerySnapshot;
//       final monthAttSnap  = results[3] as QuerySnapshot;
//       final staffSnap     = results[4] as QuerySnapshot;

//       // Revenue aggregation
//       double total = 0, cash = 0, online = 0;
//       final Map<String, double> byMonth = {};
//       final List<Map<String, dynamic>> recentPay = [];

//       for (final doc in paymentsSnap.docs) {
//         final d = doc.data() as Map<String, dynamic>;
//         final status = (d['status'] ?? '').toString().toLowerCase();
//         if (status != 'completed' && status != '') continue;

//         final amount = (d['amount'] as num? ?? 0).toDouble();
//         final method = (d['method'] ?? '').toString().toLowerCase();
//         total += amount;
//         if (method == 'easypaisa' || method == 'jazzcash') {
//           online += amount;
//         } else {
//           cash += amount;
//         }

//         final ts = d['timestamp'] as Timestamp?;
//         if (ts != null) {
//           final dt = ts.toDate();
//           final label = DateFormat('MMM').format(dt);
//           byMonth[label] = (byMonth[label] ?? 0) + amount;
//         }
//         recentPay.add(d);
//       }

//       // Sort recent payments by timestamp desc
//       recentPay.sort((a, b) {
//         final ta = (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
//         final tb = (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
//         return tb.compareTo(ta);
//       });

//       // Member aggregation
//       int active = 0, overdue = 0;
//       final Map<String, int> byPlan = {};

//       for (final doc in membersSnap.docs) {
//         final d = doc.data() as Map<String, dynamic>;
//         final validUntil = (d['validUntil'] as Timestamp?)?.toDate();
//         final feeStatus  = (d['feeStatus'] ?? 'unpaid').toString().toLowerCase();
//         final plan       = (d['plan'] ?? 'Monthly').toString();

//         if (validUntil != null && validUntil.isAfter(now)) {
//           active++;
//         }
//         if (feeStatus == 'overdue' || feeStatus == 'unpaid') overdue++;
//         byPlan[plan] = (byPlan[plan] ?? 0) + 1;
//       }

//       // Staff list
//       final staff = staffSnap.docs
//           .map((d) => {'uid': d.id, ...d.data() as Map<String, dynamic>})
//           .toList();

//       setState(() {
//         _data = _AnalyticsData(
//           totalRevenue:    total,
//           cashRevenue:     cash,
//           onlineRevenue:   online,
//           totalMembers:    membersSnap.size,
//           activeMembers:   active,
//           overdueMembers:  overdue,
//           todayAttendance: todayAttSnap.size,
//           monthAttendance: monthAttSnap.size,
//           revenueByMonth:  byMonth,
//           membersByPlan:   byPlan,
//           recentPayments:  recentPay.take(50).toList(),
//           staffList:       staff,
//         );
//         _loading = false;
//       });
//     } catch (e) {
//       setState(() { _loading = false; _error = e.toString(); });
//     }
//   }

//   // ── PDF Generation ──────────────────────────────────────────────────────────
//   Future<void> _generateAndSharePdf() async {
//     if (_data == null) return;
//     setState(() => _generatingPdf = true);
//     try {
//       final bytes = await _buildPdf(_data!, widget.gymName);
//       await _saveReportToFirestore();
//       await Printing.sharePdf(bytes: bytes,
//           filename: 'owner_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf');
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('PDF error: $e'), backgroundColor: Colors.redAccent));
//       }
//     } finally {
//       if (mounted) setState(() => _generatingPdf = false);
//     }
//   }

//   Future<void> _saveReportToFirestore() async {
//     final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
//     await FirebaseFirestore.instance
//         .collection('pos_reports_history')
//         .add({
//       'gymId':    widget.gymId,
//       'gymName':  widget.gymName,
//       'adminId':  uid,
//       'summary': {
//         'totalRevenue':   _data!.totalRevenue,
//         'cashRevenue':    _data!.cashRevenue,
//         'onlineRevenue':  _data!.onlineRevenue,
//         'totalMembers':   _data!.totalMembers,
//         'activeMembers':  _data!.activeMembers,
//         'overdueMembers': _data!.overdueMembers,
//         'todayAttendance':_data!.todayAttendance,
//         'monthAttendance':_data!.monthAttendance,
//       },
//       'generatedAt': FieldValue.serverTimestamp(),
//     });
//   }

//   // ── PDF Builder ─────────────────────────────────────────────────────────────
//   static Future<Uint8List> _buildPdf(_AnalyticsData d, String gymName) async {
//     final pdf = pw.Document();
//     final now = DateTime.now();
//     final fmt = DateFormat('dd MMM yyyy, hh:mm a');
//     final fmtNum = NumberFormat('#,##0.00', 'en_US');

//     pdf.addPage(pw.MultiPage(
//       pageFormat: PdfPageFormat.a4,
//       margin: const pw.EdgeInsets.all(32),
//       header: (ctx) => pw.Column(
//         crossAxisAlignment: pw.CrossAxisAlignment.start,
//         children: [
//           pw.Row(
//             mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//             children: [
//               pw.Column(
//                 crossAxisAlignment: pw.CrossAxisAlignment.start,
//                 children: [
//                   pw.Text(gymName.toUpperCase(),
//                       style: pw.TextStyle(
//                           fontSize: 22,
//                           fontWeight: pw.FontWeight.bold,
//                           color: PdfColors.blueGrey800)),
//                   pw.Text('Strategic Owner Report',
//                       style: const pw.TextStyle(
//                           fontSize: 11, color: PdfColors.blueGrey400)),
//                 ],
//               ),
//               pw.Column(
//                 crossAxisAlignment: pw.CrossAxisAlignment.end,
//                 children: [
//                   pw.Text('Generated:', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
//                   pw.Text(fmt.format(now),
//                       style: pw.TextStyle(
//                           fontSize: 10,
//                           fontWeight: pw.FontWeight.bold,
//                           color: PdfColors.blueGrey700)),
//                 ],
//               ),
//             ],
//           ),
//           pw.Divider(color: PdfColors.blueGrey200, thickness: 1.5),
//           pw.SizedBox(height: 4),
//         ],
//       ),
//       footer: (ctx) => pw.Row(
//         mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//         children: [
//           pw.Text('CONFIDENTIAL — Owner Eyes Only',
//               style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
//           pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
//               style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
//         ],
//       ),
//       build: (ctx) => [
//         // ── KPI Summary Cards ──────────────────────────────────────────────
//         pw.Text('KEY PERFORMANCE INDICATORS',
//             style: pw.TextStyle(
//                 fontSize: 12,
//                 fontWeight: pw.FontWeight.bold,
//                 color: PdfColors.blueGrey700)),
//         pw.SizedBox(height: 10),
//         pw.GridView(
//           crossAxisCount: 3,
//           childAspectRatio: 2.2,
//           children: [
//             _pdfKpiCard('Total Revenue', 'Rs ${fmtNum.format(d.totalRevenue)}', PdfColors.teal700),
//             _pdfKpiCard('Cash Revenue',  'Rs ${fmtNum.format(d.cashRevenue)}',  PdfColors.green700),
//             _pdfKpiCard('Online Revenue','Rs ${fmtNum.format(d.onlineRevenue)}',PdfColors.blue700),
//             _pdfKpiCard('Total Members', '${d.totalMembers}',                  PdfColors.indigo700),
//             _pdfKpiCard('Active Members','${d.activeMembers}',                 PdfColors.cyan700),
//             _pdfKpiCard('Overdue Fees',  '${d.overdueMembers}',               PdfColors.red700),
//           ],
//         ),
//         pw.SizedBox(height: 20),

//         // ── Revenue by Month table ─────────────────────────────────────────
//         pw.Text('REVENUE BY MONTH',
//             style: pw.TextStyle(
//                 fontSize: 12,
//                 fontWeight: pw.FontWeight.bold,
//                 color: PdfColors.blueGrey700)),
//         pw.SizedBox(height: 8),
//         pw.Table(
//           border: pw.TableBorder.all(color: PdfColors.blueGrey100, width: 0.5),
//           columnWidths: const {
//             0: pw.FlexColumnWidth(2),
//             1: pw.FlexColumnWidth(3),
//           },
//           children: [
//             pw.TableRow(
//               decoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
//               children: [
//                 _pdfTh('Month'),
//                 _pdfTh('Revenue (Rs)'),
//               ],
//             ),
//             ...d.revenueByMonth.entries.map((e) => pw.TableRow(
//               children: [
//                 _pdfTd(e.key),
//                 _pdfTd(fmtNum.format(e.value)),
//               ],
//             )),
//             if (d.revenueByMonth.isEmpty)
//               pw.TableRow(children: [
//                 _pdfTd('—', span: true),
//                 _pdfTd(''),
//               ]),
//           ],
//         ),
//         pw.SizedBox(height: 20),

//         // ── Members by Plan ────────────────────────────────────────────────
//         pw.Text('MEMBERSHIP BREAKDOWN',
//             style: pw.TextStyle(
//                 fontSize: 12,
//                 fontWeight: pw.FontWeight.bold,
//                 color: PdfColors.blueGrey700)),
//         pw.SizedBox(height: 8),
//         pw.Table(
//           border: pw.TableBorder.all(color: PdfColors.blueGrey100, width: 0.5),
//           columnWidths: const {
//             0: pw.FlexColumnWidth(3),
//             1: pw.FlexColumnWidth(2),
//           },
//           children: [
//             pw.TableRow(
//               decoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
//               children: [_pdfTh('Plan'), _pdfTh('Members')],
//             ),
//             ...d.membersByPlan.entries.map((e) => pw.TableRow(children: [
//               _pdfTd(e.key),
//               _pdfTd('${e.value}'),
//             ])),
//           ],
//         ),
//         pw.SizedBox(height: 20),

//         // ── Attendance ─────────────────────────────────────────────────────
//         pw.Text('ATTENDANCE SUMMARY',
//             style: pw.TextStyle(
//                 fontSize: 12,
//                 fontWeight: pw.FontWeight.bold,
//                 color: PdfColors.blueGrey700)),
//         pw.SizedBox(height: 8),
//         pw.Table(
//           border: pw.TableBorder.all(color: PdfColors.blueGrey100, width: 0.5),
//           columnWidths: const {
//             0: pw.FlexColumnWidth(3),
//             1: pw.FlexColumnWidth(2),
//           },
//           children: [
//             pw.TableRow(
//               decoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
//               children: [_pdfTh('Period'), _pdfTh('Check-ins')],
//             ),
//             pw.TableRow(children: [_pdfTd("Today"),        _pdfTd('${d.todayAttendance}')]),
//             pw.TableRow(children: [_pdfTd("This Month"),   _pdfTd('${d.monthAttendance}')]),
//           ],
//         ),
//         pw.SizedBox(height: 20),

//         // ── Recent Payments ───────────────────────────────────────────────
//         pw.Text('RECENT TRANSACTIONS (last 20)',
//             style: pw.TextStyle(
//                 fontSize: 12,
//                 fontWeight: pw.FontWeight.bold,
//                 color: PdfColors.blueGrey700)),
//         pw.SizedBox(height: 8),
//         pw.Table(
//           border: pw.TableBorder.all(color: PdfColors.blueGrey100, width: 0.5),
//           columnWidths: const {
//             0: pw.FlexColumnWidth(3),
//             1: pw.FlexColumnWidth(2),
//             2: pw.FlexColumnWidth(2),
//             3: pw.FlexColumnWidth(2),
//           },
//           children: [
//             pw.TableRow(
//               decoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
//               children: [
//                 _pdfTh('Date'),
//                 _pdfTh('Amount (Rs)'),
//                 _pdfTh('Method'),
//                 _pdfTh('Status'),
//               ],
//             ),
//             ...d.recentPayments.take(20).map((p) {
//               final ts  = p['timestamp'] as Timestamp?;
//               final dt  = ts?.toDate();
//               final date = dt != null ? DateFormat('dd MMM yy').format(dt) : '—';
//               return pw.TableRow(children: [
//                 _pdfTd(date),
//                 _pdfTd(fmtNum.format((p['amount'] as num? ?? 0))),
//                 _pdfTd((p['method'] ?? '—').toString().toUpperCase()),
//                 _pdfTd((p['status']  ?? '—').toString().toUpperCase()),
//               ]);
//             }),
//           ],
//         ),
//       ],
//     ));

//     return pdf.save();
//   }

//   // ── PDF helper widgets ──────────────────────────────────────────────────────
//   static pw.Widget _pdfKpiCard(String label, String value, PdfColor color) =>
//       pw.Container(
//         margin: const pw.EdgeInsets.all(4),
//         padding: const pw.EdgeInsets.all(10),
//         decoration: pw.BoxDecoration(
//           color: color,
//           borderRadius: pw.BorderRadius.circular(6),
//         ),
//         child: pw.Column(
//           mainAxisAlignment: pw.MainAxisAlignment.center,
//           crossAxisAlignment: pw.CrossAxisAlignment.start,
//           children: [
//             pw.Text(value,
//                 style: pw.TextStyle(
//                     fontSize: 14,
//                     fontWeight: pw.FontWeight.bold,
//                     color: PdfColors.white)),
//             pw.SizedBox(height: 3),
//             pw.Text(label,
//                 style: const pw.TextStyle(fontSize: 8, color: PdfColors.white)),
//           ],
//         ),
//       );

//   static pw.Widget _pdfTh(String t) => pw.Padding(
//         padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//         child: pw.Text(t,
//             style: pw.TextStyle(
//                 fontSize: 9,
//                 fontWeight: pw.FontWeight.bold,
//                 color: PdfColors.blueGrey700)),
//       );

//   static pw.Widget _pdfTd(String t, {bool span = false}) => pw.Padding(
//         padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
//         child: pw.Text(t,
//             style: const pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey600)),
//       );

//   // ── Build ───────────────────────────────────────────────────────────────────
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: _navy,
//       appBar: _buildAppBar(),
//       body: _loading
//           ? _buildLoader()
//           : _error != null
//               ? _buildError()
//               : _buildBody(),
//     );
//   }

//   AppBar _buildAppBar() => AppBar(
//         backgroundColor: _navy,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new, color: _textPri, size: 18),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(widget.gymName.toUpperCase(),
//                 style: const TextStyle(
//                     color: _textPri,
//                     fontSize: 15,
//                     fontWeight: FontWeight.w800,
//                     letterSpacing: 1.4)),
//             const Text('Strategic Owner\'s Module',
//                 style: TextStyle(color: _textSec, fontSize: 10)),
//           ],
//         ),
//         actions: [
//           // History
//           IconButton(
//             tooltip: 'Report History',
//             icon: const Icon(Icons.history_rounded, color: _textSec),
//             onPressed: () => Navigator.push(context,
//                 MaterialPageRoute(
//                     builder: (_) =>
//                         ReportHistoryScreen(gymId: widget.gymId))),
//           ),
//           // PDF export
//           _generatingPdf
//               ? const Padding(
//                   padding: EdgeInsets.all(14),
//                   child: SizedBox(
//                       width: 20,
//                       height: 20,
//                       child: CircularProgressIndicator(
//                           strokeWidth: 2, color: _accent)))
//               : IconButton(
//                   tooltip: 'Export PDF',
//                   icon: const Icon(Icons.picture_as_pdf_rounded, color: _accent),
//                   onPressed: _generateAndSharePdf,
//                 ),
//           const SizedBox(width: 6),
//         ],
//         bottom: TabBar(
//           controller: _tab,
//           indicatorColor: _accent,
//           indicatorWeight: 2.5,
//           labelColor: _accent,
//           unselectedLabelColor: _textSec,
//           labelStyle:
//               const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8),
//           tabs: const [
//             Tab(text: 'OVERVIEW'),
//             Tab(text: 'REVENUE'),
//             Tab(text: 'MEMBERS'),
//           ],
//         ),
//       );

//   Widget _buildLoader() => const Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             CircularProgressIndicator(color: _accent, strokeWidth: 2),
//             SizedBox(height: 16),
//             Text('Loading analytics…', style: TextStyle(color: _textSec, fontSize: 13)),
//           ],
//         ),
//       );

//   Widget _buildError() => Center(
//         child: Padding(
//           padding: const EdgeInsets.all(32),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Icon(Icons.error_rounded, color: _rose, size: 48),
//               const SizedBox(height: 16),
//               Text('Failed to load analytics',
//                   style: const TextStyle(
//                       color: _textPri, fontSize: 16, fontWeight: FontWeight.bold)),
//               const SizedBox(height: 8),
//               Text(_error ?? '', style: const TextStyle(color: _textSec, fontSize: 12),
//                   textAlign: TextAlign.center),
//               const SizedBox(height: 24),
//               _accentButton('RETRY', _load),
//             ],
//           ),
//         ),
//       );

//   Widget _buildBody() => TabBarView(
//         controller: _tab,
//         children: [
//           _OverviewTab(data: _data!),
//           _RevenueTab(data: _data!),
//           _MembersTab(data: _data!),
//         ],
//       );

//   Widget _accentButton(String label, VoidCallback onTap) => GestureDetector(
//         onTap: onTap,
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
//           decoration: BoxDecoration(
//               color: _accent.withOpacity(0.15),
//               borderRadius: BorderRadius.circular(10),
//               border: Border.all(color: _accent.withOpacity(0.4))),
//           child: Text(label,
//               style: const TextStyle(
//                   color: _accent, fontSize: 13, fontWeight: FontWeight.w700)),
//         ),
//       );
// }

// // ─────────────────────────────────────────────────────────────────────────────
// //  OVERVIEW TAB
// // ─────────────────────────────────────────────────────────────────────────────
// class _OverviewTab extends StatelessWidget {
//   final _AnalyticsData data;
//   const _OverviewTab({required this.data});

//   @override
//   Widget build(BuildContext context) {
//     return RefreshIndicator(
//       onRefresh: () async {},
//       color: _accent,
//       child: SingleChildScrollView(
//         physics: const AlwaysScrollableScrollPhysics(),
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // ── Horizontal KPI strip ────────────────────────────────────────
//             _sectionLabel('KEY METRICS'),
//             const SizedBox(height: 10),
//             SizedBox(
//               height: 106,
//               child: ListView(
//                 scrollDirection: Axis.horizontal,
//                 children: [
//                   _KpiCard(label: 'Total Revenue',   value: 'Rs ${_fmt(data.totalRevenue)}',  icon: Icons.payments_rounded,     color: _green),
//                   _KpiCard(label: 'Cash In',         value: 'Rs ${_fmt(data.cashRevenue)}',   icon: Icons.money_rounded,        color: _amber),
//                   _KpiCard(label: 'Online In',       value: 'Rs ${_fmt(data.onlineRevenue)}', icon: Icons.mobile_friendly,      color: _accent),
//                   _KpiCard(label: 'Total Members',   value: '${data.totalMembers}',           icon: Icons.people_alt_rounded,   color: const Color(0xFFA78BFA)),
//                   _KpiCard(label: 'Active Members',  value: '${data.activeMembers}',          icon: Icons.verified_user_rounded,color: _green),
//                   _KpiCard(label: 'Overdue Fees',    value: '${data.overdueMembers}',         icon: Icons.warning_amber_rounded,color: _rose),
//                   _KpiCard(label: 'Today Visits',    value: '${data.todayAttendance}',        icon: Icons.door_front_door_rounded,color: _accent),
//                   _KpiCard(label: 'Month Visits',    value: '${data.monthAttendance}',        icon: Icons.calendar_month_rounded,color: _amber),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 24),

//             // ── Revenue bar chart ────────────────────────────────────────────
//             _sectionLabel('MONTHLY REVENUE'),
//             const SizedBox(height: 10),
//             _RevenueBarChart(data: data.revenueByMonth),
//             const SizedBox(height: 24),

//             // ── Health indicators ─────────────────────────────────────────────
//             _sectionLabel('GYM HEALTH'),
//             const SizedBox(height: 10),
//             _HealthCard(
//               activeRate: data.totalMembers == 0
//                   ? 0
//                   : (data.activeMembers / data.totalMembers * 100),
//               overdueRate: data.totalMembers == 0
//                   ? 0
//                   : (data.overdueMembers / data.totalMembers * 100),
//               cashShare: data.totalRevenue == 0
//                   ? 0
//                   : (data.cashRevenue / data.totalRevenue * 100),
//               onlineShare: data.totalRevenue == 0
//                   ? 0
//                   : (data.onlineRevenue / data.totalRevenue * 100),
//             ),
//             const SizedBox(height: 24),

//             // ── Recent Transactions ───────────────────────────────────────────
//             _sectionLabel('RECENT TRANSACTIONS'),
//             const SizedBox(height: 10),
//             ...data.recentPayments.take(8).map((p) => _PaymentRow(payment: p)),
//             const SizedBox(height: 16),
//           ],
//         ),
//       ),
//     );
//   }

//   String _fmt(double v) =>
//       NumberFormat('#,##0', 'en_US').format(v);

//   Widget _sectionLabel(String t) => Text(t,
//       style: const TextStyle(
//           color: _textSec, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5));
// }

// // ─────────────────────────────────────────────────────────────────────────────
// //  REVENUE TAB
// // ─────────────────────────────────────────────────────────────────────────────
// class _RevenueTab extends StatelessWidget {
//   final _AnalyticsData data;
//   const _RevenueTab({required this.data});

//   @override
//   Widget build(BuildContext context) {
//     final total = data.totalRevenue;
//     final cashPct = total == 0 ? 0.0 : data.cashRevenue / total;
//     final onlinePct = total == 0 ? 0.0 : data.onlineRevenue / total;

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // ── Split card ──────────────────────────────────────────────────
//           _card(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text('REVENUE SPLIT',
//                     style: TextStyle(
//                         color: _textSec, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
//                 const SizedBox(height: 16),
//                 _splitRow('Cash', data.cashRevenue, cashPct, _amber),
//                 const SizedBox(height: 12),
//                 _splitRow('Online (EP/JC)', data.onlineRevenue, onlinePct, _accent),
//                 const SizedBox(height: 16),
//                 const Divider(color: Colors.white12, height: 1),
//                 const SizedBox(height: 14),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Text('TOTAL', style: TextStyle(color: _textSec, fontSize: 11, fontWeight: FontWeight.w600)),
//                     Text('Rs ${NumberFormat('#,##0').format(total)}',
//                         style: const TextStyle(color: _green, fontSize: 18, fontWeight: FontWeight.w900)),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 16),

//           // ── By month ─────────────────────────────────────────────────────
//           _card(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text('BY MONTH',
//                     style: TextStyle(
//                         color: _textSec, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
//                 const SizedBox(height: 14),
//                 _RevenueBarChart(data: data.revenueByMonth),
//               ],
//             ),
//           ),
//           const SizedBox(height: 16),

//           // ── All transactions ──────────────────────────────────────────────
//           _card(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text('ALL TRANSACTIONS',
//                     style: TextStyle(
//                         color: _textSec, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
//                 const SizedBox(height: 12),
//                 ...data.recentPayments.map((p) => _PaymentRow(payment: p)),
//                 if (data.recentPayments.isEmpty)
//                   const Padding(
//                     padding: EdgeInsets.all(24),
//                     child: Center(
//                       child: Text('No transactions yet',
//                           style: TextStyle(color: _textSec)),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _splitRow(String label, double amount, double pct, Color color) => Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Row(children: [
//                 Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
//                 const SizedBox(width: 8),
//                 Text(label, style: const TextStyle(color: _textPri, fontSize: 13)),
//               ]),
//               Text('Rs ${NumberFormat('#,##0').format(amount)}',
//                   style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
//             ],
//           ),
//           const SizedBox(height: 6),
//           LinearProgressIndicator(
//             value: pct.clamp(0.0, 1.0),
//             backgroundColor: Colors.white10,
//             valueColor: AlwaysStoppedAnimation<Color>(color),
//             minHeight: 5,
//             borderRadius: BorderRadius.circular(4),
//           ),
//           const SizedBox(height: 2),
//           Text('${(pct * 100).toStringAsFixed(1)}%',
//               style: const TextStyle(color: _textSec, fontSize: 10)),
//         ],
//       );
// }

// // ─────────────────────────────────────────────────────────────────────────────
// //  MEMBERS TAB
// // ─────────────────────────────────────────────────────────────────────────────
// class _MembersTab extends StatelessWidget {
//   final _AnalyticsData data;
//   const _MembersTab({required this.data});

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // ── Status breakdown ────────────────────────────────────────────
//           Row(children: [
//             Expanded(child: _statBrick('Total', '${data.totalMembers}',       _accent,              Icons.people_alt_rounded)),
//             const SizedBox(width: 10),
//             Expanded(child: _statBrick('Active','${data.activeMembers}',      _green,               Icons.verified_user_rounded)),
//             const SizedBox(width: 10),
//             Expanded(child: _statBrick('Overdue','${data.overdueMembers}',    _rose,                Icons.warning_amber_rounded)),
//           ]),
//           const SizedBox(height: 16),

//           // ── Plan breakdown ───────────────────────────────────────────────
//           _card(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text('BY MEMBERSHIP PLAN',
//                     style: TextStyle(
//                         color: _textSec, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
//                 const SizedBox(height: 14),
//                 if (data.membersByPlan.isEmpty)
//                   const Center(child: Padding(
//                     padding: EdgeInsets.all(16),
//                     child: Text('No data', style: TextStyle(color: _textSec)),
//                   ))
//                 else
//                   ...data.membersByPlan.entries.map((e) {
//                     final pct = data.totalMembers == 0
//                         ? 0.0
//                         : e.value / data.totalMembers;
//                     return Padding(
//                       padding: const EdgeInsets.only(bottom: 14),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Text(e.key, style: const TextStyle(color: _textPri, fontSize: 13)),
//                               Text('${e.value} members',
//                                   style: const TextStyle(color: _textSec, fontSize: 12)),
//                             ],
//                           ),
//                           const SizedBox(height: 6),
//                           LinearProgressIndicator(
//                             value: pct.clamp(0.0, 1.0),
//                             backgroundColor: Colors.white10,
//                             valueColor: const AlwaysStoppedAnimation<Color>(_accent),
//                             minHeight: 5,
//                             borderRadius: BorderRadius.circular(4),
//                           ),
//                         ],
//                       ),
//                     );
//                   }),
//               ],
//             ),
//           ),
//           const SizedBox(height: 16),

//           // ── Attendance summary ─────────────────────────────────────────────
//           _card(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text('ATTENDANCE SNAPSHOT',
//                     style: TextStyle(
//                         color: _textSec, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
//                 const SizedBox(height: 16),
//                 Row(children: [
//                   Expanded(child: _attTile('Today', '${data.todayAttendance}', Icons.today_rounded)),
//                   const SizedBox(width: 12),
//                   Expanded(child: _attTile('This Month', '${data.monthAttendance}', Icons.calendar_today_rounded)),
//                 ]),
//               ],
//             ),
//           ),
//           const SizedBox(height: 16),

//           // ── Staff list ─────────────────────────────────────────────────────
//           _card(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Text('STAFF',
//                         style: TextStyle(
//                             color: _textSec, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
//                     Text('${data.staffList.length} members',
//                         style: const TextStyle(color: _textSec, fontSize: 10)),
//                   ],
//                 ),
//                 const SizedBox(height: 12),
//                 if (data.staffList.isEmpty)
//                   const Padding(
//                     padding: EdgeInsets.all(12),
//                     child: Center(
//                       child: Text('No staff assigned', style: TextStyle(color: _textSec)),
//                     ),
//                   )
//                 else
//                   ...data.staffList.map((s) => Padding(
//                         padding: const EdgeInsets.only(bottom: 10),
//                         child: Row(children: [
//                           CircleAvatar(
//                             radius: 18,
//                             backgroundColor: _accent.withOpacity(0.15),
//                             child: Text(
//                               (s['name'] as String? ?? '?')[0].toUpperCase(),
//                               style: const TextStyle(color: _accent, fontWeight: FontWeight.bold),
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(s['name'] ?? '—',
//                                     style: const TextStyle(
//                                         color: _textPri, fontSize: 13, fontWeight: FontWeight.w600)),
//                                 Text(s['email'] ?? '—',
//                                     style: const TextStyle(color: _textSec, fontSize: 11)),
//                               ],
//                             ),
//                           ),
//                           Container(
//                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//                             decoration: BoxDecoration(
//                               color: _accent.withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(6),
//                             ),
//                             child: const Text('STAFF',
//                                 style: TextStyle(color: _accent, fontSize: 9, fontWeight: FontWeight.bold)),
//                           ),
//                         ]),
//                       )),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _attTile(String label, String value, IconData icon) => Container(
//         padding: const EdgeInsets.all(14),
//         decoration: BoxDecoration(
//           color: Colors.white.withOpacity(0.04),
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: Colors.white10),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Icon(icon, color: _accent, size: 20),
//             const SizedBox(height: 8),
//             Text(value,
//                 style: const TextStyle(
//                     color: _textPri, fontSize: 22, fontWeight: FontWeight.w900)),
//             const SizedBox(height: 2),
//             Text(label, style: const TextStyle(color: _textSec, fontSize: 11)),
//           ],
//         ),
//       );

//   Widget _statBrick(String label, String value, Color color, IconData icon) =>
//       Container(
//         padding: const EdgeInsets.all(14),
//         decoration: BoxDecoration(
//           color: color.withOpacity(0.08),
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(color: color.withOpacity(0.2)),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Icon(icon, color: color, size: 18),
//             const SizedBox(height: 8),
//             Text(value,
//                 style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
//             const SizedBox(height: 2),
//             Text(label, style: const TextStyle(color: _textSec, fontSize: 10)),
//           ],
//         ),
//       );
// }

// // ─────────────────────────────────────────────────────────────────────────────
// //  SHARED SUB-WIDGETS
// // ─────────────────────────────────────────────────────────────────────────────
// class _KpiCard extends StatelessWidget {
//   final String label;
//   final String value;
//   final IconData icon;
//   final Color color;

//   const _KpiCard({
//     required this.label,
//     required this.value,
//     required this.icon,
//     required this.color,
//   });

//   @override
//   Widget build(BuildContext context) => Container(
//         width: 145,
//         margin: const EdgeInsets.only(right: 10),
//         padding: const EdgeInsets.all(14),
//         decoration: BoxDecoration(
//           color: _navyCard,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: color.withOpacity(0.25)),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, color: color, size: 20),
//             const SizedBox(height: 8),
//             Text(value,
//                 style: TextStyle(
//                     color: color, fontSize: 16, fontWeight: FontWeight.w900),
//                 overflow: TextOverflow.ellipsis),
//             const SizedBox(height: 3),
//             Text(label,
//                 style: const TextStyle(color: _textSec, fontSize: 10),
//                 overflow: TextOverflow.ellipsis),
//           ],
//         ),
//       );
// }

// class _RevenueBarChart extends StatelessWidget {
//   final Map<String, double> data;
//   const _RevenueBarChart({required this.data});

//   @override
//   Widget build(BuildContext context) {
//     if (data.isEmpty) {
//       return const SizedBox(
//         height: 120,
//         child: Center(child: Text('No revenue data', style: TextStyle(color: _textSec))),
//       );
//     }
//     final maxVal = data.values.reduce((a, b) => a > b ? a : b);
//     return SizedBox(
//       height: 140,
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.end,
//         children: data.entries.map((e) {
//           final barH = maxVal == 0 ? 0.0 : (e.value / maxVal) * 100;
//           return Expanded(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 3),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   Container(
//                     height: barH.clamp(4.0, 100.0),
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         begin: Alignment.bottomCenter,
//                         end: Alignment.topCenter,
//                         colors: [
//                           _accent.withOpacity(0.9),
//                           _accent.withOpacity(0.35),
//                         ],
//                       ),
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                   ),
//                   const SizedBox(height: 5),
//                   Text(e.key,
//                       style: const TextStyle(color: _textSec, fontSize: 9),
//                       overflow: TextOverflow.ellipsis),
//                 ],
//               ),
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }
// }

// class _HealthCard extends StatelessWidget {
//   final double activeRate;
//   final double overdueRate;
//   final double cashShare;
//   final double onlineShare;

//   const _HealthCard({
//     required this.activeRate,
//     required this.overdueRate,
//     required this.cashShare,
//     required this.onlineShare,
//   });

//   @override
//   Widget build(BuildContext context) => _card(
//         child: Column(
//           children: [
//             _healthRow('Active Member Rate', activeRate, _green),
//             const SizedBox(height: 10),
//             _healthRow('Overdue Fee Rate', overdueRate, _rose),
//             const SizedBox(height: 10),
//             _healthRow('Cash vs Online (Cash %)', cashShare, _amber),
//             const SizedBox(height: 10),
//             _healthRow('Online Collection %', onlineShare, _accent),
//           ],
//         ),
//       );

//   Widget _healthRow(String label, double pct, Color color) => Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(label, style: const TextStyle(color: _textPri, fontSize: 12)),
//               Text('${pct.toStringAsFixed(1)}%',
//                   style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
//             ],
//           ),
//           const SizedBox(height: 5),
//           LinearProgressIndicator(
//             value: (pct / 100).clamp(0.0, 1.0),
//             backgroundColor: Colors.white10,
//             valueColor: AlwaysStoppedAnimation<Color>(color),
//             minHeight: 4,
//             borderRadius: BorderRadius.circular(4),
//           ),
//         ],
//       );
// }

// class _PaymentRow extends StatelessWidget {
//   final Map<String, dynamic> payment;
//   const _PaymentRow({required this.payment});

//   @override
//   Widget build(BuildContext context) {
//     final amount = (payment['amount'] as num? ?? 0).toDouble();
//     final method = (payment['method'] ?? '').toString().toLowerCase();
//     final status = (payment['status'] ?? '').toString().toLowerCase();
//     final ts = payment['timestamp'] as Timestamp?;
//     final date = ts != null ? DateFormat('dd MMM yy').format(ts.toDate()) : '—';

//     final isOnline = method == 'easypaisa' || method == 'jazzcash';
//     final methodColor = isOnline ? _accent : _amber;
//     final statusColor = status == 'completed' || status == ''
//         ? _green
//         : status == 'pending'
//             ? _amber
//             : _rose;

//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.03),
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: Colors.white.withOpacity(0.06)),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 36,
//             height: 36,
//             decoration: BoxDecoration(
//               color: methodColor.withOpacity(0.12),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Icon(
//               isOnline ? Icons.contactless_rounded : Icons.account_balance_rounded,
//               color: methodColor,
//               size: 18,
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(method.toUpperCase().isEmpty ? 'CASH' : method.toUpperCase(),
//                     style: TextStyle(color: methodColor, fontSize: 11, fontWeight: FontWeight.w700)),
//                 Text(date, style: const TextStyle(color: _textSec, fontSize: 10)),
//               ],
//             ),
//           ),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               Text('Rs ${NumberFormat('#,##0').format(amount)}',
//                   style: const TextStyle(color: _textPri, fontSize: 13, fontWeight: FontWeight.w700)),
//               Container(
//                 margin: const EdgeInsets.only(top: 3),
//                 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                 decoration: BoxDecoration(
//                   color: statusColor.withOpacity(0.12),
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//                 child: Text(status.toUpperCase().isEmpty ? 'DONE' : status.toUpperCase(),
//                     style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold)),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ─── Helper ───────────────────────────────────────────────────────────────────
// Widget _card({required Widget child}) => Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       margin: const EdgeInsets.only(bottom: 0),
//       decoration: BoxDecoration(
//         color: _navyCard,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.white.withOpacity(0.07)),
//       ),
//       child: child,
//     );


// // lib/features/owner/analytics/owner_analytics_screen.dart
// //
// // PDF Flow:
// //   1. Build PDF bytes in memory (pdf package)
// //   2. Upload  → Firebase Storage  gym_reports/{gymId}/{fileName}
// //   3. Get permanent downloadUrl
// //   4. Save    → Firestore pos_reports_history  { downloadUrl, summary, … }
// //   5. Open    → url_launcher (externalApplication)  ← no MissingPluginException





// // import 'dart:typed_data';
// // import 'package:flutter/material.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:firebase_storage/firebase_storage.dart';
// // import 'package:intl/intl.dart';
// // import 'package:url_launcher/url_launcher.dart';
// // import 'package:pdf/pdf.dart';
// // import 'package:pdf/widgets.dart' as pw;

// // import 'report_history_screen.dart';
// // // ─── Palette ─────────────────────────────────────────────────────────────────
// // const _navy     = Color(0xFF0D1B2A);
// // const _navyCard = Color(0xFF112236);
// // const _accent   = Color(0xFF4FC3F7);
// // const _green    = Color(0xFF4ADE80);
// // const _amber    = Color(0xFFFBBF24);
// // const _rose     = Color(0xFFF87171);
// // const _textPri  = Color(0xFFE2E8F0);
// // const _textSec  = Color(0xFF94A3B8);

// // // ─── Model ───────────────────────────────────────────────────────────────────
// // class _D {
// //   final double totalRevenue, cashRevenue, onlineRevenue;
// //   final int    totalMembers, activeMembers, overdueMembers;
// //   final int    todayAtt, monthAtt;
// //   final Map<String, double> byMonth;
// //   final Map<String, int>    byPlan;
// //   final List<Map<String, dynamic>> payments, staff;
// //   const _D({
// //     required this.totalRevenue, required this.cashRevenue, required this.onlineRevenue,
// //     required this.totalMembers, required this.activeMembers, required this.overdueMembers,
// //     required this.todayAtt, required this.monthAtt,
// //     required this.byMonth, required this.byPlan,
// //     required this.payments, required this.staff,
// //   });
// // }

// // // ─── Screen ──────────────────────────────────────────────────────────────────
// // class OwnerAnalyticsScreen extends StatefulWidget {
// //   final String gymId, gymName;
// //   const OwnerAnalyticsScreen({super.key, required this.gymId, required this.gymName});
// //   @override State<OwnerAnalyticsScreen> createState() => _State();
// // }

// // class _State extends State<OwnerAnalyticsScreen> with SingleTickerProviderStateMixin {
// //   late TabController _tab;
// //   _D? _data;
// //   bool _loading = true, _uploading = false;
// //   String? _error;

// //   @override void initState() { super.initState(); _tab = TabController(length: 3, vsync: this); _load(); }
// //   @override void dispose()   { _tab.dispose(); super.dispose(); }

// //   // ── Load ────────────────────────────────────────────────────────────────────
// //   Future<void> _load() async {
// //     setState(() { _loading = true; _error = null; });
// //     try {
// //       final fs  = FirebaseFirestore.instance;
// //       final ref = fs.collection('gyms').doc(widget.gymId);
// //       final now = DateTime.now();
// //       final today = DateFormat('yyyy-MM-dd').format(now);
// //       final month = '${now.year}-${now.month.toString().padLeft(2,'0')}-01';

// //       final r = await Future.wait([
// //         ref.collection('payments').get(),
// //         ref.collection('members').get(),
// //         ref.collection('attendance').where('date', isEqualTo: today).get(),
// //         ref.collection('attendance').where('date', isGreaterThanOrEqualTo: month).get(),
// //         fs.collection('users').where('gymId', isEqualTo: widget.gymId).where('role', isEqualTo: 'staff').get(),
// //       ]);

// //       final pays  = r[0] as QuerySnapshot;
// //       final mems  = r[1] as QuerySnapshot;
// //       final tAtt  = r[2] as QuerySnapshot;
// //       final mAtt  = r[3] as QuerySnapshot;
// //       final staff = r[4] as QuerySnapshot;

// //       double total = 0, cash = 0, online = 0;
// //       final Map<String, double> byMonth = {};
// //       final List<Map<String, dynamic>> payList = [];

// //       for (final d in pays.docs) {
// //         final m = d.data() as Map<String, dynamic>;
// //         if ((m['status'] ?? '').toString().toLowerCase() == 'pending') continue;
// //         final amt = (m['amount'] as num? ?? 0).toDouble();
// //         final mtd = (m['method'] ?? '').toString().toLowerCase();
// //         total += amt;
// //         if (mtd == 'easypaisa' || mtd == 'jazzcash') online += amt; else cash += amt;
// //         final ts = m['timestamp'] as Timestamp?;
// //         if (ts != null) { final lbl = DateFormat('MMM').format(ts.toDate()); byMonth[lbl] = (byMonth[lbl] ?? 0) + amt; }
// //         payList.add(m);
// //       }
// //       payList.sort((a, b) {
// //         final ta = (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
// //         final tb = (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
// //         return tb.compareTo(ta);
// //       });

// //       int active = 0, overdue = 0;
// //       final Map<String, int> byPlan = {};
// //       for (final d in mems.docs) {
// //         final m  = d.data() as Map<String, dynamic>;
// //         final vu = (m['validUntil'] as Timestamp?)?.toDate();
// //         final fs = (m['feeStatus'] ?? 'unpaid').toString().toLowerCase();
// //         final pl = (m['plan'] ?? 'Monthly').toString();
// //         if (vu != null && vu.isAfter(now)) active++;
// //         if (fs == 'overdue' || fs == 'unpaid') overdue++;
// //         byPlan[pl] = (byPlan[pl] ?? 0) + 1;
// //       }

// //       setState(() {
// //         _data = _D(
// //           totalRevenue: total, cashRevenue: cash, onlineRevenue: online,
// //           totalMembers: mems.size, activeMembers: active, overdueMembers: overdue,
// //           todayAtt: tAtt.size, monthAtt: mAtt.size,
// //           byMonth: byMonth, byPlan: byPlan,
// //           payments: payList.take(50).toList(),
// //           staff: staff.docs.map((d) => {'uid': d.id, ...d.data() as Map<String, dynamic>}).toList(),
// //         );
// //         _loading = false;
// //       });
// //     } catch (e) { setState(() { _loading = false; _error = e.toString(); }); }
// //   }

// //   // ── Generate → Upload → Save → Open ─────────────────────────────────────────
// //   Future<void> _generate() async {
// //     if (_data == null) return;
// //     setState(() => _uploading = true);
// //     try {
// //       // 1. Build PDF bytes
// //       final bytes = await _buildPdf(_data!, widget.gymName);

// //       // 2. Upload to Firebase Storage
// //       final name = 'gym_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
// //       final ref  = FirebaseStorage.instance
// //           .ref('gym_reports/${widget.gymId}/$name');
// //       final task = await ref.putData(bytes, SettableMetadata(contentType: 'application/pdf'));

// //       // 3. Permanent download URL
// //       final url = await task.ref.getDownloadURL();

// //       // 4. Save to Firestore history
// //       await FirebaseFirestore.instance.collection('pos_reports_history').add({
// //         'gymId':       widget.gymId,
// //         'gymName':     widget.gymName,
// //         'adminId':     FirebaseAuth.instance.currentUser?.uid ?? '',
// //         'fileName':    name,
// //         'downloadUrl': url,
// //         'summary': {
// //           'totalRevenue':    _data!.totalRevenue,
// //           'cashRevenue':     _data!.cashRevenue,
// //           'onlineRevenue':   _data!.onlineRevenue,
// //           'totalMembers':    _data!.totalMembers,
// //           'activeMembers':   _data!.activeMembers,
// //           'overdueMembers':  _data!.overdueMembers,
// //           'todayAttendance': _data!.todayAtt,
// //           'monthAttendance': _data!.monthAtt,
// //         },
// //         'sortKey':     DateTime.now().toIso8601String(),
// //         'generatedAt': FieldValue.serverTimestamp(),
// //       });

// //       // 5. Open the PDF
// //       final uri = Uri.parse(url);
// //       if (await canLaunchUrl(uri)) {
// //         await launchUrl(uri, mode: LaunchMode.externalApplication);
// //       }

// //       if (mounted) _snack('✅ Saved to cloud & opened', const Color(0xFF166534));
// //     } catch (e) {
// //       if (mounted) _snack('Error: $e', _rose);
// //     } finally {
// //       if (mounted) setState(() => _uploading = false);
// //     }
// //   }

// //   void _snack(String msg, Color bg) => ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(content: Text(msg), backgroundColor: bg, behavior: SnackBarBehavior.floating));

// //   // ── PDF ─────────────────────────────────────────────────────────────────────
// //   static Future<Uint8List> _buildPdf(_D d, String gymName) async {
// //     final doc = pw.Document();
// //     final fmt = DateFormat('dd MMM yyyy, hh:mm a');
// //     final n   = NumberFormat('#,##0.00', 'en_US');

// //     doc.addPage(pw.MultiPage(
// //       pageFormat: PdfPageFormat.a4,
// //       margin: const pw.EdgeInsets.all(36),
// //       header: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
// //         pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
// //           pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
// //             pw.Text(gymName.toUpperCase(), style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
// //             pw.Text('Strategic Owner Report — CONFIDENTIAL', style: const pw.TextStyle(fontSize: 10, color: PdfColors.blueGrey500)),
// //           ]),
// //           pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
// //             pw.Text('Generated', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
// //             pw.Text(fmt.format(DateTime.now()), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey700)),
// //           ]),
// //         ]),
// //         pw.SizedBox(height: 6),
// //         pw.Divider(color: PdfColors.blueGrey200, thickness: 1.5),
// //         pw.SizedBox(height: 4),
// //       ]),
// //       footer: (c) => pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
// //         pw.Text('Owner Eyes Only', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
// //         pw.Text('Page ${c.pageNumber} / ${c.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
// //       ]),
// //       build: (_) => [
// //         _sec('KEY PERFORMANCE INDICATORS'), pw.SizedBox(height: 8),
// //         pw.GridView(crossAxisCount: 3, childAspectRatio: 2.4, children: [
// //           _kpi('Total Revenue',  'Rs ${n.format(d.totalRevenue)}',  PdfColors.teal700),
// //           _kpi('Cash Revenue',   'Rs ${n.format(d.cashRevenue)}',   PdfColors.green700),
// //           _kpi('Online Revenue', 'Rs ${n.format(d.onlineRevenue)}', PdfColors.blue700),
// //           _kpi('Total Members',  '${d.totalMembers}',               PdfColors.indigo700),
// //           _kpi('Active Members', '${d.activeMembers}',              PdfColors.cyan700),
// //           _kpi('Overdue Fees',   '${d.overdueMembers}',             PdfColors.red700),
// //         ]),
// //         pw.SizedBox(height: 20),
// //         _sec('REVENUE BY MONTH'), pw.SizedBox(height: 8),
// //         _tbl(['Month','Revenue (Rs)'], [2,3],
// //           d.byMonth.isEmpty ? [['—','—']] : d.byMonth.entries.map((e) => [e.key, n.format(e.value)]).toList()),
// //         pw.SizedBox(height: 20),
// //         _sec('MEMBERSHIP BREAKDOWN'), pw.SizedBox(height: 8),
// //         _tbl(['Plan','Members'], [3,2],
// //           d.byPlan.isEmpty ? [['—','0']] : d.byPlan.entries.map((e) => [e.key,'${e.value}']).toList()),
// //         pw.SizedBox(height: 20),
// //         _sec('ATTENDANCE'), pw.SizedBox(height: 8),
// //         _tbl(['Period','Check-ins'], [3,2], [['Today','${d.todayAtt}'],['This Month','${d.monthAtt}']]),
// //         pw.SizedBox(height: 20),
// //         _sec('RECENT TRANSACTIONS (last 20)'), pw.SizedBox(height: 8),
// //         _tbl(['Date','Amount (Rs)','Method','Status'], [3,2,2,2],
// //           d.payments.take(20).map((p) {
// //             final ts = p['timestamp'] as Timestamp?;
// //             final dt = ts != null ? DateFormat('dd MMM yy').format(ts.toDate()) : '—';
// //             return [dt, n.format((p['amount'] as num? ?? 0)), (p['method'] ?? '—').toString().toUpperCase(), (p['status'] ?? '—').toString().toUpperCase()];
// //           }).toList()),
// //       ],
// //     ));
// //     return doc.save();
// //   }

// //   static pw.Widget _sec(String t) => pw.Text(t, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey700));
// //   static pw.Widget _kpi(String l, String v, PdfColor c) => pw.Container(
// //     margin: const pw.EdgeInsets.all(3), padding: const pw.EdgeInsets.all(10),
// //     decoration: pw.BoxDecoration(color: c, borderRadius: pw.BorderRadius.circular(6)),
// //     child: pw.Column(mainAxisAlignment: pw.MainAxisAlignment.center, crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
// //       pw.Text(v, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
// //       pw.SizedBox(height: 3),
// //       pw.Text(l, style: const pw.TextStyle(fontSize: 8, color: PdfColors.white)),
// //     ]));
// //   static pw.Widget _tbl(List<String> hdr, List<int> w, List<List<String>> rows) {
// //     final cw = { for (int i = 0; i < w.length; i++) i: pw.FlexColumnWidth(w[i].toDouble()) };
// //     return pw.Table(
// //       border: pw.TableBorder.all(color: PdfColors.blueGrey100, width: 0.5), columnWidths: cw,
// //       children: [
// //         pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
// //           children: hdr.map((h) => pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
// //             child: pw.Text(h, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey700)))).toList()),
// //         ...rows.map((r) => pw.TableRow(children: r.map((c) => pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
// //           child: pw.Text(c, style: const pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey600)))).toList())),
// //       ]);
// //   }

// //   // ── Build ────────────────────────────────────────────────────────────────────
// //   @override
// //   Widget build(BuildContext context) => Scaffold(
// //     backgroundColor: _navy,
// //     appBar: AppBar(
// //       backgroundColor: _navy, elevation: 0,
// //       leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: _textPri, size: 18), onPressed: () => Navigator.pop(context)),
// //       title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
// //         Text(widget.gymName.toUpperCase(), style: const TextStyle(color: _textPri, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1.4)),
// //         const Text("Strategic Owner's Module", style: TextStyle(color: _textSec, fontSize: 10)),
// //       ]),
// //       actions: [
// //         IconButton(tooltip: 'Report History', icon: const Icon(Icons.history_rounded, color: _textSec),
// //           onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReportHistoryScreen(gymId: widget.gymId)))),
// //         _uploading
// //           ? const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _accent)))
// //           : IconButton(tooltip: 'Generate & Upload PDF', icon: const Icon(Icons.picture_as_pdf_rounded, color: _accent), onPressed: _generate),
// //         const SizedBox(width: 4),
// //       ],
// //       bottom: TabBar(controller: _tab, indicatorColor: _accent, indicatorWeight: 2.5, labelColor: _accent, unselectedLabelColor: _textSec,
// //         labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8),
// //         tabs: const [Tab(text: 'OVERVIEW'), Tab(text: 'REVENUE'), Tab(text: 'MEMBERS')]),
// //     ),
// //     body: _loading
// //       ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(color: _accent, strokeWidth: 2), SizedBox(height: 14), Text('Loading…', style: TextStyle(color: _textSec))]))
// //       : _error != null
// //         ? Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
// //             const Icon(Icons.error_rounded, color: _rose, size: 48), const SizedBox(height: 14),
// //             const Text('Failed to load', style: TextStyle(color: _textPri, fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
// //             Text(_error!, style: const TextStyle(color: _textSec, fontSize: 12), textAlign: TextAlign.center), const SizedBox(height: 20),
// //             TextButton(onPressed: _load, child: const Text('RETRY', style: TextStyle(color: _accent))),
// //           ])))
// //         : TabBarView(controller: _tab, children: [_OverviewTab(d: _data!), _RevenueTab(d: _data!), _MembersTab(d: _data!)]),
// //   );
// // }

// // // ─────────────────────────────────────────────────────────────────────────────
// // //  OVERVIEW TAB
// // // ─────────────────────────────────────────────────────────────────────────────
// // class _OverviewTab extends StatelessWidget {
// //   final _D d;
// //   const _OverviewTab({required this.d});
// //   String _f(double v) => NumberFormat('#,##0', 'en_US').format(v);

// //   @override
// //   Widget build(BuildContext context) => SingleChildScrollView(
// //     padding: const EdgeInsets.all(16),
// //     child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
// //       _lbl('KEY METRICS'), const SizedBox(height: 10),
// //       SizedBox(height: 106, child: ListView(scrollDirection: Axis.horizontal, children: [
// //         _Kpi('Total Revenue',  'Rs ${_f(d.totalRevenue)}',  Icons.payments_rounded,        _green),
// //         _Kpi('Cash In',        'Rs ${_f(d.cashRevenue)}',   Icons.money_rounded,           _amber),
// //         _Kpi('Online In',      'Rs ${_f(d.onlineRevenue)}', Icons.mobile_friendly,         _accent),
// //         _Kpi('Total Members',  '${d.totalMembers}',         Icons.people_alt_rounded,      const Color(0xFFA78BFA)),
// //         _Kpi('Active',         '${d.activeMembers}',        Icons.verified_user_rounded,   _green),
// //         _Kpi('Overdue',        '${d.overdueMembers}',       Icons.warning_amber_rounded,   _rose),
// //         _Kpi('Today Visits',   '${d.todayAtt}',             Icons.door_front_door_rounded, _accent),
// //         _Kpi('Month Visits',   '${d.monthAtt}',             Icons.calendar_month_rounded,  _amber),
// //       ])),
// //       const SizedBox(height: 24), _lbl('MONTHLY REVENUE'), const SizedBox(height: 10),
// //       _Bar(data: d.byMonth),
// //       const SizedBox(height: 24), _lbl('GYM HEALTH'), const SizedBox(height: 10),
// //       _Health(
// //         activeRate:  d.totalMembers == 0 ? 0 : d.activeMembers  / d.totalMembers * 100,
// //         overdueRate: d.totalMembers == 0 ? 0 : d.overdueMembers / d.totalMembers * 100,
// //         cashShare:   d.totalRevenue == 0 ? 0 : d.cashRevenue    / d.totalRevenue * 100,
// //         onlineShare: d.totalRevenue == 0 ? 0 : d.onlineRevenue  / d.totalRevenue * 100,
// //       ),
// //       const SizedBox(height: 24), _lbl('RECENT TRANSACTIONS'), const SizedBox(height: 10),
// //       ...d.payments.take(8).map((p) => _PayRow(p: p)),
// //     ]),
// //   );
// //   Widget _lbl(String t) => Text(t, style: const TextStyle(color: _textSec, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5));
// // }

// // // ─────────────────────────────────────────────────────────────────────────────
// // //  REVENUE TAB
// // // ─────────────────────────────────────────────────────────────────────────────
// // class _RevenueTab extends StatelessWidget {
// //   final _D d;
// //   const _RevenueTab({required this.d});
// //   @override
// //   Widget build(BuildContext context) {
// //     final fmt = NumberFormat('#,##0', 'en_US');
// //     final cashP   = d.totalRevenue == 0 ? 0.0 : d.cashRevenue   / d.totalRevenue;
// //     final onlineP = d.totalRevenue == 0 ? 0.0 : d.onlineRevenue / d.totalRevenue;
// //     return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
// //       _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
// //         const Text('REVENUE SPLIT', style: TextStyle(color: _textSec, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
// //         const SizedBox(height: 16),
// //         _split('Cash',             d.cashRevenue,   cashP,   _amber,  fmt),
// //         const SizedBox(height: 12),
// //         _split('Online (EP / JC)', d.onlineRevenue, onlineP, _accent, fmt),
// //         const SizedBox(height: 14),
// //         const Divider(color: Colors.white12, height: 1), const SizedBox(height: 12),
// //         Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
// //           const Text('TOTAL', style: TextStyle(color: _textSec, fontSize: 11, fontWeight: FontWeight.w600)),
// //           Text('Rs ${fmt.format(d.totalRevenue)}', style: const TextStyle(color: _green, fontSize: 18, fontWeight: FontWeight.w900)),
// //         ]),
// //       ])),
// //       const SizedBox(height: 14),
// //       _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
// //         const Text('BY MONTH', style: TextStyle(color: _textSec, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
// //         const SizedBox(height: 12), _Bar(data: d.byMonth),
// //       ])),
// //       const SizedBox(height: 14),
// //       _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
// //         const Text('ALL TRANSACTIONS', style: TextStyle(color: _textSec, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
// //         const SizedBox(height: 10),
// //         ...d.payments.map((p) => _PayRow(p: p)),
// //         if (d.payments.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No transactions', style: TextStyle(color: _textSec)))),
// //       ])),
// //     ]));
// //   }
// //   Widget _split(String lbl, double amt, double pct, Color c, NumberFormat fmt) =>
// //     Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
// //       Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
// //         Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)), const SizedBox(width: 8), Text(lbl, style: const TextStyle(color: _textPri, fontSize: 13))]),
// //         Text('Rs ${fmt.format(amt)}', style: TextStyle(color: c, fontSize: 13, fontWeight: FontWeight.w700)),
// //       ]),
// //       const SizedBox(height: 6),
// //       LinearProgressIndicator(value: pct.clamp(0.0,1.0), backgroundColor: Colors.white10, valueColor: AlwaysStoppedAnimation<Color>(c), minHeight: 5, borderRadius: BorderRadius.circular(4)),
// //       const SizedBox(height: 2),
// //       Text('${(pct*100).toStringAsFixed(1)}%', style: const TextStyle(color: _textSec, fontSize: 10)),
// //     ]);
// // }

// // // ─────────────────────────────────────────────────────────────────────────────
// // //  MEMBERS TAB
// // // ─────────────────────────────────────────────────────────────────────────────
// // class _MembersTab extends StatelessWidget {
// //   final _D d;
// //   const _MembersTab({required this.d});
// //   @override
// //   Widget build(BuildContext context) => SingleChildScrollView(
// //     padding: const EdgeInsets.all(16),
// //     child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
// //       Row(children: [
// //         Expanded(child: _Brick('Total',  '${d.totalMembers}',  _accent, Icons.people_alt_rounded)),
// //         const SizedBox(width: 10),
// //         Expanded(child: _Brick('Active', '${d.activeMembers}', _green,  Icons.verified_user_rounded)),
// //         const SizedBox(width: 10),
// //         Expanded(child: _Brick('Overdue','${d.overdueMembers}',_rose,   Icons.warning_amber_rounded)),
// //       ]),
// //       const SizedBox(height: 14),
// //       _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
// //         const Text('BY PLAN', style: TextStyle(color: _textSec, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
// //         const SizedBox(height: 12),
// //         if (d.byPlan.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(14), child: Text('No data', style: TextStyle(color: _textSec))))
// //         else ...d.byPlan.entries.map((e) {
// //           final pct = d.totalMembers == 0 ? 0.0 : e.value / d.totalMembers;
// //           return Padding(padding: const EdgeInsets.only(bottom: 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
// //             Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
// //               Text(e.key, style: const TextStyle(color: _textPri, fontSize: 13)),
// //               Text('${e.value} members', style: const TextStyle(color: _textSec, fontSize: 12)),
// //             ]),
// //             const SizedBox(height: 6),
// //             LinearProgressIndicator(value: pct.clamp(0.0,1.0), backgroundColor: Colors.white10, valueColor: const AlwaysStoppedAnimation<Color>(_accent), minHeight: 5, borderRadius: BorderRadius.circular(4)),
// //           ]));
// //         }),
// //       ])),
// //       const SizedBox(height: 14),
// //       _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
// //         const Text('ATTENDANCE', style: TextStyle(color: _textSec, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
// //         const SizedBox(height: 14),
// //         Row(children: [
// //           Expanded(child: _AttTile('Today',      '${d.todayAtt}', Icons.today_rounded)),
// //           const SizedBox(width: 12),
// //           Expanded(child: _AttTile('This Month', '${d.monthAtt}', Icons.calendar_today_rounded)),
// //         ]),
// //       ])),
// //       const SizedBox(height: 14),
// //       _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
// //         Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
// //           const Text('STAFF', style: TextStyle(color: _textSec, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
// //           Text('${d.staff.length} assigned', style: const TextStyle(color: _textSec, fontSize: 10)),
// //         ]),
// //         const SizedBox(height: 12),
// //         if (d.staff.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(12), child: Text('No staff assigned', style: TextStyle(color: _textSec))))
// //         else ...d.staff.map((s) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [
// //           CircleAvatar(radius: 18, backgroundColor: _accent.withOpacity(0.15),
// //             child: Text((s['name'] as String? ?? '?')[0].toUpperCase(), style: const TextStyle(color: _accent, fontWeight: FontWeight.bold))),
// //           const SizedBox(width: 12),
// //           Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
// //             Text(s['name'] ?? '—', style: const TextStyle(color: _textPri, fontSize: 13, fontWeight: FontWeight.w600)),
// //             Text(s['email'] ?? '—', style: const TextStyle(color: _textSec, fontSize: 11)),
// //           ])),
// //           Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
// //             decoration: BoxDecoration(color: _accent.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
// //             child: const Text('STAFF', style: TextStyle(color: _accent, fontSize: 9, fontWeight: FontWeight.bold))),
// //         ]))),
// //       ])),
// //     ]),
// //   );
// // }

// // // ─── Atoms ────────────────────────────────────────────────────────────────────
// // class _Kpi extends StatelessWidget {
// //   final String l, v; final IconData i; final Color c;
// //   const _Kpi(this.l, this.v, this.i, this.c);
// //   @override
// //   Widget build(BuildContext context) => Container(
// //     width: 145, margin: const EdgeInsets.only(right: 10), padding: const EdgeInsets.all(14),
// //     decoration: BoxDecoration(color: _navyCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.withOpacity(0.25))),
// //     child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
// //       Icon(i, color: c, size: 20), const SizedBox(height: 8),
// //       Text(v, style: TextStyle(color: c, fontSize: 16, fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis),
// //       const SizedBox(height: 3),
// //       Text(l, style: const TextStyle(color: _textSec, fontSize: 10), overflow: TextOverflow.ellipsis),
// //     ]));
// // }

// // class _Bar extends StatelessWidget {
// //   final Map<String, double> data;
// //   const _Bar({required this.data});
// //   @override
// //   Widget build(BuildContext context) {
// //     if (data.isEmpty) return const SizedBox(height: 100, child: Center(child: Text('No revenue data yet', style: TextStyle(color: _textSec))));
// //     final mx = data.values.reduce((a, b) => a > b ? a : b);
// //     return SizedBox(height: 140, child: Row(crossAxisAlignment: CrossAxisAlignment.end,
// //       children: data.entries.map((e) {
// //         final h = mx == 0 ? 0.0 : (e.value / mx) * 100;
// //         return Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3),
// //           child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
// //             Container(height: h.clamp(4.0, 100.0), decoration: BoxDecoration(
// //               gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter,
// //                 colors: [_accent.withOpacity(0.9), _accent.withOpacity(0.3)]), borderRadius: BorderRadius.circular(4))),
// //             const SizedBox(height: 5),
// //             Text(e.key, style: const TextStyle(color: _textSec, fontSize: 9), overflow: TextOverflow.ellipsis),
// //           ])));
// //       }).toList()));
// //   }
// // }

// // class _Health extends StatelessWidget {
// //   final double activeRate, overdueRate, cashShare, onlineShare;
// //   const _Health({required this.activeRate, required this.overdueRate, required this.cashShare, required this.onlineShare});
// //   @override
// //   Widget build(BuildContext context) => _card(child: Column(children: [
// //     _r('Active Member Rate',  activeRate,  _green),  const SizedBox(height: 10),
// //     _r('Overdue Fee Rate',    overdueRate, _rose),   const SizedBox(height: 10),
// //     _r('Cash Collection %',  cashShare,   _amber),  const SizedBox(height: 10),
// //     _r('Online Collection %',onlineShare, _accent),
// //   ]));
// //   Widget _r(String l, double p, Color c) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
// //     Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
// //       Text(l, style: const TextStyle(color: _textPri, fontSize: 12)),
// //       Text('${p.toStringAsFixed(1)}%', style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w700)),
// //     ]),
// //     const SizedBox(height: 5),
// //     LinearProgressIndicator(value: (p/100).clamp(0.0,1.0), backgroundColor: Colors.white10, valueColor: AlwaysStoppedAnimation<Color>(c), minHeight: 4, borderRadius: BorderRadius.circular(4)),
// //   ]);
// // }

// // class _Brick extends StatelessWidget {
// //   final String l, v; final Color c; final IconData i;
// //   const _Brick(this.l, this.v, this.c, this.i);
// //   @override
// //   Widget build(BuildContext context) => Container(
// //     padding: const EdgeInsets.all(14),
// //     decoration: BoxDecoration(color: c.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: c.withOpacity(0.2))),
// //     child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
// //       Icon(i, color: c, size: 18), const SizedBox(height: 8),
// //       Text(v, style: TextStyle(color: c, fontSize: 22, fontWeight: FontWeight.w900)),
// //       const SizedBox(height: 2), Text(l, style: const TextStyle(color: _textSec, fontSize: 10)),
// //     ]));
// // }

// // class _AttTile extends StatelessWidget {
// //   final String l, v; final IconData i;
// //   const _AttTile(this.l, this.v, this.i);
// //   @override
// //   Widget build(BuildContext context) => Container(
// //     padding: const EdgeInsets.all(14),
// //     decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
// //     child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
// //       Icon(i, color: _accent, size: 20), const SizedBox(height: 8),
// //       Text(v, style: const TextStyle(color: _textPri, fontSize: 22, fontWeight: FontWeight.w900)),
// //       const SizedBox(height: 2), Text(l, style: const TextStyle(color: _textSec, fontSize: 11)),
// //     ]));
// // }

// // class _PayRow extends StatelessWidget {
// //   final Map<String, dynamic> p;
// //   const _PayRow({required this.p});
// //   @override
// //   Widget build(BuildContext context) {
// //     final amt   = (p['amount'] as num? ?? 0).toDouble();
// //     final mtd   = (p['method'] ?? '').toString().toLowerCase();
// //     final sts   = (p['status'] ?? '').toString().toLowerCase();
// //     final ts    = p['timestamp'] as Timestamp?;
// //     final date  = ts != null ? DateFormat('dd MMM yy').format(ts.toDate()) : '—';
// //     final isO   = mtd == 'easypaisa' || mtd == 'jazzcash';
// //     final mc    = isO ? _accent : _amber;
// //     final sc    = sts == 'completed' || sts == '' ? _green : sts == 'pending' ? _amber : _rose;
// //     return Container(
// //       margin: const EdgeInsets.only(bottom: 8),
// //       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
// //       decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withOpacity(0.06))),
// //       child: Row(children: [
// //         Container(width: 36, height: 36, decoration: BoxDecoration(color: mc.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
// //           child: Icon(isO ? Icons.mobile_friendly : Icons.money_rounded, color: mc, size: 18)),
// //         const SizedBox(width: 12),
// //         Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
// //           Text(mtd.isEmpty ? 'CASH' : mtd.toUpperCase(), style: TextStyle(color: mc, fontSize: 11, fontWeight: FontWeight.w700)),
// //           Text(date, style: const TextStyle(color: _textSec, fontSize: 10)),
// //         ])),
// //         Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
// //           Text('Rs ${NumberFormat('#,##0').format(amt)}', style: const TextStyle(color: _textPri, fontSize: 13, fontWeight: FontWeight.w700)),
// //           Container(margin: const EdgeInsets.only(top: 3), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
// //             decoration: BoxDecoration(color: sc.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
// //             child: Text(sts.isEmpty ? 'DONE' : sts.toUpperCase(), style: TextStyle(color: sc, fontSize: 9, fontWeight: FontWeight.bold))),
// //         ]),
// //       ]),
// //     );
// //   }
// // }

// // Widget _card({required Widget child}) => Container(
// //   width: double.infinity, padding: const EdgeInsets.all(16),
// //   decoration: BoxDecoration(color: _navyCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.07))),
// //   child: child);



// ============================================================================
//  lib/features/owner/analytics/owner_analytics_screen.dart
//
//  Strategic Owner's Module — Deep Navy / Slate palette
//
//  PDF Flow (MERGED):
//    1. Build PDF bytes in memory (pdf package)
//    2. Upload  → Firebase Storage  gym_reports/{gymId}/{fileName}
//    3. Get permanent downloadUrl
//    4. Save    → Firestore pos_reports_history { downloadUrl, summary, … }
//    5. Share   → Printing.sharePdf()  (local share sheet / download)
//    6. Open    → url_launcher (externalApplication)  ← permanent cloud link
//
//  Required pubspec.yaml deps:
//    pdf: ^3.x
//    printing: ^5.x
//    firebase_storage: ^11.x
//    url_launcher: ^6.x
// ============================================================================

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import 'report_history_screen.dart';

// ─── Palette ─────────────────────────────────────────────────────────────────
const _navy     = Color(0xFF000000);
const _navyCard = Color(0xFF1A1A1A);
const _slate    = Color(0xFF2A2A2A);
const _accent   = Color(0xFFFFFF00);
const _green    = Color(0xFF4ADE80);
const _amber    = Color(0xFFFBBF24);
const _rose     = Color(0xFFF87171);
const _textPri  = Color(0xFFE2E8F0);
const _textSec  = Color(0xFF9E9E9E);

// ─── Model ───────────────────────────────────────────────────────────────────
class _AnalyticsData {
  final double totalRevenue;
  final double cashRevenue;
  final double onlineRevenue;
  final int    totalMembers;
  final int    activeMembers;
  final int    overdueMembers;
  final int    todayAttendance;
  final int    monthAttendance;
  final Map<String, double> revenueByMonth;
  final Map<String, int>    membersByPlan;
  final List<Map<String, dynamic>> recentPayments;
  final List<Map<String, dynamic>> staffList;

  const _AnalyticsData({
    required this.totalRevenue,
    required this.cashRevenue,
    required this.onlineRevenue,
    required this.totalMembers,
    required this.activeMembers,
    required this.overdueMembers,
    required this.todayAttendance,
    required this.monthAttendance,
    required this.revenueByMonth,
    required this.membersByPlan,
    required this.recentPayments,
    required this.staffList,
  });
}

// ─── Entry point ─────────────────────────────────────────────────────────────
class OwnerAnalyticsScreen extends StatefulWidget {
  final String gymId;
  final String gymName;

  const OwnerAnalyticsScreen({
    super.key,
    required this.gymId,
    required this.gymName,
  });

  @override
  State<OwnerAnalyticsScreen> createState() => _OwnerAnalyticsScreenState();
}

class _OwnerAnalyticsScreenState extends State<OwnerAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  _AnalyticsData? _data;
  bool _loading = true;
  bool _generatingPdf = false;
  String? _error;

  // Track upload progress for UI feedback
  double _uploadProgress = 0;
  String _pdfStatus = '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ── Data Layer ──────────────────────────────────────────────────────────────
  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final fs = FirebaseFirestore.instance;
      final gymRef = fs.collection('gyms').doc(widget.gymId);
      final now = DateTime.now();
      final todayKey =
          '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';

      final results = await Future.wait([
        gymRef.collection('payments').get(),
        gymRef.collection('members').get(),
        gymRef.collection('attendance')
            .where('date', isEqualTo: todayKey).get(),
        gymRef.collection('attendance')
            .where('date', isGreaterThanOrEqualTo:
                '${now.year}-${now.month.toString().padLeft(2,'0')}-01').get(),
        fs.collection('users')
            .where('gymId', isEqualTo: widget.gymId)
            .where('role', isEqualTo: 'staff').get(),
      ]);

      final paymentsSnap  = results[0] as QuerySnapshot;
      final membersSnap   = results[1] as QuerySnapshot;
      final todayAttSnap  = results[2] as QuerySnapshot;
      final monthAttSnap  = results[3] as QuerySnapshot;
      final staffSnap     = results[4] as QuerySnapshot;

      // Revenue aggregation
      double total = 0, cash = 0, online = 0;
      final Map<String, double> byMonth = {};
      final List<Map<String, dynamic>> recentPay = [];

      for (final doc in paymentsSnap.docs) {
        final d = doc.data() as Map<String, dynamic>;
        final status = (d['status'] ?? '').toString().toLowerCase();
        if (status == 'pending') continue;

        final amount = (d['amount'] as num? ?? 0).toDouble();
        final method = (d['method'] ?? '').toString().toLowerCase();
        total += amount;
        if (method == 'easypaisa' || method == 'jazzcash') {
          online += amount;
        } else {
          cash += amount;
        }

        final ts = d['timestamp'] as Timestamp?;
        if (ts != null) {
          final dt = ts.toDate();
          final label = DateFormat('MMM').format(dt);
          byMonth[label] = (byMonth[label] ?? 0) + amount;
        }
        recentPay.add(d);
      }

      recentPay.sort((a, b) {
        final ta = (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
        final tb = (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
        return tb.compareTo(ta);
      });

      // Member aggregation
      int active = 0, overdue = 0;
      final Map<String, int> byPlan = {};

      for (final doc in membersSnap.docs) {
        final d = doc.data() as Map<String, dynamic>;
        final validUntil = (d['validUntil'] as Timestamp?)?.toDate();
        final feeStatus  = (d['feeStatus'] ?? 'unpaid').toString().toLowerCase();
        final plan       = (d['plan'] ?? 'Monthly').toString();

        if (validUntil != null && validUntil.isAfter(now)) active++;
        if (feeStatus == 'overdue' || feeStatus == 'unpaid') overdue++;
        byPlan[plan] = (byPlan[plan] ?? 0) + 1;
      }

      final staff = staffSnap.docs
          .map((d) => {'uid': d.id, ...d.data() as Map<String, dynamic>})
          .toList();

      setState(() {
        _data = _AnalyticsData(
          totalRevenue:    total,
          cashRevenue:     cash,
          onlineRevenue:   online,
          totalMembers:    membersSnap.size,
          activeMembers:   active,
          overdueMembers:  overdue,
          todayAttendance: todayAttSnap.size,
          monthAttendance: monthAttSnap.size,
          revenueByMonth:  byMonth,
          membersByPlan:   byPlan,
          recentPayments:  recentPay.take(50).toList(),
          staffList:       staff,
        );
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  // ── PDF: Build → Upload → Save → Share & Open ───────────────────────────────
  Future<void> _generatePdf() async {
    if (_data == null) return;
    setState(() {
      _generatingPdf = true;
      _uploadProgress = 0;
      _pdfStatus = 'Building PDF…';
    });

    try {
      // Step 1 — Build PDF bytes
      final bytes = await _buildPdf(_data!, widget.gymName);

      // Step 2 — Upload to Firebase Storage
      final fileName =
          'gym_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final storageRef = FirebaseStorage.instance
          .ref('gym_reports/${widget.gymId}/$fileName');

      setState(() => _pdfStatus = 'Uploading to cloud…');
      final uploadTask = storageRef.putData(
        bytes,
        SettableMetadata(contentType: 'application/pdf'),
      );

      // Track upload progress
      uploadTask.snapshotEvents.listen((snap) {
        if (snap.totalBytes > 0) {
          setState(() =>
              _uploadProgress = snap.bytesTransferred / snap.totalBytes);
        }
      });

      final taskSnapshot = await uploadTask;

      // Step 3 — Get permanent download URL
      setState(() => _pdfStatus = 'Saving record…');
      final downloadUrl = await taskSnapshot.ref.getDownloadURL();

      // Step 4 — Save to Firestore history with downloadUrl
      await _saveReportToFirestore(downloadUrl: downloadUrl, fileName: fileName);

      setState(() => _pdfStatus = 'Done! Opening share sheet…');

      // Step 5 — Local share / download via Printing
      await Printing.sharePdf(
        bytes: bytes,
        filename: fileName,
      );

      // Step 6 — Also open the cloud URL so they have a permanent link
      final uri = Uri.parse(downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      _snack('✅ PDF saved to cloud & shared!', const Color(0xFF166534));
    } catch (e) {
      if (mounted) _snack('PDF error: $e', _rose);
    } finally {
      if (mounted) {
        setState(() {
          _generatingPdf = false;
          _uploadProgress = 0;
          _pdfStatus = '';
        });
      }
    }
  }

  Future<void> _saveReportToFirestore({
    required String downloadUrl,
    required String fileName,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    await FirebaseFirestore.instance
        .collection('pos_reports_history')
        .add({
      'gymId':       widget.gymId,
      'gymName':     widget.gymName,
      'adminId':     uid,
      'fileName':    fileName,
      'downloadUrl': downloadUrl,           // ← permanent cloud link
      'summary': {
        'totalRevenue':    _data!.totalRevenue,
        'cashRevenue':     _data!.cashRevenue,
        'onlineRevenue':   _data!.onlineRevenue,
        'totalMembers':    _data!.totalMembers,
        'activeMembers':   _data!.activeMembers,
        'overdueMembers':  _data!.overdueMembers,
        'todayAttendance': _data!.todayAttendance,
        'monthAttendance': _data!.monthAttendance,
      },
      'sortKey':     DateTime.now().toIso8601String(),
      'generatedAt': FieldValue.serverTimestamp(),
    });
  }

  void _snack(String msg, Color bg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── PDF Builder ─────────────────────────────────────────────────────────────
  static Future<Uint8List> _buildPdf(_AnalyticsData d, String gymName) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final fmt = DateFormat('dd MMM yyyy, hh:mm a');
    final fmtNum = NumberFormat('#,##0.00', 'en_US');

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(gymName.toUpperCase(),
                      style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey800)),
                  pw.Text('Strategic Owner Report — CONFIDENTIAL',
                      style: const pw.TextStyle(
                          fontSize: 11, color: PdfColors.blueGrey400)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Generated:',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
                  pw.Text(fmt.format(now),
                      style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey700)),
                ],
              ),
            ],
          ),
          pw.Divider(color: PdfColors.blueGrey200, thickness: 1.5),
          pw.SizedBox(height: 4),
        ],
      ),
      footer: (ctx) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('CONFIDENTIAL — Owner Eyes Only',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
          pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
        ],
      ),
      build: (ctx) => [
        // ── KPI Summary Cards ──────────────────────────────────────────────
        pw.Text('KEY PERFORMANCE INDICATORS',
            style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey700)),
        pw.SizedBox(height: 10),
        pw.GridView(
          crossAxisCount: 3,
          childAspectRatio: 2.2,
          children: [
            _pdfKpiCard('Total Revenue',  'Rs ${fmtNum.format(d.totalRevenue)}',  PdfColors.teal700),
            _pdfKpiCard('Cash Revenue',   'Rs ${fmtNum.format(d.cashRevenue)}',   PdfColors.green700),
            _pdfKpiCard('Online Revenue', 'Rs ${fmtNum.format(d.onlineRevenue)}', PdfColors.blue700),
            _pdfKpiCard('Total Members',  '${d.totalMembers}',                    PdfColors.indigo700),
            _pdfKpiCard('Active Members', '${d.activeMembers}',                   PdfColors.cyan700),
            _pdfKpiCard('Overdue Fees',   '${d.overdueMembers}',                  PdfColors.red700),
          ],
        ),
        pw.SizedBox(height: 20),

        // ── Revenue by Month ───────────────────────────────────────────────
        pw.Text('REVENUE BY MONTH',
            style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey700)),
        pw.SizedBox(height: 8),
        _pdfTable(
          headers: ['Month', 'Revenue (Rs)'],
          flexes: [2, 3],
          rows: d.revenueByMonth.isEmpty
              ? [['—', '—']]
              : d.revenueByMonth.entries
                  .map((e) => [e.key, fmtNum.format(e.value)])
                  .toList(),
        ),
        pw.SizedBox(height: 20),

        // ── Members by Plan ────────────────────────────────────────────────
        pw.Text('MEMBERSHIP BREAKDOWN',
            style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey700)),
        pw.SizedBox(height: 8),
        _pdfTable(
          headers: ['Plan', 'Members'],
          flexes: [3, 2],
          rows: d.membersByPlan.isEmpty
              ? [['—', '0']]
              : d.membersByPlan.entries
                  .map((e) => [e.key, '${e.value}'])
                  .toList(),
        ),
        pw.SizedBox(height: 20),

        // ── Attendance ─────────────────────────────────────────────────────
        pw.Text('ATTENDANCE SUMMARY',
            style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey700)),
        pw.SizedBox(height: 8),
        _pdfTable(
          headers: ['Period', 'Check-ins'],
          flexes: [3, 2],
          rows: [
            ['Today',      '${d.todayAttendance}'],
            ['This Month', '${d.monthAttendance}'],
          ],
        ),
        pw.SizedBox(height: 20),

        // ── Recent Payments ────────────────────────────────────────────────
        pw.Text('RECENT TRANSACTIONS (last 20)',
            style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey700)),
        pw.SizedBox(height: 8),
        _pdfTable(
          headers: ['Date', 'Amount (Rs)', 'Method', 'Status'],
          flexes: [3, 2, 2, 2],
          rows: d.recentPayments.take(20).map((p) {
            final ts   = p['timestamp'] as Timestamp?;
            final dt   = ts?.toDate();
            final date = dt != null ? DateFormat('dd MMM yy').format(dt) : '—';
            return [
              date,
              fmtNum.format((p['amount'] as num? ?? 0)),
              (p['method'] ?? '—').toString().toUpperCase(),
              (p['status']  ?? '—').toString().toUpperCase(),
            ];
          }).toList(),
        ),
      ],
    ));

    return pdf.save();
  }

  // ── PDF helpers ─────────────────────────────────────────────────────────────
  static pw.Widget _pdfKpiCard(String label, String value, PdfColor color) =>
      pw.Container(
        margin: const pw.EdgeInsets.all(4),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: color,
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white)),
            pw.SizedBox(height: 3),
            pw.Text(label,
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.white)),
          ],
        ),
      );

  /// Reusable PDF table builder (cleaner than the original per-case version)
  static pw.Widget _pdfTable({
    required List<String> headers,
    required List<int> flexes,
    required List<List<String>> rows,
  }) {
    final colWidths = {
      for (int i = 0; i < flexes.length; i++)
        i: pw.FlexColumnWidth(flexes[i].toDouble())
    };
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.blueGrey100, width: 0.5),
      columnWidths: colWidths,
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
          children: headers
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    child: pw.Text(h,
                        style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blueGrey700)),
                  ))
              .toList(),
        ),
        // Data rows
        ...rows.map((row) => pw.TableRow(
              children: row
                  .map((cell) => pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        child: pw.Text(cell,
                            style: const pw.TextStyle(
                                fontSize: 9,
                                color: PdfColors.blueGrey600)),
                      ))
                  .toList(),
            )),
      ],
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      appBar: _buildAppBar(),
      body: _loading
          ? _buildLoader()
          : _error != null
              ? _buildError()
              : _buildBody(),
    );
  }

  AppBar _buildAppBar() => AppBar(
        backgroundColor: _navy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _textPri, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.gymName.toUpperCase(),
                style: const TextStyle(
                    color: _textPri,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4)),
            const Text('Strategic Owner\'s Module',
                style: TextStyle(color: _textSec, fontSize: 10)),
          ],
        ),
        actions: [
          // History
          IconButton(
            tooltip: 'Report History',
            icon: const Icon(Icons.manage_history_rounded, color: _textSec),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        ReportHistoryScreen(gymId: widget.gymId))),
          ),
          // PDF export button (with progress indicator)
          _generatingPdf
              ? _buildPdfProgressIndicator()
              : IconButton(
                  tooltip: 'Export & Upload PDF',
                  icon: const Icon(
                      Icons.summarize_rounded, color: _accent),
                  onPressed: _generatePdf,
                ),
          const SizedBox(width: 6),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: _accent,
          indicatorWeight: 2.5,
          labelColor: _accent,
          unselectedLabelColor: _textSec,
          labelStyle: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8),
          tabs: const [
            Tab(text: 'OVERVIEW'),
            Tab(text: 'REVENUE'),
            Tab(text: 'MEMBERS'),
          ],
        ),
      );

  /// Shows upload progress ring + status text in the AppBar action area
  Widget _buildPdfProgressIndicator() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Tooltip(
          message: _pdfStatus,
          child: SizedBox(
            width: 24,
            height: 24,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: _uploadProgress > 0 ? _uploadProgress : null,
                  strokeWidth: 2.5,
                  color: _accent,
                  backgroundColor: _accent.withOpacity(0.2),
                ),
                if (_uploadProgress > 0)
                  Center(
                    child: Text(
                      '${(_uploadProgress * 100).toInt()}',
                      style: const TextStyle(
                          color: _accent,
                          fontSize: 7,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );

  Widget _buildLoader() => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _accent, strokeWidth: 2),
            SizedBox(height: 16),
            Text('Loading analytics…',
                style: TextStyle(color: _textSec, fontSize: 13)),
          ],
        ),
      );

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_rounded, color: _rose, size: 48),
              const SizedBox(height: 16),
              const Text('Failed to load analytics',
                  style: TextStyle(
                      color: _textPri,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_error ?? '',
                  style: const TextStyle(color: _textSec, fontSize: 12),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              _accentButton('RETRY', _load),
            ],
          ),
        ),
      );

  Widget _buildBody() => TabBarView(
        controller: _tab,
        children: [
          _OverviewTab(data: _data!),
          _RevenueTab(data: _data!),
          _MembersTab(data: _data!),
        ],
      );

  Widget _accentButton(String label, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          decoration: BoxDecoration(
              color: _accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _accent.withOpacity(0.4))),
          child: Text(label,
              style: const TextStyle(
                  color: _accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  OVERVIEW TAB
// ─────────────────────────────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final _AnalyticsData data;
  const _OverviewTab({required this.data});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {},
      color: _accent,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('KEY METRICS'),
            const SizedBox(height: 10),
            SizedBox(
              height: 106,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _KpiCard(label: 'Total Revenue',  value: 'Rs ${_fmt(data.totalRevenue)}',  icon: Icons.trending_up_rounded,   color: _green),
                  _KpiCard(label: 'Cash In',        value: 'Rs ${_fmt(data.cashRevenue)}',   icon: Icons.account_balance_rounded, color: _amber),
                  _KpiCard(label: 'Online In',      value: 'Rs ${_fmt(data.onlineRevenue)}', icon: Icons.contactless_rounded,   color: _accent),
                  _KpiCard(label: 'Total Members',  value: '${data.totalMembers}',           icon: Icons.groups_rounded,        color: const Color(0xFFA78BFA)),
                  _KpiCard(label: 'Active Members', value: '${data.activeMembers}',          icon: Icons.verified_rounded,      color: _green),
                  _KpiCard(label: 'Overdue Fees',   value: '${data.overdueMembers}',         icon: Icons.running_with_errors_rounded, color: _rose),
                  _KpiCard(label: 'Today Visits',   value: '${data.todayAttendance}',        icon: Icons.directions_walk_rounded, color: _accent),
                  _KpiCard(label: 'Month Visits',   value: '${data.monthAttendance}',        icon: Icons.bar_chart_rounded,     color: _amber),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _sectionLabel('MONTHLY REVENUE'),
            const SizedBox(height: 10),
            _RevenueBarChart(data: data.revenueByMonth),
            const SizedBox(height: 24),

            _sectionLabel('GYM HEALTH'),
            const SizedBox(height: 10),
            _HealthCard(
              activeRate: data.totalMembers == 0
                  ? 0
                  : (data.activeMembers / data.totalMembers * 100),
              overdueRate: data.totalMembers == 0
                  ? 0
                  : (data.overdueMembers / data.totalMembers * 100),
              cashShare: data.totalRevenue == 0
                  ? 0
                  : (data.cashRevenue / data.totalRevenue * 100),
              onlineShare: data.totalRevenue == 0
                  ? 0
                  : (data.onlineRevenue / data.totalRevenue * 100),
            ),
            const SizedBox(height: 24),

            _sectionLabel('RECENT TRANSACTIONS'),
            const SizedBox(height: 10),
            ...data.recentPayments.take(8).map((p) => _PaymentRow(payment: p)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) => NumberFormat('#,##0', 'en_US').format(v);

  Widget _sectionLabel(String t) => Text(t,
      style: const TextStyle(
          color: _textSec,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5));
}

// ─────────────────────────────────────────────────────────────────────────────
//  REVENUE TAB
// ─────────────────────────────────────────────────────────────────────────────
class _RevenueTab extends StatelessWidget {
  final _AnalyticsData data;
  const _RevenueTab({required this.data});

  @override
  Widget build(BuildContext context) {
    final total     = data.totalRevenue;
    final cashPct   = total == 0 ? 0.0 : data.cashRevenue   / total;
    final onlinePct = total == 0 ? 0.0 : data.onlineRevenue / total;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('REVENUE SPLIT',
                    style: TextStyle(
                        color: _textSec,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5)),
                const SizedBox(height: 16),
                _splitRow('Cash',            data.cashRevenue,   cashPct,   _amber),
                const SizedBox(height: 12),
                _splitRow('Online (EP/JC)',  data.onlineRevenue, onlinePct, _accent),
                const SizedBox(height: 16),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL',
                        style: TextStyle(
                            color: _textSec,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                    Text('Rs ${NumberFormat('#,##0').format(total)}',
                        style: const TextStyle(
                            color: _green,
                            fontSize: 18,
                            fontWeight: FontWeight.w900)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('BY MONTH',
                    style: TextStyle(
                        color: _textSec,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5)),
                const SizedBox(height: 14),
                _RevenueBarChart(data: data.revenueByMonth),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ALL TRANSACTIONS',
                    style: TextStyle(
                        color: _textSec,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5)),
                const SizedBox(height: 12),
                ...data.recentPayments.map((p) => _PaymentRow(payment: p)),
                if (data.recentPayments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text('No transactions yet',
                          style: TextStyle(color: _textSec)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _splitRow(String label, double amount, double pct, Color color) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(label,
                    style: const TextStyle(color: _textPri, fontSize: 13)),
              ]),
              Text('Rs ${NumberFormat('#,##0').format(amount)}',
                  style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: pct.clamp(0.0, 1.0),
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 5,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 2),
          Text('${(pct * 100).toStringAsFixed(1)}%',
              style: const TextStyle(color: _textSec, fontSize: 10)),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  MEMBERS TAB
// ─────────────────────────────────────────────────────────────────────────────
class _MembersTab extends StatelessWidget {
  final _AnalyticsData data;
  const _MembersTab({required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: _statBrick('Total',   '${data.totalMembers}',  _accent, Icons.groups_rounded)),
            const SizedBox(width: 10),
            Expanded(child: _statBrick('Active',  '${data.activeMembers}', _green,  Icons.verified_rounded)),
            const SizedBox(width: 10),
            Expanded(child: _statBrick('Overdue', '${data.overdueMembers}',_rose,   Icons.running_with_errors_rounded)),
          ]),
          const SizedBox(height: 16),

          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('BY MEMBERSHIP PLAN',
                    style: TextStyle(
                        color: _textSec,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5)),
                const SizedBox(height: 14),
                if (data.membersByPlan.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No data',
                          style: TextStyle(color: _textSec)),
                    ),
                  )
                else
                  ...data.membersByPlan.entries.map((e) {
                    final pct = data.totalMembers == 0
                        ? 0.0
                        : e.value / data.totalMembers;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(e.key,
                                  style: const TextStyle(
                                      color: _textPri, fontSize: 13)),
                              Text('${e.value} members',
                                  style: const TextStyle(
                                      color: _textSec, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: pct.clamp(0.0, 1.0),
                            backgroundColor: Colors.white10,
                            valueColor: const AlwaysStoppedAnimation<Color>(_accent),
                            minHeight: 5,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ATTENDANCE SNAPSHOT',
                    style: TextStyle(
                        color: _textSec,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5)),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: _attTile('Today',      '${data.todayAttendance}', Icons.wb_sunny_rounded)),
                  const SizedBox(width: 12),
                  Expanded(child: _attTile('This Month', '${data.monthAttendance}', Icons.date_range_rounded)),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('STAFF',
                        style: TextStyle(
                            color: _textSec,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5)),
                    Text('${data.staffList.length} assigned',
                        style: const TextStyle(color: _textSec, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 12),
                if (data.staffList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(
                      child: Text('No staff assigned',
                          style: TextStyle(color: _textSec)),
                    ),
                  )
                else
                  ...data.staffList.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: _accent.withOpacity(0.15),
                            child: Text(
                              (s['name'] as String? ?? '?')[0].toUpperCase(),
                              style: const TextStyle(
                                  color: _accent,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s['name'] ?? '—',
                                    style: const TextStyle(
                                        color: _textPri,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                                Text(s['email'] ?? '—',
                                    style: const TextStyle(
                                        color: _textSec, fontSize: 11)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('STAFF',
                                style: TextStyle(
                                    color: _accent,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ]),
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _attTile(String label, String value, IconData icon) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: _accent, size: 20),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    color: _textPri,
                    fontSize: 22,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(color: _textSec, fontSize: 11)),
          ],
        ),
      );

  Widget _statBrick(String label, String value, Color color, IconData icon) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(color: _textSec, fontSize: 10)),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  SHARED SUB-WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: 145,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _navyCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w900),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text(label,
                style: const TextStyle(color: _textSec, fontSize: 10),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      );
}

class _RevenueBarChart extends StatelessWidget {
  final Map<String, double> data;
  const _RevenueBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: Text('No revenue data yet',
              style: TextStyle(color: _textSec)),
        ),
      );
    }
    final maxVal = data.values.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.entries.map((e) {
          final barH = maxVal == 0 ? 0.0 : (e.value / maxVal) * 100;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: barH.clamp(4.0, 100.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          _accent.withOpacity(0.9),
                          _accent.withOpacity(0.35),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(e.key,
                      style: const TextStyle(color: _textSec, fontSize: 9),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _HealthCard extends StatelessWidget {
  final double activeRate;
  final double overdueRate;
  final double cashShare;
  final double onlineShare;

  const _HealthCard({
    required this.activeRate,
    required this.overdueRate,
    required this.cashShare,
    required this.onlineShare,
  });

  @override
  Widget build(BuildContext context) => _card(
        child: Column(
          children: [
            _healthRow('Active Member Rate',       activeRate,  _green),
            const SizedBox(height: 10),
            _healthRow('Overdue Fee Rate',          overdueRate, _rose),
            const SizedBox(height: 10),
            _healthRow('Cash vs Online (Cash %)',   cashShare,   _amber),
            const SizedBox(height: 10),
            _healthRow('Online Collection %',       onlineShare, _accent),
          ],
        ),
      );

  Widget _healthRow(String label, double pct, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(color: _textPri, fontSize: 12)),
              Text('${pct.toStringAsFixed(1)}%',
                  style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 5),
          LinearProgressIndicator(
            value: (pct / 100).clamp(0.0, 1.0),
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
}

class _PaymentRow extends StatelessWidget {
  final Map<String, dynamic> payment;
  const _PaymentRow({required this.payment});

  @override
  Widget build(BuildContext context) {
    final amount  = (payment['amount'] as num? ?? 0).toDouble();
    final method  = (payment['method'] ?? '').toString().toLowerCase();
    final status  = (payment['status'] ?? '').toString().toLowerCase();
    final ts      = payment['timestamp'] as Timestamp?;
    final date    = ts != null
        ? DateFormat('dd MMM yy').format(ts.toDate())
        : '—';

    final isOnline     = method == 'easypaisa' || method == 'jazzcash';
    final methodColor  = isOnline ? _accent : _amber;
    final statusColor  = status == 'completed' || status == ''
        ? _green
        : status == 'pending'
            ? _amber
            : _rose;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: methodColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isOnline ? Icons.contactless_rounded : Icons.account_balance_rounded,
              color: methodColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    method.toUpperCase().isEmpty
                        ? 'CASH'
                        : method.toUpperCase(),
                    style: TextStyle(
                        color: methodColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
                Text(date,
                    style: const TextStyle(color: _textSec, fontSize: 10)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Rs ${NumberFormat('#,##0').format(amount)}',
                  style: const TextStyle(
                      color: _textPri,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
              Container(
                margin: const EdgeInsets.only(top: 3),
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                    status.toUpperCase().isEmpty
                        ? 'DONE'
                        : status.toUpperCase(),
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Shared card helper ───────────────────────────────────────────────────────
Widget _card({required Widget child}) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: child,
    );