import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MembershipEditScreen extends StatefulWidget {
  final String uid;
  final String gymId;
  final String fieldType;
  final String currentValue;

  const MembershipEditScreen({
    super.key,
    required this.uid,
    required this.gymId,
    required this.fieldType,
    required this.currentValue,
  });

  @override
  State<MembershipEditScreen> createState() => _MembershipEditScreenState();
}

class _MembershipEditScreenState extends State<MembershipEditScreen> {
  final TextEditingController _feeController = TextEditingController();
  String _selectedPlan = "Monthly";
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  final List<String> _plans = ["Monthly", "6 Months", "Yearly"];

  @override
  void initState() {
    super.initState();
    if (widget.fieldType == 'fee') {
      _feeController.text = widget.currentValue;
    } else if (widget.fieldType == 'plan') {
      _selectedPlan = _plans.contains(widget.currentValue) ? widget.currentValue : "Monthly";
    } else if (widget.fieldType == 'validity') {
      _selectedDate = DateTime.tryParse(widget.currentValue) ?? DateTime.now();
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.yellowAccent,
              onPrimary: Colors.black,
              surface: Color(0xFF1A1A1A),
              onSurface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.yellowAccent),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _updateField() async {
    setState(() => _isSaving = true);
    final docRef = FirebaseFirestore.instance
        .collection('gyms')
        .doc(widget.gymId)
        .collection('members')
        .doc(widget.uid);

    Map<String, dynamic> updateData = {};

    if (widget.fieldType == 'plan') {
      updateData['plan'] = _selectedPlan;
    } else if (widget.fieldType == 'fee') {
      updateData['currentFee'] = num.tryParse(_feeController.text) ?? 0;
    } else if (widget.fieldType == 'validity') {
      updateData['validUntil'] = Timestamp.fromDate(_selectedDate);
    }

    try {
      await docRef.update(updateData);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      debugPrint("Update Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text("UPDATE ${widget.fieldType.toUpperCase()}", 
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInputSection(),
            const Spacer(),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    if (widget.fieldType == 'plan') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Select Membership Plan", style: TextStyle(color: Colors.white38, fontSize: 13)),
          const SizedBox(height: 20),
          ..._plans.map((plan) => _buildPlanOption(plan)),
        ],
      );
    } else if (widget.fieldType == 'validity') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Select Expiry Date", style: TextStyle(color: Colors.white38, fontSize: 13)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => _selectDate(context),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.purpleAccent.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.purpleAccent.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, color: Colors.purpleAccent),
                  const SizedBox(width: 15),
                  Text(
                    DateFormat('EEEE, dd MMM yyyy').format(_selectedDate),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Enter Monthly Fee", style: TextStyle(color: Colors.white38, fontSize: 13)),
          const SizedBox(height: 20),
          TextField(
            controller: _feeController,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixText: "Rs ",
              prefixStyle: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
              filled: true,
              fillColor: Colors.orangeAccent.withOpacity(0.05),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: Colors.orangeAccent.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Colors.orangeAccent),
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildPlanOption(String planName) {
    bool isSelected = _selectedPlan == planName;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = planName),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent.withOpacity(0.1) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blueAccent : Colors.white10,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? Colors.blueAccent : Colors.white24,
            ),
            const SizedBox(width: 15),
            Text(
              planName,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.yellowAccent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        onPressed: _isSaving ? null : _updateField,
        child: _isSaving
            ? const CircularProgressIndicator(color: Colors.black)
            : const Text("UPDATE MEMBERSHIP", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
      ),
    );
  }
}