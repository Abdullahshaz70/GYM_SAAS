import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
const _bg      = Color(0xFF0A0A0A);
const _card    = Color(0xFF141414);
const _card2   = Color(0xFF1A1A1A);
const _accent  = Colors.yellowAccent;
const _rose    = Color(0xFFF87171);
const _textPri = Colors.white;
const _textSec = Color(0xFF666666);
const _border  = Color(0xFF1E1E1E);

// ─── Entry point ─────────────────────────────────────────────────────────────
class WorkoutLogScreen extends StatelessWidget {
  const WorkoutLogScreen({super.key});

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
            Text('WORKOUT LOG',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4)),
            Text('Track your training sessions',
                style: TextStyle(color: _textSec, fontSize: 10)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _border),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showWorkoutSheet(context),
        backgroundColor: _accent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log Workout',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_uid)
            .collection('workouts')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: _accent, strokeWidth: 2));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return const _EmptyWorkout();

          // Group by month
          final Map<String, List<QueryDocumentSnapshot>> grouped = {};
          for (final doc in docs) {
            final d = doc.data() as Map<String, dynamic>;
            final ts = d['date'] as Timestamp?;
            final label = ts != null
                ? DateFormat('MMMM yyyy').format(ts.toDate())
                : 'Unknown';
            grouped.putIfAbsent(label, () => []).add(doc);
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: grouped.entries.expand((entry) {
              return [
                _sectionLabel(entry.key),
                const SizedBox(height: 8),
                ...entry.value.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  return _WorkoutTile(
                    data: d,
                    onEdit: () => _showWorkoutSheet(context,
                        existing: d, docId: doc.id),
                    onDelete: () => _delete(context, doc.id),
                  );
                }),
                const SizedBox(height: 8),
              ];
            }).toList(),
          );
        },
      ),
    );
  }

  static Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 4),
        child: Text(text,
            style: const TextStyle(
                color: _textSec,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5)),
      );

  static void _showWorkoutSheet(BuildContext ctx,
      {Map<String, dynamic>? existing, String? docId}) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _WorkoutSheet(existing: existing, docId: docId),
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
        title: const Text('Delete Workout',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700)),
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
            child: const Text('Delete',
                style: TextStyle(color: _rose)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('workouts')
        .doc(docId)
        .delete();
  }
}

// ─── Workout tile ─────────────────────────────────────────────────────────────

class _WorkoutTile extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onEdit, onDelete;
  const _WorkoutTile(
      {required this.data,
      required this.onEdit,
      required this.onDelete});

  @override
  State<_WorkoutTile> createState() => _WorkoutTileState();
}

class _WorkoutTileState extends State<_WorkoutTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final title = d['title'] as String? ?? 'Workout';
    final notes = d['notes'] as String? ?? '';
    final ts = d['date'] as Timestamp?;
    final dateStr = ts != null
        ? DateFormat('EEE, dd MMM').format(ts.toDate())
        : '—';
    final exercises =
        (d['exercises'] as List<dynamic>? ?? [])
            .cast<Map<dynamic, dynamic>>();

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.yellowAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                      Icons.fitness_center_rounded,
                      color: Colors.yellowAccent,
                      size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                          '$dateStr  ·  ${exercises.length} exercise${exercises.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                              color: _textSec,
                              fontSize: 11)),
                    ],
                  ),
                ),
                Row(children: [
                  GestureDetector(
                    onTap: widget.onEdit,
                    child: const Icon(Icons.edit_rounded,
                        color: _textSec, size: 16),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: widget.onDelete,
                    child: const Icon(Icons.delete_outline_rounded,
                        color: _rose, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: _textSec,
                    size: 18,
                  ),
                ]),
              ]),
            ),

            // Exercises (expanded)
            if (_expanded && exercises.isNotEmpty) ...[
              const Divider(color: _border, height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...exercises.map((ex) {
                      final name = ex['name'] as String? ?? '—';
                      final sets = ex['sets'] ?? '—';
                      final reps = ex['reps'] ?? '—';
                      final wt = ex['weight'];
                      final unit = ex['unit'] as String? ?? 'kg';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.yellowAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13)),
                          ),
                          Text(
                            '${sets}×${reps}${wt != null && wt != '' ? '  @  ${wt}$unit' : ''}',
                            style: const TextStyle(
                                color: _textSec,
                                fontSize: 12),
                          ),
                        ]),
                      );
                    }),
                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(notes,
                          style: const TextStyle(
                              color: _textSec,
                              fontSize: 11,
                              fontStyle: FontStyle.italic)),
                    ],
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyWorkout extends StatelessWidget {
  const _EmptyWorkout();

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
              child: const Icon(Icons.fitness_center_rounded,
                  color: Colors.yellowAccent, size: 32),
            ),
            const SizedBox(height: 16),
            const Text('No workouts logged yet',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Tap + Log Workout to record\nyour first session.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: _textSec, fontSize: 13, height: 1.5)),
          ],
        ),
      );
}

// ─── Workout form sheet ───────────────────────────────────────────────────────

class _WorkoutSheet extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final String? docId;
  const _WorkoutSheet({this.existing, this.docId});

  @override
  State<_WorkoutSheet> createState() => _WorkoutSheetState();
}

class _WorkoutSheetState extends State<_WorkoutSheet> {
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _date   = DateTime.now();
  bool _saving     = false;

  // exercises: {name, sets, reps, weight, unit}
  final List<Map<String, dynamic>> _exercises = [];

