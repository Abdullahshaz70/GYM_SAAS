import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/chat_service.dart';
import 'chat_screen.dart';

class NewConversationScreen extends StatefulWidget {
  final String gymId;
  final String userRole;

  const NewConversationScreen({
    required this.gymId,
    required this.userRole,
  });

  @override
  State<NewConversationScreen> createState() => _NewConversationScreenState();
}

class _NewConversationScreenState extends State<NewConversationScreen> {
  final _chatService = ChatService();
  final _auth = FirebaseAuth.instance;
  late Future<List<Map<String, dynamic>>> _usersFuture;
  String _currentUserName = '';
  String _currentUserRole = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
    _usersFuture = _chatService.getGymUsers(
      _auth.currentUser?.uid ?? '',
      widget.gymId,
      widget.userRole,
    );
  }

  Future<void> _loadCurrentUserData() async {
    final userDetails =
        await _chatService.getUserDetails(_auth.currentUser?.uid ?? '');
    setState(() {
      _currentUserName = userDetails['name'] as String? ?? 'User';
      _currentUserRole = userDetails['role'] as String? ?? 'member';
    });
  }

  void _startConversation(Map<String, dynamic> otherUser) async {
    final conversationId = await _chatService.getOrCreateConversation(
      userId1: _auth.currentUser?.uid ?? '',
      userId2: otherUser['id'] as String,
      gymId: widget.gymId,
    );

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            gymId: widget.gymId,
            conversationId: conversationId,
            otherUserId: otherUser['id'] as String,
            otherUserName: otherUser['name'] as String? ?? 'User',
            otherUserRole: otherUser['role'] as String? ?? 'member',
            currentUserRole: widget.userRole,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Start a Conversation'),
        backgroundColor: Colors.grey[900],
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading users: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No users available to chat with',
                style: TextStyle(color: Colors.grey[400]),
              ),
            );
          }

          final users = snapshot.data!;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final userName = user['name'] as String? ?? 'User';
              final userRole = user['role'] as String? ?? 'member';
              final photoUrl = user['photoUrl'] as String?;

              return GestureDetector(
                onTap: () => _startConversation(user),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border:
                        Border(bottom: BorderSide(color: Colors.grey[800]!)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.yellowAccent,
                        backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                            ? NetworkImage(photoUrl)
                            : null,
                        child: photoUrl == null || photoUrl.isEmpty
                            ? Text(
                                userName[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: userRole == 'owner'
                                    ? Colors.blue[900]
                                    : userRole == 'staff'
                                        ? Colors.green[900]
                                        : Colors.grey[800],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                userRole.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward, color: Colors.grey[500]),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
