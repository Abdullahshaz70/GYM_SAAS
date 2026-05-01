import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
const _bg      = Color(0xFF000000);
const _card    = Color(0xFF1A1A1A);
const _accent  = Color(0xFFFFFF00);
const _rose    = Color(0xFFF87171);
const _textPri = Color(0xFFE2E8F0);
const _textSec = Color(0xFF9E9E9E);

const _categories = [
  'Rent',
  'Electricity',
  'Salaries',
  'Equipment',
  'Maintenance',
  'Marketing',
  'Other',
];

const _catColors = {
  'Rent':        Color(0xFFA78BFA),
  'Electricity': Color(0xFFFBBF24),
  'Salaries':    Color(0xFF4ADE80),
  'Equipment':   Color(0xFF60A5FA),
  'Maintenance': Color(0xFFF87171),
  'Marketing':   Color(0xFFFB923C),
  'Other':       Color(0xFF9E9E9E),
};

const _catIcons = {
  'Rent':        Icons.home_rounded,
  'Electricity': Icons.bolt_rounded,
  'Salaries':    Icons.people_alt_rounded,
  'Equipment':   Icons.fitness_center_rounded,
  'Maintenance': Icons.build_rounded,
  'Marketing':   Icons.campaign_rounded,
  'Other':       Icons.category_rounded,
};

// ─── Entry point ─────────────────────────────────────────────────────────────
class ExpenseTrackerScreen extends StatefulWidget {
  final String gymId;
  const ExpenseTrackerScreen({super.key, required this.gymId});

  @override
  State<ExpenseTrackerScreen> createState() => _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState extends State<ExpenseTrackerScreen> {
  DateTime? _filterMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _filterMonth = DateTime(now.year, now.month);
  }

  Query get _query {
    final base = FirebaseFirestore.instance
        .collection('gyms')
        .doc(widget.gymId)
        .collection('expenses')
        .orderBy('date', descending: true);

    if (_filterMonth != null) {
      final start = Timestamp.fromDate(_filterMonth!);
      final end   = Timestamp.fromDate(
          DateTime(_filterMonth!.year, _filterMonth!.month + 1));
      return base
          .where('date', isGreaterThanOrEqualTo: start)
          .where('date', isLessThan: end);
    }
    return base;
  }

  void _showAddSheet({Map<String, dynamic>? existing, String? docId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExpenseFormSheet(
        gymId: widget.gymId,
        existing: existing,
        docId: docId,
      ),
    );
  }

  Future<void> _delete(String docId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Expense',
            style: TextStyle(color: _textPri, fontWeight: FontWeight.w700)),
        content: const Text('This cannot be undone.',
            style: TextStyle(color: _textSec)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: _textSec)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: _rose)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await FirebaseFirestore.instance
        .collection('gyms')
        .doc(widget.gymId)
        .collection('expenses')
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _textPri, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('EXPENSE TRACKER',
                style: TextStyle(
                    color: _textPri,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4)),
            Text('Track all gym operating costs',
                style: TextStyle(color: _textSec, fontSize: 10)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        backgroundColor: _accent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Expense',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          _MonthFilterBar(
            selected: _filterMonth,
            onChanged: (m) => setState(() => _filterMonth = m),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _query.snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: _accent, strokeWidth: 2));
                }
                if (snap.hasError) {
                  return Center(
                      child: Text('Error: ${snap.error}',
                          style: const TextStyle(color: _rose)));
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) return const _EmptyExpenses();

                double total = 0;
                final Map<String, double> byCategory = {};
                for (final doc in docs) {
                  final d = doc.data() as Map<String, dynamic>;
                  final amt = (d['amount'] as num? ?? 0).toDouble();
                  total += amt;
                  final cat = d['category'] as String? ?? 'Other';
                  byCategory[cat] = (byCategory[cat] ?? 0) + amt;
                }

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _SummaryCard(
                          total: total, byCategory: byCategory)),
                    SliverPadding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 4, 16, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) {
                            final doc = docs[i];
                            final d =
                                doc.data() as Map<String, dynamic>;
                            return _ExpenseTile(
                              data: d,
                              onEdit: () => _showAddSheet(
                                  existing: d, docId: doc.id),
                              onDelete: () => _delete(doc.id),
                            );
                          },
                          childCount: docs.length,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Month filter chips ───────────────────────────────────────────────────────

