import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String gymId;
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String otherUserRole;
  final String currentUserRole;

  const ChatScreen({
    required this.gymId,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserRole,
    required this.currentUserRole,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatService = ChatService();
  final _auth = FirebaseAuth.instance;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  String _currentUserName = '';
  String _currentUserRole = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
    _markMessagesAsRead();
  }

  Future<void> _loadCurrentUserData() async {
    final userDetails =
        await _chatService.getUserDetails(_auth.currentUser?.uid ?? '');
    setState(() {
      _currentUserName = userDetails['name'] as String? ?? 'User';
      _currentUserRole = userDetails['role'] as String? ?? 'member';
    });
  }

  Future<void> _markMessagesAsRead() async {
    await _chatService.markMessagesAsRead(
      widget.gymId,
      widget.conversationId,
      _auth.currentUser?.uid ?? '',
    );
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    if (_currentUserName.isEmpty) return;

    try {
      await _chatService.sendMessage(
        gymId: widget.gymId,
        conversationId: widget.conversationId,
        message: _messageController.text,
        senderName: _currentUserName,
        senderRole: _currentUserRole,
      );

      _messageController.clear();

      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUserName),
            Text(
              widget.otherUserRole.toUpperCase(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        backgroundColor: Colors.grey[900],
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessagesStream(
                widget.gymId,
                widget.conversationId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet. Start the conversation!',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  );
                }

                final messages = snapshot.data!.docs;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageDoc = messages[index];
                    final messageData =
                        messageDoc.data() as Map<String, dynamic>;
                    final senderId = messageData['senderId'] as String?;
                    final message = messageData['message'] as String?;
                    final senderName = messageData['senderName'] as String?;
                    final senderRole = messageData['senderRole'] as String?;
                    final timestamp =
                        messageData['timestamp'] as Timestamp?;
                    final isRead = messageData['isRead'] as bool? ?? false;
                    final isCurrentUser = senderId == currentUserId;

                    return Align(
                      alignment: isCurrentUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: isCurrentUser
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            if (!isCurrentUser)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4, left: 8),
                                child: Text(
                                  '$senderName ($senderRole)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isCurrentUser
                                    ? Colors.yellowAccent
                                    : Colors.grey[800],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message ?? '',
                                    style: TextStyle(
                                      color: isCurrentUser
                                          ? Colors.black
                                          : Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _formatMessageTime(timestamp),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isCurrentUser
                                              ? Colors.black54
                                              : Colors.grey[500],
                                        ),
                                      ),
                                      if (isCurrentUser) ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          isRead
                                              ? Icons.done_all
                                              : Icons.done,
                                          size: 14,
                                          color: isRead
                                              ? Colors.blue
                                              : Colors.black54,
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration:
                BoxDecoration(border: Border(top: BorderSide(color: Colors.grey[800]!))),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      maxLines: null,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.yellowAccent,
                    radius: 24,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.black),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMessageTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final dateTime = timestamp.toDate();
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
