# Feature: ELO (Equipe de Louvor) — Default Team

## Current Implementation
Part of `EventsRepository` + `event_editor_page.dart` + `worship_team_availability_modal.dart` + `elo_availability_status_page.dart` + `weekly_team_assignments_page.dart`

### How ELO Works

**Roles within ELO** (currently fixed categories in `EventPeople`):
- `elo` — General worship team members
- `preacher` — Speakers/preachers
- `lead` — Service leaders
- `soundImage` — Sound/image tech
- `diaconia` — Deacons
- `eloWithInstruments` — `Map<userId, Map<instrument, talkBack>>` — ELO members with instrument assignments + talkback permission

**Availability System:**
- Members select which Sundays they're available (next month)
- Stored as `users/{userId}.availability` — list of Timestamps
- Modal shows calendar with Sunday availability counts
- Per-date check: `hasAvailabilityForDate(userId, date)`

**Event Assignment:**
- Event editor has a people assignment screen
- Shows available vs unavailable members for each role
- Assign members by tapping their avatar
- Weekly team assignments page (`weekly_team_assignments_page.dart`) shows roster overview

**Notifications:**
- When people are assigned to an event, they're notified via `onServicePeopleUpdated` function
- When event steps change, `onServiceStepsUpdated` notifies assigned members
- Friday liturgy reminder (scheduled) — checks who's responsible for liturgy on Sunday events
- Elo availability reminder — weekly check for next month's availability

### Pages
- `worship_team_availability_modal.dart` — Availability selection modal
- `elo_availability_status_page.dart` — View all ELO availability counts
- `weekly_team_assignments_page.dart` — Weekly roster overview
- `event_editor_page.dart` — Event editing with people assignment

### Firestore Collections
- `users/{userId}.availability` — List[Timestamp] of available Sundays
- `services/{eventId}.people` — EventPeople object with role assignments
- `services/{eventId}.people.eloWithInstruments` — Nested map: `Map<userId, Map<instrument, bool>>`

### Multi-tenant Changes Needed
- **ELO is the ONLY default group** — every church gets one automatically
- Roles within ELO become dynamic: church admin defines role types (not fixed fields)
- `eloWithInstruments` stays as instrument/talkback sub-config
- Availability system stays the same structure
- Weekly team assignments page stays the same UI
- Reminders become per-church configurable (not hardcoded Friday/Monday)
- Notification triggers need `churchId` in their parent document path
