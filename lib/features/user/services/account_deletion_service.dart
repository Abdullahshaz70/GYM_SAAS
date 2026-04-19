import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountDeletionService {
  final _fs = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Returns the feeStatus of the member in their gym.
  /// Returns null if the member document doesn't exist.
  Future<String?> getMemberFeeStatus(String gymId, String uid) async {
    final doc = await _fs
        .collection('gyms')
        .doc(gymId)
        .collection('members')
        .doc(uid)
        .get();
    if (!doc.exists) return null;
    return (doc.data()?['feeStatus'] as String?) ?? 'unpaid';
  }

  /// Performs the full soft-delete sequence:
  /// 1. Anonymizes users/{uid} and marks isDeleted on both docs (atomic batch)
  /// 2. Writes an owner notification if fees are outstanding
  /// 3. Deletes the Firebase Auth account (caller must reauthenticate first)
  Future<void> deleteMemberAccount({
    required String gymId,
    required String uid,
    required String memberName,
    required String feeStatus,
  }) async {
    final needsOwnerNotif =
        feeStatus == 'unpaid' || feeStatus == 'pending';

    final now = FieldValue.serverTimestamp();
    final batch = _fs.batch();

    // 1. Anonymize + flag users/{uid}
    // Email is cleared so the address is free for re-registration.
    final userRef = _fs.collection('users').doc(uid);
    batch.update(userRef, {
      'name': 'Deleted Member',
      'email': 'deleted_$uid@deleted.invalid',
      'contactNumber': '',
      'isDeleted': true,
      'deletedAt': now,
    });

    // 2. Flag gyms/{gymId}/members/{uid}
    final memberRef = _fs
        .collection('gyms')
        .doc(gymId)
        .collection('members')
        .doc(uid);
    batch.update(memberRef, {
      'isDeleted': true,
      'deletedAt': now,
    });

    // 3. Write owner notification if fees are outstanding
    if (needsOwnerNotif) {
      final notifRef = _fs
          .collection('gyms')
          .doc(gymId)
          .collection('notifications')
          .doc();
      batch.set(notifRef, {
        'type': 'member_deleted_unpaid',
        'message':
            'Member "$memberName" deleted their account with $feeStatus fees.',
        'memberId': uid,
        'createdAt': now,
        'isRead': false,
      });
    }

    // 4. Commit all Firestore writes atomically
    await batch.commit();

    // 5. Delete Firebase Auth account (must be last).
    // The caller always re-authenticates before calling this method,
    // so requires-recent-login should never occur.
    await _auth.currentUser!.delete();
  }

  /// Re-authenticates with email + password.
  /// Call this before [deleteMemberAccount] to ensure a fresh session.
  Future<void> reauthenticate({
    required String email,
    required String password,
  }) async {
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await _auth.currentUser!.reauthenticateWithCredential(credential);
  }
}
