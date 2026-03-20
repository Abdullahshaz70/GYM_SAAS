import 'package:cloud_firestore/cloud_firestore.dart';

enum GymAccessLevel {
  full,       // status=active, isSaaSActive=true
  readOnly,   // status=active, isSaaSActive=false  (owner/staff only)
  locked,     // status != active (everyone blocked)
}

class GymStatusResult {
  final GymAccessLevel access;
  final String message;
  final String? status;
  final bool isSaaSActive;

  const GymStatusResult({
    required this.access,
    required this.message,
    this.status,
    this.isSaaSActive = true,
  });
}

class GymStatusService {
  static Future<GymStatusResult> checkAccess(String gymId) async {
    final doc = await FirebaseFirestore.instance
        .collection('gyms')
        .doc(gymId)
        .get();

    if (!doc.exists) {
      return const GymStatusResult(
        access: GymAccessLevel.locked,
        message: 'Gym not found.',
      );
    }

    final data = doc.data()!;
    final status = (data['status'] ?? 'active').toString().toLowerCase();
    final isSaaSActive = data['isSaaSActive'] ?? true;

    if (status != 'active') {
      final messages = {
        'suspended': 'This gym has been temporarily suspended. Please contact support.',
        'blocked':   'This gym has been blocked. Please contact support.',
        'closed':    'This gym is permanently closed.',
      };
      return GymStatusResult(
        access: GymAccessLevel.locked,
        message: messages[status] ?? 'This gym is currently unavailable.',
        status: status,
        isSaaSActive: isSaaSActive,
      );
    }

    if (!isSaaSActive) {
      return GymStatusResult(
        access: GymAccessLevel.readOnly,
        message: 'Digital platform access is disabled for this gym.',
        status: status,
        isSaaSActive: false,
      );
    }

    return GymStatusResult(
      access: GymAccessLevel.full,
      message: '',
      status: status,
      isSaaSActive: true,
    );
  }
}