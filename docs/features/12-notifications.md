# Feature: Push Notifications & Scheduled Reminders

## Current Implementation
**Module:** `notifications/`
**Backend:** Firebase Functions
**Data Model:** `notification_type.dart`

### FCM Setup
- `firebase_messaging` ^15.1.3
- `flutter_local_notifications` ^18.0.1
- Each user stores their FCM token in `users/{userId}.fcmToken`
- Token refreshed on app lifecycle events

### Notification Types
- `chat_mention` — Mentioned in chat
- `service_people_updated` — Assigned to event
- `service_steps_updated` — Event steps changed
- `friday_liturgy` — Friday liturgy reminder
- `monday_prayer` — Monday prayer meeting reminder
- `elo_availability` — ELO availability reminder

### Scheduled Reminders (CURRENT—Presbyterian-specific)

| Function | Schedule | Purpose |
|---|---|---|
| `fridayLiturgyReminder` | Every Friday 9am (São Paulo) | Check Sunday events, notify responsible societies about liturgy |
| `mondayPrayerMeetingReminder` | Specific schedule | Remind about Monday prayer meetings |
| `eloAvailabilityReminder` | Weekly | Check ELO availability for next month |

### Real-time Triggers

| Function | Trigger | Purpose |
|---|---|---|
| `onMessageCreated` | New event chat message | Notify @mentioned users |
| `onSocietyMessageCreated` | New society chat message | Notify @mentioned users |
| `onServicePeopleUpdated` | Event people changed | Notify newly assigned members |
| `onServiceStepsUpdated` | Event steps changed | Notify affected members |

### Notification Preferences
- User can disable specific notification types
- Stored in `users/{userId}.disabled_notifications` (list of type strings)
- Settings page has toggles for each type
- FCM notifications check disabled list before sending

### Multi-tenant Changes Needed
- All reminder functions iterate all active churches and check `reminderRules` in settings
- Reminders become per-church configurable schedule, not hardcoded
- FCM token management stays the same
- Notification types stay the same
- Preferences stored per-user, scoped to church membership
- Real-time triggers gain `churchId` in their parent document paths:
  - `churches/{churchId}/events/{eventId}/messages/{messageId}`
  - `churches/{churchId}/societies/{societyId}/messages/{messageId}`
  - `churches/{churchId}/events/{eventId}` (people/steps updates)
