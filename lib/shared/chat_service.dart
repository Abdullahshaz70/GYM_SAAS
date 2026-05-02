import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get or create a conversation between two users within a gym
  Future<String> getOrCreateConversation({
    required String userId1,
    required String userId2,
    required String gymId,
  }) async {
    // Create a unique ID for the conversation (sorted to ensure consistency)
    final List<String> userIds = [userId1, userId2]..sort();
    final conversationId =
        '${userIds[0]}_${userIds[1]}';

    final docRef = _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('conversations')
        .doc(conversationId);
    
    final doc = await docRef.get();

    if (!doc.exists) {
      // Create new conversation
      await docRef.set({
        'participants': [userId1, userId2],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessage': '',
      });
    }

    return conversationId;
  }

  /// Send a message in a conversation
  Future<void> sendMessage({
    required String gymId,
    required String conversationId,
    required String message,
    required String senderName,
    required String senderRole,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore
          .collection('gyms')
          .doc(gymId)
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .add({
        'senderId': currentUser.uid,
        'senderName': senderName,
        'senderRole': senderRole,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // Update conversation's last message info
      await _firestore
          .collection('gyms')
          .doc(gymId)
          .collection('conversations')
          .doc(conversationId)
          .update({
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessage': message,
        'lastSenderId': currentUser.uid,
      });
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  /// Get all conversations for current user in a gym
  Stream<QuerySnapshot> getConversationsStream(String userId, String gymId) {
    return _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .snapshots();
  }

  /// Get messages for a conversation
  Stream<QuerySnapshot> getMessagesStream(String gymId, String conversationId) {
    return _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(
    String gymId,
    String conversationId,
    String userId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('gyms')
          .doc(gymId)
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .get();

      final toMark = snapshot.docs
          .where((doc) => (doc.data()['senderId'] as String?) != userId)
          .toList();

      if (toMark.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in toMark) {
          batch.update(doc.reference, {'isRead': true});
        }
        await batch.commit();
      }
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  /// Get unread message count for a user in a gym
  Stream<int> getUnreadCountStream(String userId, String gymId) {
    return _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .snapshots()
        .asyncMap((conversations) async {
      int totalUnread = 0;
      for (final conv in conversations.docs) {
        final conversationId = conv.id;
        final unreadSnap = await _firestore
            .collection('gyms')
            .doc(gymId)
            .collection('conversations')
            .doc(conversationId)
            .collection('messages')
            .where('isRead', isEqualTo: false)
            .get();
        totalUnread += unreadSnap.docs
            .where((d) => (d.data()['senderId'] as String?) != userId)
            .length;
      }
      return totalUnread;
    });
  }

  /// Get user details for displaying in chat
  Future<Map<String, dynamic>> getUserDetails(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data() ?? {};
  }

  /// Get all gym members/staff for starting a new conversation
  Future<List<Map<String, dynamic>>> getGymUsers(
    String currentUserId,
    String gymId,
    String userRole,
  ) async {
    final users = <Map<String, dynamic>>[];

    if (userRole == 'member') {
      // Members can chat with owner and staff
      final membersSnap = await _firestore
          .collection('users')
          .where('gymId', isEqualTo: gymId)
          .where('role', whereIn: ['owner', 'staff'])
          .get();

      for (final doc in membersSnap.docs) {
        if (doc.id != currentUserId) {
          users.add({
            'id': doc.id,
            ...doc.data(),
          });
        }
      }
    } else if (userRole == 'staff') {
      // Staff can chat with owner and members
      final usersSnap = await _firestore
          .collection('users')
          .where('gymId', isEqualTo: gymId)
          .get();

      for (final doc in usersSnap.docs) {
        if (doc.id != currentUserId) {
          users.add({
            'id': doc.id,
            ...doc.data(),
          });
        }
      }
    } else if (userRole == 'owner') {
      // Owner can chat with all staff and members
      final usersSnap = await _firestore
          .collection('users')
          .where('gymId', isEqualTo: gymId)
          .get();

      for (final doc in usersSnap.docs) {
        if (doc.id != currentUserId) {
          users.add({
            'id': doc.id,
            ...doc.data(),
          });
        }
      }
    }

    return users;
  }

  /// Delete a conversation (only for testing)
  Future<void> deleteConversation(String gymId, String conversationId) async {
    // Delete all messages first
    final messages = await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .get();

    for (final doc in messages.docs) {
      await doc.reference.delete();
    }

    // Delete conversation
    await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('conversations')
        .doc(conversationId)
        .delete();
  }
}
