import 'dart:math' show max;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
const _bg      = Color(0xFF0A0A0A);
const _card    = Color(0xFF141414);
const _card2   = Color(0xFF1A1A1A);
const _accent  = Colors.yellowAccent;
const _green   = Color(0xFF4ADE80);
const _rose    = Color(0xFFF87171);
const _blue    = Color(0xFF60A5FA);
const _purple  = Color(0xFFA78BFA);
const _orange  = Color(0xFFFB923C);
const _textPri = Colors.white;
const _textSec = Color(0xFF666666);
const _border  = Color(0xFF1E1E1E);

// ─── BMI helpers ──────────────────────────────────────────────────────────────
double _calcBmi(double weightKg, double heightCm) {
  if (heightCm <= 0) return 0;
  final hm = heightCm / 100;
  return weightKg / (hm * hm);
}

String _bmiCategory(double bmi) {
  if (bmi <= 0) return '—';
  if (bmi < 18.5) return 'Underweight';
  if (bmi < 25.0) return 'Normal';
  if (bmi < 30.0) return 'Overweight';
  return 'Obese';
}

Color _bmiColor(double bmi) {
  if (bmi <= 0) return _textSec;
  if (bmi < 18.5) return _blue;
  if (bmi < 25.0) return _green;
  if (bmi < 30.0) return _orange;
  return _rose;
}

// ─── Entry point ─────────────────────────────────────────────────────────────
class BodyMeasurementsScreen extends StatelessWidget {
  const BodyMeasurementsScreen({super.key});

  static final _uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BODY TRACKER',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4)),
            Text('Weight, BMI & measurements over time',
                style: TextStyle(color: _textSec, fontSize: 10)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _border),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context),
        backgroundColor: _accent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Entry',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_uid)
            .collection('measurements')
            .orderBy('date', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child:
                    CircularProgressIndicator(color: _accent, strokeWidth: 2));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return const _EmptyMeasurements();

          final entries = docs
              .map((d) => d.data() as Map<String, dynamic>)
              .toList();

          final latest = entries.first;
          final latestWeight =
              (latest['weight'] as num? ?? 0).toDouble();
          final latestHeight =
              (latest['height'] as num? ?? 0).toDouble();
          final latestBmi =
              (latest['bmi'] as num?)?.toDouble() ??
                  _calcBmi(latestWeight, latestHeight);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              // ── Latest BMI card ────────────────────────────────────────
              _BmiCard(
                  bmi: latestBmi,
                  weight: latestWeight,
                  height: latestHeight),
              const SizedBox(height: 16),

              // ── Weight history chart ───────────────────────────────────
              if (entries.length > 1) ...[
                _WeightChart(entries: entries.take(10).toList()),
                const SizedBox(height: 16),
              ],

              // ── History list ───────────────────────────────────────────
              _sectionLabel('HISTORY'),
              const SizedBox(height: 8),
              ...docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                return _MeasurementTile(
                  data: d,
                  onEdit: () =>
                      _showAddSheet(context, existing: d, docId: doc.id),
                  onDelete: () => _delete(context, doc.id),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  static Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Text(text,
            style: const TextStyle(
                color: _textSec,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5)),
      );

  static void _showAddSheet(BuildContext ctx,
      {Map<String, dynamic>? existing, String? docId}) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _MeasurementSheet(existing: existing, docId: docId),
    );
  }

  static Future<void> _delete(
      BuildContext context, String docId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card2,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Entry',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
        content: const Text('This cannot be undone.',
            style: TextStyle(color: _textSec)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: _textSec)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Delete', style: TextStyle(color: _rose)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('measurements')
        .doc(docId)
        .delete();
  }
}

// ─── BMI card ─────────────────────────────────────────────────────────────────

class _BmiCard extends StatelessWidget {
  final double bmi, weight, height;
  const _BmiCard(
      {required this.bmi, required this.weight, required this.height});

  @override
  Widget build(BuildContext context) {
    final category = _bmiCategory(bmi);
    final color    = _bmiColor(bmi);
    final fmt      = NumberFormat('#,##0.0');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CURRENT STATUS',
              style: TextStyle(
                  color: _textSec,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2)),
          const SizedBox(height: 16),

