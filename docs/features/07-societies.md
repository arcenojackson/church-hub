# Feature: Societies/Groups Management

## Current Implementation
**Module:** `societies/`
**Repository:** `lib/src/modules/societies/data/societies_repository.dart`

### Data Model (`SocietyModel`)
| Field | Type | Description |
|---|---|---|
| `id` | String | Firestore doc ID |
| `name` | String | Group name |
| `description` | String | Group description |
| `color` | int | Custom color (hex int) |
| `userId` | String | Creator's ID |
| `membersIds` | List<String> | Member user IDs |
| `boardIds` | List<String> | Legacy: directorate IDs |
| `boardWithPositions` | Map<String, List<String>> | New format: position → userIds |
| `forumUsersByCategory` | Map<String, List<String>>? | Forum users by category |
| `vocaisIds` | List<String> | ELO singer IDs |
| `ministrosIds` | List<String> | ELO minister IDs |
| `calendarArtTemplate` | CalendarArtTemplate? | Custom calendar art template |

### Board Positions (CURRENT — hardcoded enum)
| Position | Label |
|---|---|
| `presidente` | Presidente |
| `vice` | Vice |
| `secretario` | Secretario(a) |
| `tesoureiro` | Tesoureiro(a) |

### Board Position Migration
- Old format: `board: List<String>` (just IDs)
- New format: `board: Map<position, List<userId>>`
- Repository handles both formats (backward compatibility)

### Forum Feature
- Societies can have a "forum" — categorized discussions
- `forumUsersByCategory`: Map of category name → list of user IDs
- Categories and access managed per-society

### Society Operations (from repository)
- Create society with name, description, color, members
- Update society details
- Delete society
- Add/remove members
- Add/remove board members with positions
- Manage forum categories and users

### Pages
- `societies_page.dart` — List of all societies the user belongs to
- `society_details_page.dart` — Member list, info, board display
- `society_chat_page.dart` — Full chat page for society discussions
- `elo_roles_config_page.dart` — ELO role configuration
- `widgets/society_form_sheet.dart` — Society creation/edit form

### Society Chat
- Subcollection: `societies/{societyId}/messages/{messageId}`
- Same `ChatMessage` model as event chat
- Cloud Function: `onSocietyMessageCreated` — mention notifications
- `SocietyChatRepository` manages society-specific messages

### VocaIs/Ministros
- Each society has `vocaisIds` (singers in ELO) and `ministrosIds` (ELO ministers who "ministram")
- Used for availability tracking and event assignment
- These are society-scoped — members of this society who are part of ELO

### Multi-tenant Changes Needed
- Societies scoped to `churches/{churchId}/societies/{societyId}`
- Board positions become configurable per-church (not hardcoded enum)
- `vocaisIds` and `ministrosIds` remain — they link to ELO roles
- Forum categories configurable per-society (not church-level)
- Society chat trigger path updated to include `churchId`
- Only available for Pro and Max tiers
