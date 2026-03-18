import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  Future<Map<String, dynamic>?> getMemberData(String gymId, String uid) async {
    final doc = await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('members')
        .doc(uid)
        .get();
    return doc.exists ? doc.data() : null;
  }

  Future<Set<String>> getAttendance(String gymId, String uid) async {
    final snap = await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('attendance')
        .where('memberId', isEqualTo: uid)
        .get();

    return snap.docs
        .map((doc) => (doc['timestamp'] as Timestamp).toDate())
        .map((d) =>
            "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}")
        .toSet();
  }

  Future<void> markAttendance(String gymId, String uid) async {
    await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('attendance')
        .add({
      "memberId": uid,
      "status": "present",
      "markedBy": "member",
      "timestamp": FieldValue.serverTimestamp(),
    });
  }

  Stream<DocumentSnapshot> watchPayment(String gymId, String paymentId) {
    return _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('payments')
        .doc(paymentId)
        .snapshots();
  }

  Future<Map<String, dynamic>> getOwnerBalance(String gymId) async {
    final configDoc = await getCompanyConfig();
    final platformFeePercent =
        (configDoc?['platformFeePercent'] as num?)?.toDouble() ?? 10.0;

    final paymentsSnap = await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('payments')
        .where('status', isEqualTo: 'completed')
        .get();

    double totalCollected = 0;
    for (final doc in paymentsSnap.docs) {
      totalCollected += (doc['amount'] as num).toDouble();
    }

    final payoutsSnap = await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('payouts')
        .where('status', isEqualTo: 'processed')
        .get();

    double totalPaidOut = 0;
    for (final doc in payoutsSnap.docs) {
      totalPaidOut += (doc['amount'] as num).toDouble();
    }

    final platformFee = totalCollected * (platformFeePercent / 100);
    final available = totalCollected - platformFee - totalPaidOut;

    return {
      'totalCollected': totalCollected,
      'platformFee': platformFee,
      'platformFeePercent': platformFeePercent,
      'totalPaidOut': totalPaidOut,
      'available': available < 0 ? 0.0 : available,
    };
  }

  Future<void> requestPayout({
    required String gymId,
    required double amount,
    required String accountType,
    required String accountNumber,
  }) async {
    await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('payouts')
        .add({
      'amount': amount,
      'accountType': accountType,
      'accountNumber': accountNumber,
      'status': 'pending',
      'requestedAt': FieldValue.serverTimestamp(),
      'processedAt': null,
    });
  }

  Future<List<Map<String, dynamic>>> getPayouts(String gymId) async {
    final snap = await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('payouts')
        .orderBy('requestedAt', descending: true)
        .get();

    return snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  String generateReferenceCode(String gymId, String memberId) {
  final ts = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
  return 'REF-${gymId.substring(0, 4).toUpperCase()}-$ts';
}

Future<Map<String, dynamic>?> getCompanyConfig() async {
  try {
    final doc = await _firestore.collection('config').doc('company').get();
    return doc.exists ? doc.data() : null;
  } catch (_) {
    return null;
  }
}

Future<String> createPayment({
  required String gymId,
  required String memberId,
  required double amount,
  required String plan,
  required String referenceCode,
  required String screenshotUrl,
}) async {
  final now = DateTime.now();
  final nowTs = Timestamp.fromDate(now);

  int months = 1;
  if (plan == '6 Months') months = 6;
  if (plan == 'Yearly') months = 12;
  final validUntil =
      Timestamp.fromDate(DateTime(now.year, now.month + months, now.day));

  final ref = await _firestore
      .collection('gyms')
      .doc(gymId)
      .collection('payments')
      .add({
    'memberId': memberId,
    'amount': amount,
    'method': 'easypaisa',
    'markedBy': 'online',
    'verified': false,
    'status': 'pending',
    'referenceCode': referenceCode,
    'screenshot': screenshotUrl,
    'plan': plan,
    'validUntil': validUntil,
    'timestamp': nowTs,
    'createdAt': nowTs,
    'updatedAt': nowTs,
    'transactionId': referenceCode,
  });

  // Also update member feeStatus to 'pending'
  await _firestore
      .collection('gyms')
      .doc(gymId)
      .collection('members')
      .doc(memberId)
      .update({'feeStatus': 'pending'});

  return ref.id;
}

}