          Row(children: [
            // BMI circle
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2.5),
                color: color.withOpacity(0.08),
              ),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(bmi > 0 ? fmt.format(bmi) : '—',
                        style: TextStyle(
                            color: color,
                            fontSize: 20,
                            fontWeight: FontWeight.w900)),
                    const Text('BMI',
                        style: TextStyle(
                            color: _textSec,
                            fontSize: 9,
                            fontWeight: FontWeight.w600)),
                  ]),
            ),
            const SizedBox(width: 18),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category,
                      style: TextStyle(
                          color: color,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  _statRow('Weight',
                      weight > 0 ? '${fmt.format(weight)} kg' : '—',
                      Colors.white),
                  const SizedBox(height: 4),
                  _statRow('Height',
                      height > 0 ? '${fmt.format(height)} cm' : '—',
                      Colors.white),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 14),
          // BMI scale bar
          _BmiScaleBar(bmi: bmi),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, Color c) => Row(
        children: [
          Text('$label: ',
              style: const TextStyle(color: _textSec, fontSize: 12)),
          Text(value,
              style: TextStyle(
                  color: c, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      );
}

class _BmiScaleBar extends StatelessWidget {
  final double bmi;
  const _BmiScaleBar({required this.bmi});

  @override
  Widget build(BuildContext context) {
    // BMI range 10–40 mapped to 0–1
    final pos = bmi > 0
        ? ((bmi - 10) / 30).clamp(0.0, 1.0)
        : -1.0;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          height: 8,
          child: Row(children: [
            Expanded(flex: 17, child: Container(color: _blue)),   // <18.5
            Expanded(flex: 65, child: Container(color: _green)),  // 18.5-25
            Expanded(flex: 50, child: Container(color: _orange)), // 25-30
            Expanded(flex: 68, child: Container(color: _rose)),   // 30-40
          ]),
        ),
      ),
      if (bmi > 0)
        LayoutBuilder(builder: (_, c) {
          final offset = (pos * c.maxWidth).clamp(4.0, c.maxWidth - 4);
          return Stack(clipBehavior: Clip.none, children: [
            Positioned(
              left: offset - 1,
              top: 2,
              child: Container(
                width: 2,
                height: 10,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
          ]);
        }),
      const SizedBox(height: 4),
      const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Under', style: TextStyle(color: _textSec, fontSize: 9)),
        Text('Normal', style: TextStyle(color: _textSec, fontSize: 9)),
        Text('Over', style: TextStyle(color: _textSec, fontSize: 9)),
        Text('Obese', style: TextStyle(color: _textSec, fontSize: 9)),
      ]),
    ]);
  }
}

// ─── Weight chart ─────────────────────────────────────────────────────────────

class _WeightChart extends StatelessWidget {
  final List<Map<String, dynamic>> entries;
  const _WeightChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    final weights = entries
        .map((e) => (e['weight'] as num? ?? 0).toDouble())
        .toList()
        .reversed
        .toList();
    final dates = entries
        .map((e) {
          final ts = e['date'] as Timestamp?;
          return ts != null
              ? DateFormat('dd MMM').format(ts.toDate())
              : '—';
        })
        .toList()
        .reversed
        .toList();

