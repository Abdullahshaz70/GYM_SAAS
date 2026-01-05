import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';

class GymQrScreen extends StatefulWidget {
  final String gymId;
  const GymQrScreen({super.key, required this.gymId});

  @override
  State<GymQrScreen> createState() => _GymQrScreenState();
}

class _GymQrScreenState extends State<GymQrScreen> {
  String qrData = "";
  DateTime? expiresAt;

  @override
  void initState() {
    super.initState();
    _generateOrLoadQr();
  }

  Future<void> _generateOrLoadQr() async {
    final gymRef =
        FirebaseFirestore.instance.collection('gyms').doc(widget.gymId);
    final doc = await gymRef.get();

    if (doc.exists) {
      final data = doc.data()!;
      final exp = (data['qrExpiresAt'] as Timestamp?)?.toDate();

      if (exp != null && exp.isAfter(DateTime.now())) {
        _setQr(data['currentQrToken'], exp);
        return;
      }
    }

    await _generateNewQr();
  }

  Future<void> _generateNewQr() async {
    final token = const Uuid().v4();
    final expiry = DateTime.now().add(const Duration(hours: 24));

    await FirebaseFirestore.instance
        .collection('gyms')
        .doc(widget.gymId)
        .update({
      'currentQrToken': token,
      'qrExpiresAt': Timestamp.fromDate(expiry),
      'lastQrGeneratedAt': Timestamp.now(),
    });

    _setQr(token, expiry);
  }

  void _setQr(String token, DateTime expiry) {
    setState(() {
      qrData = jsonEncode({
        'gymId': widget.gymId,
        'token': token,
      });
      expiresAt = expiry;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gym Attendance QR")),
      body: Center(
        child: qrData.isEmpty
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  QrImageView(
                    data: qrData,
                    size: 250,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Expires at: ${expiresAt.toString()}",
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _generateNewQr,
                    child: const Text("Refresh QR"),
                  )
                ],
              ),
      ),
    );
  }
}
