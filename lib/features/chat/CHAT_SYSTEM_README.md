# In-App Chat System Documentation

## Overview

A real-time messaging system that enables communication between gym members, staff, and owners. The system uses Firebase Firestore for message storage and real-time listeners for instant notifications.

## Features

✅ **Real-time Messaging** - Messages appear instantly across all clients using Firestore StreamBuilders
✅ **Role-Based Access** - Members can chat with owner and staff; staff can chat with members and owner; owners can chat with all
✅ **Conversation Management** - Auto-create conversations on first message
✅ **User Discovery** - Browse available contacts based on role permissions
✅ **Message Timestamps** - View when messages were sent
✅ **Sender Information** - See sender name and role in each message
✅ **Read Status Tracking** - Track which messages have been read
✅ **Gym-Scoped** - All conversations are isolated per gym

## File Structure

```
lib/
├── shared/
│   └── chat_service.dart              # Main chat service with Firestore operations
├── features/
│   └── chat/
│       ├── conversations_list.dart    # List of all conversations for user
│       ├── chat_screen.dart           # Individual conversation chat interface
│       └── new_conversation_screen.dart # Screen to start new conversation
```

## Firestore Schema

### Gym-Nested Structure
All conversations are nested under each gym for better organization and security:

```
gyms/{gymId}/
├── conversations/{conversationId}/
│   ├── participants: [string]          # UIDs of 2 participants
│   ├── createdAt: timestamp            # When conversation started
│   ├── lastMessageTime: timestamp      # Last message time
│   ├── lastMessage: string             # Preview of last message
│   ├── lastSenderId: string            # Who sent last message
│   └── messages/{messageId}/
│       ├── senderId: string            # UID of sender
│       ├── senderName: string          # Display name of sender
│       ├── senderRole: string          # Role (owner/staff/member)
│       ├── message: string             # Message content
│       ├── timestamp: timestamp        # When message was sent
│       └── isRead: boolean             # Read status
```

## Usage Guide

### For Owners
1. Tap the **mail icon** in the AppBar of the Owner Dashboard
2. View all conversations with staff and members in your gym
3. Tap any conversation to open chat
4. Type a message and tap send button
5. Or tap the **+** FAB to start a new conversation

### For Staff
1. Tap the **mail icon** in the AppBar of the Staff Dashboard
2. View conversations with the gym owner and members
3. Select a conversation or create a new one
4. Send and receive messages

### For Members
1. Tap the **mail icon** in the AppBar of the Member Dashboard
2. View conversations with gym owner and staff
3. Start new conversations or continue existing ones
4. Communicate about fees, attendance, or gym concerns

## Role-Based Permissions

| Role | Can Chat With |
|------|---------------|
| **Owner** | All staff + all members in their gym |
| **Staff** | Owner + all members in their gym |
| **Member** | Owner + staff in their gym |

## ChatService API Reference

### Core Methods

#### `getOrCreateConversation()`
```dart
Future<String> getOrCreateConversation({
  required String userId1,
  required String userId2,
  required String gymId,
})
```
Creates or retrieves existing conversation. Returns conversation ID.

#### `sendMessage()`
```dart
Future<void> sendMessage({
  required String conversationId,
  required String message,
  required String senderName,
  required String senderRole,
})
```
Sends a message and updates conversation metadata.

#### `getConversationsStream()`
```dart
Stream<QuerySnapshot> getConversationsStream(String userId, String gymId)
```
Real-time stream of all conversations for a user in a gym.

#### `getMessagesStream()`
```dart
Stream<QuerySnapshot> getMessagesStream(String conversationId)
```
Real-time stream of all messages in a conversation.

#### `markMessagesAsRead()`
```dart
Future<void> markMessagesAsRead(String conversationId, String userId)
```
Marks all unread messages as read for a user.

#### `getUnreadCountStream()`
```dart
Stream<int> getUnreadCountStream(String userId, String gymId)
```
Real-time stream of unread message count.

#### `getGymUsers()`
```dart
Future<List<Map<String, dynamic>>> getGymUsers(
  String currentUserId,
  String gymId,
  String userRole,
)
```
Gets list of users available to chat with based on role.

## Implementation Details

### Conversation ID Generation
Conversation IDs are deterministic and created by sorting both user UIDs:
```
conversationId = '${sortedUserIds[0]}_${sortedUserIds[1]}'
```
This ensures the same conversation ID regardless of which user initiates. The gym context is automatically provided by the nested path `gyms/{gymId}/conversations/{conversationId}`.

### Real-Time Updates
All screens use Firebase Firestore `StreamBuilder` for real-time updates:
- Messages appear instantly as they're sent
- Conversation list updates with latest message and timestamp
- No polling or manual refresh needed