    final minW = weights.reduce((a, b) => a < b ? a : b);
    final maxW = weights.reduce((a, b) => a > b ? a : b);
    final range = max(maxW - minW, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('WEIGHT TREND',
            style: TextStyle(
                color: _textSec,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2)),
        const SizedBox(height: 14),
        SizedBox(
          height: 90,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(weights.length, (i) {
              final h = ((weights[i] - minW) / range * 70 + 12)
                  .clamp(12.0, 82.0);
              final isLast = i == weights.length - 1;
              return Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isLast)
                        Text(
                          '${weights[i].toStringAsFixed(1)}',
                          style: const TextStyle(
                              color: Colors.yellowAccent,
                              fontSize: 9,
                              fontWeight: FontWeight.w700),
                        ),
                      const SizedBox(height: 2),
                      Container(
                        height: h,
                        decoration: BoxDecoration(
                          color: isLast
                              ? Colors.yellowAccent
                              : Colors.yellowAccent.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(dates.first,
                style: const TextStyle(color: _textSec, fontSize: 9)),
            Text(dates.last,
                style: const TextStyle(
                    color: Colors.yellowAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ]),
    );
  }
}

// ─── Measurement tile ─────────────────────────────────────────────────────────

class _MeasurementTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onEdit, onDelete;
  const _MeasurementTile(
      {required this.data,
      required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final weight = (data['weight'] as num? ?? 0).toDouble();
    final height = (data['height'] as num? ?? 0).toDouble();
    final bmi = (data['bmi'] as num?)?.toDouble() ??
        _calcBmi(weight, height);
    final ts     = data['date'] as Timestamp?;
    final date   = ts != null
        ? DateFormat('dd MMM yyyy').format(ts.toDate())
        : '—';
    final bmiCol = _bmiColor(bmi);
    final fmt    = NumberFormat('#,##0.0');

    final chest    = (data['chest']     as num?)?.toDouble();
    final waist    = (data['waist']     as num?)?.toDouble();
    final arms     = (data['arms']      as num?)?.toDouble();
    final hips     = (data['hips']      as num?)?.toDouble();
    final thighs   = (data['thighs']    as num?)?.toDouble();
    final calves   = (data['calves']    as num?)?.toDouble();
    final shoulders= (data['shoulders'] as num?)?.toDouble();
    final neck     = (data['neck']      as num?)?.toDouble();
    final forearms = (data['forearms']  as num?)?.toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // BMI badge
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: bmiCol.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: bmiCol.withOpacity(0.3)),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(bmi > 0 ? fmt.format(bmi) : '—',
                style: TextStyle(
                    color: bmiCol,
                    fontSize: 13,
                    fontWeight: FontWeight.w800)),
            const Text('BMI',
                style: TextStyle(color: _textSec, fontSize: 8)),
          ]),
        ),
        const SizedBox(width: 12),

        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(date,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              Row(children: [
                GestureDetector(
                  onTap: onEdit,
                  child: const Icon(Icons.edit_rounded,
                      color: _textSec, size: 15),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(Icons.delete_outline_rounded,
                      color: _rose, size: 15),
                ),
              ]),
            ]),
            const SizedBox(height: 6),
            Wrap(spacing: 12, runSpacing: 4, children: [
              if (weight > 0)
                _chip('${fmt.format(weight)} kg', Colors.white),
              if (height > 0)
                _chip('${fmt.format(height)} cm', _textSec),
              if (chest != null && chest > 0)
                _chip('Chest ${fmt.format(chest)}', _purple),
              if (waist != null && waist > 0)
                _chip('Waist ${fmt.format(waist)}', _blue),
              if (arms != null && arms > 0)
                _chip('Arms ${fmt.format(arms)}', _green),
              if (hips != null && hips > 0)
                _chip('Hips ${fmt.format(hips)}', _orange),
              if (thighs != null && thighs > 0)
                _chip('Thighs ${fmt.format(thighs)}', _rose),
              if (calves != null && calves > 0)
                _chip('Calves ${fmt.format(calves)}', _blue),
              if (shoulders != null && shoulders > 0)
                _chip('Shoulders ${fmt.format(shoulders)}', _accent),
              if (neck != null && neck > 0)
                _chip('Neck ${fmt.format(neck)}', _textSec),
              if (forearms != null && forearms > 0)
                _chip('Forearms ${fmt.format(forearms)}', _green),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _chip(String text, Color color) => Text(text,
      style: TextStyle(color: color, fontSize: 11));
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyMeasurements extends StatelessWidget {
  const _EmptyMeasurements();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.yellowAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.monitor_weight_rounded,
                  color: Colors.yellowAccent, size: 32),
            ),
            const SizedBox(height: 16),
            const Text('No measurements yet',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Tap + Add Entry to record\nyour first body measurement.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: _textSec, fontSize: 13, height: 1.5)),
          ],
        ),
      );
}

// ─── Measurement form sheet ───────────────────────────────────────────────────

class _MeasurementSheet extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final String? docId;
  const _MeasurementSheet({this.existing, this.docId});

  @override
  State<_MeasurementSheet> createState() => _MeasurementSheetState();
}

