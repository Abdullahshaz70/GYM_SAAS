import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AttendanceQrSheet extends StatelessWidget {
  const AttendanceQrSheet({
    super.key,
    required this.gymId,
    required this.onCopyToken,
  });

  final String gymId;
  final ValueChanged<String> onCopyToken;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('gyms')
          .doc(gymId)
          .snapshots(),
      builder: (context, snapshot) {
        final token = snapshot.hasData
            ? ((snapshot.data!.data()
                    as Map<String, dynamic>)['currentAttendanceQrToken'] ??
                'no-token')
            : 'loading...';

        return _QrBottomSheet(
          icon: Icons.qr_code_rounded,
          title: 'Member Check-In',
          subtitle: 'Scan to mark attendance',
          qrData: token,
          tokenLabel: 'Active Token',
          tokenValue: token,
          onCopy: () => onCopyToken(token),
        );
      },
    );
  }
}

class RegistrationQrSheet extends StatelessWidget {
  const RegistrationQrSheet({
    super.key,
    required this.gymCode,
    required this.onCopyCode,
  });

  final String gymCode;
  final VoidCallback onCopyCode;

  @override
  Widget build(BuildContext context) {
    return _QrBottomSheet(
      icon: Icons.qr_code_scanner_rounded,
      title: 'Gym Access Code',
      subtitle: 'Members scan this to join your gym',
      qrData: gymCode,
      tokenLabel: 'Gym Code',
      tokenValue: gymCode,
      largeToken: true,
      onCopy: onCopyCode,
    );
  }
}

// ─── Shared private sheet layout ─────────────────────────────────────────────

class _QrBottomSheet extends StatelessWidget {
  const _QrBottomSheet({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.qrData,
    required this.tokenLabel,
    required this.tokenValue,
    required this.onCopy,
    this.largeToken = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String qrData;
  final String tokenLabel;
  final String tokenValue;
  final VoidCallback onCopy;
  final bool largeToken;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 20),
            // Icon + title
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.yellowAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.yellowAccent, size: 26),
            ),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle,
                style:
                    const TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 24),
            // QR code
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.yellowAccent.withOpacity(0.12),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200,
                eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square, color: Colors.black),
                dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.circle,
                    color: Colors.black),
              ),
            ),
            const SizedBox(height: 20),
            // Token / code row
            GestureDetector(
              onTap: onCopy,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Text(tokenLabel,
                            style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1)),
                        const SizedBox(height: 4),
                        Text(
                          tokenValue,
                          style: TextStyle(
                            color: Colors.yellowAccent,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: largeToken ? 22 : 14,
                            letterSpacing: largeToken ? 4 : 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.copy_rounded,
                        color: Colors.white24, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellowAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Done',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}