### Message Bubbles
- **Sent messages**: Yellow background (Colors.yellowAccent), aligned right
- **Received messages**: Gray background (Colors.grey[800]), aligned left
- Sender info shown above received messages
- Timestamp shown below each message

## Security Considerations

### Firestore Rules Recommendation
Since conversations are nested under each gym, security rules are simpler and more efficient:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Gym document - users can read their own gym's data
    match /gyms/{gymId} {
      allow read: if request.auth.uid in get(/databases/$(database)/documents/users/$(request.auth.uid)).data.gymId;
      
      // Conversations - users can read/write conversations they're part of
      match /conversations/{conversationId} {
        allow read, create: if request.auth.uid in resource.data.participants ||
                              request.auth.uid in request.resource.data.participants;
        allow update: if request.auth.uid in resource.data.participants;
        
        // Messages - users can read/write in conversations they're part of
        match /messages/{messageId} {
          allow read, create: if request.auth.uid in get(/databases/$(database)/documents/gyms/$(gymId)/conversations/$(conversationId)).data.participants;
          allow update: if request.auth.uid == resource.data.senderId;
        }
      }
    }
  }
}
```

### Benefits of Gym-Nested Structure
- **Simpler Security Rules**: No need to check `gymId` field; naturally scoped to gym
- **Data Isolation**: Conversations automatically scoped to their gym
- **Cascade Deletion**: Deleting a gym automatically cascades to conversations
- **Better Organization**: All gym data (members, payments, attendance, conversations) in one place
- **Easier Access Control**: Can enforce gym membership checks at collection level

## UI Components

### ConversationsListScreen
Main screen showing all conversations for the user. Features:
- Conversation list with last message preview
- Last message timestamp
- Avatar with first letter of contact name
- Empty state with option to start new conversation
- Floating action button to create new conversation

### ChatScreen
Individual conversation interface. Features:
- Message list with sender info and timestamps
- Message input field with send button
- Auto-scroll to latest message
- Sender role displayed in messages
- Dark theme with yellow accent for sent messages

### NewConversationScreen
Browse and select user to start conversation. Features:
- Searchable list of users (filtered by role permissions)
- User role displayed as badge
- Quick navigation to start chatting

## Known Limitations

1. **No message search** - Searching past messages not implemented
2. **No message editing** - Messages cannot be edited after sending
3. **No message deletion** - Messages cannot be deleted
4. **No media sharing** - Text-only messaging
5. **No typing indicators** - Doesn't show when someone is typing
6. **No notifications** - Chat messages don't trigger push notifications (Firebase Messaging initialized but not connected)

## Future Enhancements

- [ ] Push notifications for new messages
- [ ] Message search functionality
- [ ] Typing indicators
- [ ] Read receipts (double checkmarks)
- [ ] Message reactions/emojis
- [ ] Media sharing (images, PDFs)
- [ ] Group conversations (multiple participants)
- [ ] Voice/audio messages
- [ ] Message pinning
- [ ] Chat themes/customization

## Testing

### Test Scenarios

1. **Member to Owner**
   - Log in as member
   - Tap messages icon
   - Create conversation with owner
   - Send and receive messages

2. **Staff to Multiple Members**
   - Log in as staff
   - Create conversations with different members
   - Verify can chat with each independently

3. **Owner Broadcasts**
   - Log in as owner
   - Start conversations with staff and members
   - Send same message to multiple people

4. **Message Persistence**
   - Send messages
   - Log out
   - Log back in
   - Verify all messages still visible

5. **Role Isolation**
   - Verify member cannot see staff conversations
   - Verify staff cannot chat with members from other gyms
   - Verify owner can only chat within their gym

## Integration Points

### Owner Screen
- File: [lib/features/owner/gym_owner_screen.dart](../owner/gym_owner_screen.dart)
- Location: AppBar mail icon button
- Launches: `ConversationsListScreen(gymId, 'owner')`

### Staff Screen
- File: [lib/features/staff/gym_staff.dart](../staff/gym_staff.dart)
- Location: AppBar mail icon button
- Launches: `ConversationsListScreen(gymId, 'staff')`

### Member Screen
- File: [lib/features/user/gym_user.dart](../user/gym_user.dart)
- Location: AppBar mail icon button
- Launches: `ConversationsListScreen(gymId, 'member')`

## Troubleshooting

### Messages not appearing
- Check Firestore is initialized
- Verify user is logged in with valid UID
- Confirm both users are in same gym
- Check network connectivity

### Conversations not loading
- Verify user's `role` field exists in Firestore
- Check gym ID is set correctly in users collection
- Ensure Firestore rules allow reading conversations

### Permission errors
- Review Firestore security rules
- Verify user has correct role in `users/{uid}`
- Check gym ID matches in both user and conversation

## Contact & Support
For issues or feature requests related to the chat system, please update this documentation and notify the development team.