class _MonthFilterBar extends StatelessWidget {
  final DateTime? selected;
  final ValueChanged<DateTime?> onChanged;

  const _MonthFilterBar({required this.selected, required this.onChanged});

  List<DateTime?> _options() {
    final now = DateTime.now();
    final months = <DateTime?>[null];
    for (int i = 0; i < 12; i++) {
      final m = now.month - i;
      final y = now.year + (m <= 0 ? -1 : 0);
      months.add(DateTime(y, m <= 0 ? m + 12 : m));
    }
    return months;
  }

  @override
  Widget build(BuildContext context) {
    final options = _options();
    return SizedBox(
      height: 46,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: options.length,
        itemBuilder: (_, i) {
          final opt = options[i];
          final label = opt == null
              ? 'All Time'
              : DateFormat('MMM yy').format(opt);
          final isSel = opt == null
              ? selected == null
              : (opt.year == selected?.year &&
                  opt.month == selected?.month);
          return GestureDetector(
            onTap: () => onChanged(opt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSel ? _accent : _card,
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: isSel ? _accent : Colors.white10),
              ),
              alignment: Alignment.center,
              child: Text(label,
                  style: TextStyle(
                      color: isSel ? Colors.black : _textSec,
                      fontSize: 12,
                      fontWeight: isSel
                          ? FontWeight.w700
                          : FontWeight.w400)),
            ),
          );
        },
      ),
    );
  }
}

