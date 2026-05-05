# Feature: Members (People Management)

## Current Implementation
**Module:** `people/`
**Repository:** `lib/src/modules/people/data/people_repository.dart`

### Data Flow
- People are `UserModel` instances — the app queries the `users` collection filtered by the current user
- Repository provides methods for fetching, inviting, and managing people

### Pages
- `people_section.dart` — Tab/list of all members
- `widgets/user_chip.dart` — Reusable user avatar+name chip
- `widgets/invite_person_sheet.dart` — Invite new person (email/link)
- `widgets/people_selector_sheet.dart` — People picker used across the app

### Dependencies
- Reusable across all features: event assignment, society management, chat mentions
- Uses Firebase Auth user list or Firestore query for member directory

### Multi-tenant Changes Needed
- People becomes `churches/{churchId}/people/{personId}` — scoped to church
- Invite flow: church admin sends invite link/code, recipient joins church
- Add `churchId` to user profile on join
- Member count tracking for tier limits
- User chips stay the same
- People selector sheet stays the same but scoped to church members only
