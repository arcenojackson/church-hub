# Feature: Event-Level Chat

## Current Implementation
**Module:** `events/` (chat-related files)
**Repository:** `lib/src/modules/events/data/chat_repository.dart`

### Data Model (`ChatMessage`)
| Field | Type | Description |
|---|---|---|
| `text` | String | Message text |
| `userId` | String | Sender's Firebase Auth UID |
| `userName` | String | Sender's display name |
| `mentionedUserIds` | List<String>? | @-mentioned user IDs |
| `quotedMessageId` | String? | ID of quoted message |
| `quotedMessageText` | String? | Text of quoted message |
| `quotedMessageUserName` | String? | Name of quoted message author |

### Firestore Structure
```
services/{eventId}/messages/{messageId}
  userId, userName, text, mentionedUserIds, quotedMessageId, quotedMessageText, quotedMessageUserName, createdAt
```

### Backend (`onMessageCreated` function)
- Triggered on `services/{eventId}/messages/{messageId}` onCreate
- For each mentioned user: look up FCM token from `users/{userId}`
- Skip: same user (self-mention), no FCM token, notifications disabled
- Push notification: `@{sender} te mentionou` with event name + message preview

### Pages
- `event_chat_tab.dart` — Chat page tab within an event
- `widgets/chat_message_bubble.dart` — Message display (text, mentions, quotes)
- `widgets/chat_input_field.dart` — Input with @mention support
- `widgets/quoted_message_preview.dart` — Quoted message preview in input
- `widgets/message_search_bar.dart` — Search messages in event

### Dependencies
- `firebase_messaging` ^15.1.3
- Cloud Functions for push notifications

### Multi-tenant Changes Needed
- Chat scoped to `churches/{churchId}/events/{eventId}/messages/{messageId}`
- Cloud Function trigger path updated to include `churchId`
- @mention lookup scoped to church members only
- Search remains the same
- Quoted messages stay the same