// ─── Summary card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final double total;
  final Map<String, double> byCategory;

  const _SummaryCard({required this.total, required this.byCategory});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_US');
    final sorted = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL EXPENSES',
                  style: TextStyle(
                      color: _textSec,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2)),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _rose.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: _rose.withOpacity(0.3)),
                ),
                child: Text('Rs ${fmt.format(total)}',
                    style: const TextStyle(
                        color: _rose,
                        fontSize: 13,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          if (sorted.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...sorted.take(5).map((e) {
              final pct = total > 0 ? e.value / total : 0.0;
              final color = _catColors[e.key] ?? _textSec;
              final icon =
                  _catIcons[e.key] ?? Icons.category_rounded;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          Icon(icon, color: color, size: 13),
                          const SizedBox(width: 6),
                          Text(e.key,
                              style: const TextStyle(
                                  color: _textPri,
                                  fontSize: 12)),
                          const SizedBox(width: 6),
                          Text(
                              '${(pct * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                  color: _textSec,
                                  fontSize: 10)),
                        ]),
                        Text('Rs ${fmt.format(e.value)}',
                            style: TextStyle(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    LinearProgressIndicator(
                      value: pct.clamp(0.0, 1.0),
                      backgroundColor: Colors.white10,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(color),
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

// ─── Expense tile ─────────────────────────────────────────────────────────────

class _ExpenseTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExpenseTile(
      {required this.data,
      required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final category = data['category'] as String? ?? 'Other';
    final amount = (data['amount'] as num? ?? 0).toDouble();
    final desc = data['description'] as String? ?? '';
    final dateTs = data['date'] as Timestamp?;
    final date = dateTs != null
        ? DateFormat('dd MMM yyyy').format(dateTs.toDate())
        : '—';
    final color = _catColors[category] ?? _textSec;
    final icon = _catIcons[category] ?? Icons.category_rounded;
    final fmt = NumberFormat('#,##0', 'en_US');

    return Dismissible(
      key: ValueKey('${data.hashCode}$date'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _rose.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded,
            color: _rose),
      ),
      child: GestureDetector(
        onTap: onEdit,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category,
                        style: const TextStyle(
                            color: _textPri,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(desc,
                          style: const TextStyle(
                              color: _textSec, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 3),
                    Text(date,
                        style: const TextStyle(
                            color: _textSec, fontSize: 10)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('Rs ${fmt.format(amount)}',
                  style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyExpenses extends StatelessWidget {
  const _EmptyExpenses();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_rounded,
                color: _textSec.withOpacity(0.25), size: 64),
            const SizedBox(height: 16),
            const Text('No expenses recorded',
                style: TextStyle(
                    color: _textPri,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
                'Tap + Add Expense to record\nyour first gym expense.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: _textSec, fontSize: 13, height: 1.5)),
          ],
        ),
      );
}

// ─── Add / Edit form bottom sheet ─────────────────────────────────────────────

class _ExpenseFormSheet extends StatefulWidget {
  final String gymId;
  final Map<String, dynamic>? existing;
  final String? docId;

  const _ExpenseFormSheet(
      {required this.gymId, this.existing, this.docId});

  @override
  State<_ExpenseFormSheet> createState() =>
      _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends State<_ExpenseFormSheet> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'Rent';
  DateTime _date = DateTime.now();
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final d = widget.existing!;
      _category = d['category'] as String? ?? 'Rent';
      _amountCtrl.text =
          (d['amount'] as num? ?? '').toString();
      _descCtrl.text = d['description'] as String? ?? '';
      final ts = d['date'] as Timestamp?;
      if (ts != null) _date = ts.toDate();
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount =
        double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      _snack('Enter a valid amount', _rose);
      return;
    }

    setState(() => _saving = true);
    try {
      final col = FirebaseFirestore.instance
          .collection('gyms')
          .doc(widget.gymId)
          .collection('expenses');

      final payload = <String, dynamic>{
        'category': _category,
        'amount': amount,
        'description': _descCtrl.text.trim(),
        'date': Timestamp.fromDate(
            DateTime(_date.year, _date.month, _date.day)),
        'addedBy':
            FirebaseAuth.instance.currentUser?.uid ?? '',
      };

      if (_isEdit) {
        await col.doc(widget.docId).update(payload);
      } else {
        payload['createdAt'] =
            FieldValue.serverTimestamp();
        await col.add(payload);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        _snack('Error: $e', _rose);
        setState(() => _saving = false);
      }
    }
  }

  void _snack(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
    ));
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
              primary: _accent, onPrimary: Colors.black),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Color(0xFF1E1E1E)),
          left: BorderSide(color: Color(0xFF1E1E1E)),
          right: BorderSide(color: Color(0xFF1E1E1E)),
        ),
      ),
      padding:
          EdgeInsets.fromLTRB(20, 16, 20, 24 + bottom),
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
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(_isEdit ? 'Edit Expense' : 'Add Expense',
                style: const TextStyle(
                    color: _textPri,
                    fontSize: 17,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),

            // Category
            const Text('CATEGORY',
                style: TextStyle(
                    color: _textSec,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final sel = _category == cat;
                final color = _catColors[cat] ?? _textSec;
                final icon = _catIcons[cat] ??
                    Icons.category_rounded;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _category = cat),
                  child: AnimatedContainer(
                    duration:
                        const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel
                          ? color.withOpacity(0.18)
                          : _card,
                      borderRadius:
                          BorderRadius.circular(10),
                      border: Border.all(
                          color: sel
                              ? color
                              : Colors.white10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon,
                            color:
                                sel ? color : _textSec,
                            size: 14),
                        const SizedBox(width: 6),
                        Text(cat,
                            style: TextStyle(
                                color: sel
                                    ? color
                                    : _textSec,
                                fontSize: 12,
                                fontWeight: sel
                                    ? FontWeight.w700
                                    : FontWeight.w400)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Amount
            const Text('AMOUNT (Rs)',
                style: TextStyle(
                    color: _textSec,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(
                      decimal: true),
              style: const TextStyle(
                  color: _textPri,
                  fontSize: 16,
                  fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                filled: true,
                fillColor: _card,
                hintText: '0',
                hintStyle: TextStyle(
                    color: _textSec.withOpacity(0.5)),
                prefixText: 'Rs  ',
                prefixStyle: const TextStyle(
                    color: _textSec, fontSize: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Colors.white10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Colors.white10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: _accent, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Description
            const Text('DESCRIPTION (optional)',
                style: TextStyle(
                    color: _textSec,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2)),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              style: const TextStyle(
                  color: _textPri, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: _card,
                hintText: 'e.g. April rent payment',
                hintStyle: TextStyle(
                    color: _textSec.withOpacity(0.5)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Colors.white10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Colors.white10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: _accent, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Date
            const Text('DATE',
                style: TextStyle(
                    color: _textSec,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    const Icon(
                        Icons.calendar_today_rounded,
                        color: _textSec,
                        size: 16),
                    const SizedBox(width: 10),
                    Text(
                        DateFormat('dd MMM yyyy')
                            .format(_date),
                        style: const TextStyle(
                            color: _textPri,
                            fontSize: 14)),
                    const Spacer(),
                    const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF333333),
                        size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black))
                    : Text(
                        _isEdit
                            ? 'Save Changes'
                            : 'Add Expense',
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
}
