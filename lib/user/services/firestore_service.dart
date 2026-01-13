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
        .map((d) => "${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}")
        .toSet();
  }

  Future<void> markAttendance(String gymId, String uid) async {
    await _firestore.collection('gyms').doc(gymId).collection('attendance').add({
      "memberId": uid,
      "status": "present",
      "markedBy": "member",
      "timestamp": FieldValue.serverTimestamp(),
    });
  }


    Future<List<Map<String, dynamic>>> getGymGateways(String gymId) async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('gyms')
        .doc(gymId)
        .collection('merchantCredentials')
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  } catch (e) {
    return [];
  }
}




}