  bool get _isEdit => widget.existing != null;
  static final _uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final d = widget.existing!;
      _titleCtrl.text = d['title'] as String? ?? '';
      _notesCtrl.text = d['notes'] as String? ?? '';
      final ts = d['date'] as Timestamp?;
      if (ts != null) _date = ts.toDate();
      final exList = (d['exercises'] as List<dynamic>? ?? [])
          .cast<Map<dynamic, dynamic>>();
      for (final e in exList) {
        _exercises.add({
          'name':   e['name'] ?? '',
          'sets':   e['sets']?.toString() ?? '',
          'reps':   e['reps']?.toString() ?? '',
          'weight': e['weight']?.toString() ?? '',
          'unit':   e['unit'] ?? 'kg',
        });
      }
    }
    if (_exercises.isEmpty) _addExercise();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _addExercise() => setState(() => _exercises.add(
      {'name': '', 'sets': '', 'reps': '', 'weight': '', 'unit': 'kg'}));

  void _removeExercise(int i) {
    if (_exercises.length > 1) setState(() => _exercises.removeAt(i));
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
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      _snack('Enter a workout title');
      return;
    }
    final hasValidEx = _exercises.any((e) =>
        (e['name'] as String).isNotEmpty);
    if (!hasValidEx) {
      _snack('Add at least one exercise name');
      return;
    }

    setState(() => _saving = true);
    try {
      final col = FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('workouts');

      final exData = _exercises
          .where((e) => (e['name'] as String).isNotEmpty)
          .map((e) => {
                'name':   e['name'],
                'sets':   int.tryParse(e['sets'] ?? '') ?? 0,
                'reps':   int.tryParse(e['reps'] ?? '') ?? 0,
                'weight': e['weight'],
                'unit':   e['unit'],
              })
          .toList();

      final payload = {
        'title':     title,
        'notes':     _notesCtrl.text.trim(),
        'date':      Timestamp.fromDate(
            DateTime(_date.year, _date.month, _date.day)),
        'exercises': exData,
      };

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
            Text(_isEdit ? 'Edit Workout' : 'Log Workout',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 18),

            // Title
            _label('WORKOUT TITLE'),
            const SizedBox(height: 6),
            _field(_titleCtrl, 'e.g. Chest Day, Leg Day'),
            const SizedBox(height: 12),

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
                      style:
                          const TextStyle(color: Colors.white, fontSize: 14)),
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFF333333), size: 18),
                ]),
              ),
            ),
            const SizedBox(height: 16),

            // Exercises
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _label('EXERCISES'),
                GestureDetector(
                  onTap: _addExercise,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.yellowAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded,
                            color: Colors.yellowAccent, size: 14),
                        SizedBox(width: 4),
                        Text('Add',
                            style: TextStyle(
                                color: Colors.yellowAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ..._exercises.asMap().entries.map((entry) {
              final i   = entry.key;
              final ex  = entry.value;
              return _ExerciseRow(
                key: ValueKey(i),
                index: i,
                data: ex,
                onChanged: (key, val) =>
                    setState(() => _exercises[i][key] = val),
                onRemove: () => _removeExercise(i),
              );
            }),

            const SizedBox(height: 12),

            // Notes
            _label('NOTES (optional)'),
            const SizedBox(height: 6),
            _field(_notesCtrl, 'e.g. Felt strong today, new PR on bench',
                maxLines: 2),
            const SizedBox(height: 22),

            // Save
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
                    : Text(_isEdit ? 'Save Changes' : 'Log Workout',
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

  static Widget _field(TextEditingController ctrl, String hint,
          {int maxLines = 1}) =>
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          filled: true,
          fillColor: _card,
          hintText: hint,
          hintStyle:
              TextStyle(color: _textSec.withOpacity(0.5), fontSize: 13),
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

// ─── Exercise row ─────────────────────────────────────────────────────────────

class _ExerciseRow extends StatelessWidget {
  final int index;
  final Map<String, dynamic> data;
  final void Function(String key, dynamic val) onChanged;
  final VoidCallback onRemove;

  const _ExerciseRow({
    super.key,
    required this.index,
    required this.data,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Exercise ${index + 1}',
              style: const TextStyle(
                  color: Colors.yellowAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
          const Spacer(),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.remove_circle_outline_rounded,
                color: _rose, size: 18),
          ),
        ]),
        const SizedBox(height: 8),
        _miniField(data['name'] ?? '', 'Exercise name',
            onChanged: (v) => onChanged('name', v)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
              child: _miniField(data['sets'] ?? '', 'Sets',
                  numeric: true,
                  onChanged: (v) => onChanged('sets', v))),
          const SizedBox(width: 8),
          Expanded(
              child: _miniField(data['reps'] ?? '', 'Reps',
                  numeric: true,
                  onChanged: (v) => onChanged('reps', v))),
          const SizedBox(width: 8),
          Expanded(
              child: _miniField(data['weight'] ?? '', 'Weight',
                  numeric: true,
                  onChanged: (v) => onChanged('weight', v))),
          const SizedBox(width: 6),
          // kg / lbs toggle
          GestureDetector(
            onTap: () =>
                onChanged('unit', data['unit'] == 'kg' ? 'lbs' : 'kg'),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.yellowAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(data['unit'] ?? 'kg',
                  style: const TextStyle(
                      color: Colors.yellowAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _miniField(String initial, String hint,
      {bool numeric = false,
      required void Function(String) onChanged}) {
    final ctrl =
        TextEditingController(text: initial)
          ..selection = TextSelection.fromPosition(
              TextPosition(offset: initial.length));
    return TextField(
      controller: ctrl,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF111111),
        hintText: hint,
        hintStyle: const TextStyle(color: _textSec, fontSize: 11),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white12)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white12)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
                color: Colors.yellowAccent, width: 1.5)),
      ),
    );
  }
}