class _MeasurementSheetState extends State<_MeasurementSheet> {
  final _wtCtrl       = TextEditingController();
  final _htCtrl       = TextEditingController();
  final _chestCtrl    = TextEditingController();
  final _waistCtrl    = TextEditingController();
  final _armsCtrl     = TextEditingController();
  final _hipsCtrl     = TextEditingController();
  final _thighsCtrl   = TextEditingController();
  final _calvesCtrl   = TextEditingController();
  final _shouldersCtrl= TextEditingController();
  final _neckCtrl     = TextEditingController();
  final _forearmsCtrl = TextEditingController();
  DateTime _date   = DateTime.now();
  bool _saving     = false;

  bool get _isEdit => widget.existing != null;
  static final _uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final d = widget.existing!;
      _wtCtrl.text =
          (d['weight'] as num?)?.toString() ?? '';
      _htCtrl.text =
          (d['height'] as num?)?.toString() ?? '';
      _chestCtrl.text     = (d['chest']     as num?)?.toString() ?? '';
      _waistCtrl.text     = (d['waist']     as num?)?.toString() ?? '';
      _armsCtrl.text      = (d['arms']      as num?)?.toString() ?? '';
      _hipsCtrl.text      = (d['hips']      as num?)?.toString() ?? '';
      _thighsCtrl.text    = (d['thighs']    as num?)?.toString() ?? '';
      _calvesCtrl.text    = (d['calves']    as num?)?.toString() ?? '';
      _shouldersCtrl.text = (d['shoulders'] as num?)?.toString() ?? '';
      _neckCtrl.text      = (d['neck']      as num?)?.toString() ?? '';
      _forearmsCtrl.text  = (d['forearms']  as num?)?.toString() ?? '';
      final ts = d['date'] as Timestamp?;
      if (ts != null) _date = ts.toDate();
    }
  }

  @override
  void dispose() {
    _wtCtrl.dispose();
    _htCtrl.dispose();
    _chestCtrl.dispose();
    _waistCtrl.dispose();
    _armsCtrl.dispose();
    _hipsCtrl.dispose();
    _thighsCtrl.dispose();
    _calvesCtrl.dispose();
    _shouldersCtrl.dispose();
    _neckCtrl.dispose();
    _forearmsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
              primary: Colors.yellowAccent,
              onPrimary: Colors.black),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final weight = double.tryParse(_wtCtrl.text.trim());
    final height = double.tryParse(_htCtrl.text.trim());
    if (weight == null || weight <= 0) {
      _snack('Enter a valid weight');
      return;
    }
    if (height == null || height <= 0) {
      _snack('Enter a valid height');
      return;
    }

    setState(() => _saving = true);
    try {
      final bmi = _calcBmi(weight, height);
      final col = FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('measurements');

      final payload = <String, dynamic>{
        'weight': weight,
        'height': height,
        'bmi':    double.parse(bmi.toStringAsFixed(2)),
        'date':   Timestamp.fromDate(
            DateTime(_date.year, _date.month, _date.day)),
      };

      final chest    = double.tryParse(_chestCtrl.text.trim());
      final waist    = double.tryParse(_waistCtrl.text.trim());
      final arms     = double.tryParse(_armsCtrl.text.trim());
      final hips     = double.tryParse(_hipsCtrl.text.trim());
      final thighs   = double.tryParse(_thighsCtrl.text.trim());
      final calves   = double.tryParse(_calvesCtrl.text.trim());
      final shoulders= double.tryParse(_shouldersCtrl.text.trim());
      final neck     = double.tryParse(_neckCtrl.text.trim());
      final forearms = double.tryParse(_forearmsCtrl.text.trim());
      if (chest != null && chest > 0)       payload['chest']    = chest;
      if (waist != null && waist > 0)       payload['waist']    = waist;
      if (arms != null && arms > 0)         payload['arms']     = arms;
      if (hips != null && hips > 0)         payload['hips']     = hips;
      if (thighs != null && thighs > 0)     payload['thighs']   = thighs;
      if (calves != null && calves > 0)     payload['calves']   = calves;
      if (shoulders != null && shoulders > 0) payload['shoulders'] = shoulders;
      if (neck != null && neck > 0)         payload['neck']     = neck;
      if (forearms != null && forearms > 0) payload['forearms'] = forearms;

      if (_isEdit) {
        await col.doc(widget.docId).update(payload);
      } else {
        payload['createdAt'] = FieldValue.serverTimestamp();
        await col.add(payload);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        _snack('Error: $e');
        setState(() => _saving = false);
      }
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: _rose,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    // Live BMI preview
    final wt = double.tryParse(_wtCtrl.text) ?? 0;
    final ht = double.tryParse(_htCtrl.text) ?? 0;
    final liveBmi = _calcBmi(wt, ht);
    final bmiCol = _bmiColor(liveBmi);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top:   BorderSide(color: _border),
          left:  BorderSide(color: _border),
          right: BorderSide(color: _border),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFF333333),
                    borderRadius: BorderRadius.circular(99)),
              ),
            ),
            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_isEdit ? 'Edit Measurement' : 'Add Measurement',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800)),
                // Live BMI preview
                if (liveBmi > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: bmiCol.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: bmiCol.withOpacity(0.3)),
                    ),
                    child: Text(
                        'BMI ${liveBmi.toStringAsFixed(1)}  ·  ${_bmiCategory(liveBmi)}',
                        style: TextStyle(
                            color: bmiCol,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
            const SizedBox(height: 18),

            // Date
            _label('DATE'),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today_rounded,
                      color: _textSec, size: 16),
                  const SizedBox(width: 10),
                  Text(DateFormat('EEE, dd MMM yyyy').format(_date),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14)),
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFF333333), size: 18),
                ]),
              ),
            ),
            const SizedBox(height: 12),

            // Weight + Height
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('WEIGHT (kg)'),
                const SizedBox(height: 6),
                _numField(_wtCtrl, '70.0'),
              ])),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('HEIGHT (cm)'),
                const SizedBox(height: 6),
                _numField(_htCtrl, '175'),
              ])),
            ]),
            const SizedBox(height: 14),

            _label('BODY MEASUREMENTS (cm) — OPTIONAL'),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Chest', style: TextStyle(color: _textSec, fontSize: 10)),
                const SizedBox(height: 4),
                _numField(_chestCtrl, '—'),
              ])),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Waist', style: TextStyle(color: _textSec, fontSize: 10)),
                const SizedBox(height: 4),
                _numField(_waistCtrl, '—'),
              ])),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Arms', style: TextStyle(color: _textSec, fontSize: 10)),
                const SizedBox(height: 4),
                _numField(_armsCtrl, '—'),
              ])),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Hips', style: TextStyle(color: _textSec, fontSize: 10)),
                const SizedBox(height: 4),
                _numField(_hipsCtrl, '—'),
              ])),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Thighs', style: TextStyle(color: _textSec, fontSize: 10)),
                const SizedBox(height: 4),
                _numField(_thighsCtrl, '—'),
              ])),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Calves', style: TextStyle(color: _textSec, fontSize: 10)),
                const SizedBox(height: 4),
                _numField(_calvesCtrl, '—'),
              ])),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Shoulders', style: TextStyle(color: _textSec, fontSize: 10)),
                const SizedBox(height: 4),
                _numField(_shouldersCtrl, '—'),
              ])),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Neck', style: TextStyle(color: _textSec, fontSize: 10)),
                const SizedBox(height: 4),
                _numField(_neckCtrl, '—'),
              ])),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Forearms', style: TextStyle(color: _textSec, fontSize: 10)),
                const SizedBox(height: 4),
                _numField(_forearmsCtrl, '—'),
              ])),
            ]),
            const SizedBox(height: 22),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellowAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black))
                    : Text(_isEdit ? 'Save Changes' : 'Save Entry',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _label(String t) => Text(t,
      style: const TextStyle(
          color: _textSec,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2));

  Widget _numField(TextEditingController ctrl, String hint) =>
      TextField(
        controller: ctrl,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          filled: true,
          fillColor: _card,
          hintText: hint,
          hintStyle:
              TextStyle(color: _textSec.withOpacity(0.4), fontSize: 13),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white12)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white12)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: Colors.yellowAccent, width: 1.5)),
        ),
      );
}
