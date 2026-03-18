import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import 'payment_pending_screen.dart';

class PayFeeScreen extends StatefulWidget {
  final String gymId;
  final String memberId;
  final String plan;
  final double currentFee;

  const PayFeeScreen({
    super.key,
    required this.gymId,
    required this.memberId,
    required this.plan,
    required this.currentFee,
  });

  @override
  State<PayFeeScreen> createState() => _PayFeeScreenState();
}

class _PayFeeScreenState extends State<PayFeeScreen> {
  final FirestoreService _fs = FirestoreService();

  bool _isLoading = true;
  bool _isSubmitting = false;

  String _easypaisaNumber = '';
  String _accountName = '';
  double _amount = 0;
  late String _referenceCode;
  File? _screenshotFile;

  @override
  void initState() {
    super.initState();
    _referenceCode =
        _fs.generateReferenceCode(widget.gymId, widget.memberId);
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await _fs.getCompanyConfig();
    if (!mounted) return;
    setState(() {
      _easypaisaNumber = config?['easypaisaNumber'] ?? 'Not configured';
      _accountName = config?['accountName'] ?? 'ProTracker';
      _amount = _calculateAmount();
      _isLoading = false;
    });
  }

  double _calculateAmount() {
    switch (widget.plan) {
      case '6 Months':
        return widget.currentFee * 5.0;
      case 'Yearly':
        return widget.currentFee * 9.0;
      default:
        return widget.currentFee;
    }
  }

  Future<void> _pickScreenshot() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() => _screenshotFile = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (_screenshotFile == null) {
      _showSnack('Please upload your payment screenshot', Colors.orange);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final ref = FirebaseStorage.instance.ref().child(
          'payment_screenshots/${widget.gymId}/$_referenceCode.jpg');
      await ref.putFile(_screenshotFile!);
      final screenshotUrl = await ref.getDownloadURL();

      final paymentId = await _fs.createPayment(
        gymId: widget.gymId,
        memberId: widget.memberId,
        amount: _amount,
        plan: widget.plan,
        referenceCode: _referenceCode,
        screenshotUrl: screenshotUrl,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentPendingScreen(
            gymId: widget.gymId,
            paymentId: paymentId,
            referenceCode: _referenceCode,
            amount: _amount,
          ),
        ),
      );
    } catch (e) {
      if (mounted) _showSnack('Error: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating));
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnack('Copied!', Colors.green);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('PAY FEES',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.yellowAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _stepCard(
                    step: '1',
                    color: Colors.yellowAccent,
                    title: 'Send Payment',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Send exactly this amount to:',
                            style:
                                TextStyle(color: Colors.white54, fontSize: 13)),
                        const SizedBox(height: 16),
                        _infoRow('Easypaisa', _easypaisaNumber,
                            Colors.greenAccent, copyable: true),
                        const SizedBox(height: 10),
                        _infoRow('Account Name', _accountName, Colors.white70),
                        const SizedBox(height: 10),
                        _infoRow('Amount',
                            'Rs ${_amount.toStringAsFixed(0)}', Colors.yellowAccent),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.redAccent.withOpacity(0.2)),
                          ),
                          child: const Text(
                            '⚠️  You MUST include the reference code in the remarks/description when sending',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _stepCard(
                    step: '2',
                    color: Colors.blueAccent,
                    title: 'Use This Reference Code',
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () => _copyToClipboard(_referenceCode),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: Colors.blueAccent.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _referenceCode,
                                    style: const TextStyle(
                                      color: Colors.blueAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.copy_rounded,
                                    color: Colors.blueAccent, size: 18),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Tap to copy. Paste this in the remarks field when sending money.',
                          style:
                              TextStyle(color: Colors.white38, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _stepCard(
                    step: '3',
                    color: Colors.purpleAccent,
                    title: 'Upload Screenshot',
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _pickScreenshot,
                          child: Container(
                            width: double.infinity,
                            height: _screenshotFile != null ? null : 130,
                            decoration: BoxDecoration(
                              color: Colors.purpleAccent.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _screenshotFile != null
                                    ? Colors.purpleAccent.withOpacity(0.4)
                                    : Colors.purpleAccent.withOpacity(0.2),
                              ),
                            ),
                            child: _screenshotFile != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.file(_screenshotFile!,
                                        fit: BoxFit.cover),
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.upload_rounded,
                                          color: Colors.purpleAccent, size: 36),
                                      SizedBox(height: 10),
                                      Text('Tap to upload screenshot',
                                          style: TextStyle(
                                              color: Colors.white54,
                                              fontSize: 13)),
                                    ],
                                  ),
                          ),
                        ),
                        if (_screenshotFile != null) ...[
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: _pickScreenshot,
                            child: const Text('Change screenshot',
                                style: TextStyle(
                                    color: Colors.purpleAccent, fontSize: 12)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellowAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.black, strokeWidth: 2.5))
                          : const Text('I HAVE PAID',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  letterSpacing: 1)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _stepCard({
    required String step,
    required Color color,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
                child: Center(
                  child: Text(step,
                      style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, Color valueColor,
      {bool copyable = false}) {
    return Row(
      children: [
        Text('$label: ',
            style: const TextStyle(color: Colors.white38, fontSize: 13)),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  color: valueColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ),
        if (copyable)
          GestureDetector(
            onTap: () => _copyToClipboard(value),
            child: const Icon(Icons.copy_rounded,
                color: Colors.white38, size: 16),
          ),
      ],
    );
  }
}