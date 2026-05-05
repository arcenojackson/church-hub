# Feature: Events & Service Planning

## Current Implementation
**Module:** `events/`
**Repository:** `lib/src/modules/events/data/events_repository.dart`

### Event Model (`EventModel`)
| Field | Type | Description |
|---|---|---|
| `id` | String | Firestore doc ID |
| `name` | String | Event name |
| `date` | DateTime | Event date |
| `start` | String | Start time ("HH:mm") |
| `steps` | List<EventStepModel> | Service steps/structure |
| `people` | EventPeople | Team assignments by role |
| `teams` | EventTeams | Society-level team assignments (liturgia, lanche, etc.) |
| `templateId` | String? | Template used for this event |

### EventStepModel
| Field | Type | Description |
|---|---|---|
| `title` | String | Step name |
| `description` | String? | Step details |
| `duration` | int? | Duration in minutes |
| `type` | EventStepType | `step` or `music` |
| `musicId` | String? | Linked music (for music steps) |
| `musicTone` | String? | Key/tone for the music step |

### EventPeople (CURRENT — hardcoded fields)
| Field | Type | Description |
|---|---|---|
| `elo` | List<String> | General ELO member IDs |
| `preacher` | List<String> | Preacher IDs |
| `lead` | List<String> | Service leader IDs |
| `soundImage` | List<String> | Tech team IDs |
| `diaconia` | List<String> | Deacon IDs |
| `eloWithInstruments` | Map<String, Map<String, bool>> | userId → {instrument: talkback} |

### EventTeams (CURRENT — hardcoded types)
| Field | Type | Description |
|---|---|---|
| `liturgia` | String? | Responsible society ID for liturgy |
| `lanche` | String? | Responsible society for post-cult snack |
| `aberturaEbd` | String? | Responsible for EBD opening |
| `reuniaoOracao` | String? | Responsible for prayer meeting |

### Event Operations
- `fetchUpcoming()` — Get upcoming events via ApiClient
- `fetchById(id)` — Direct Firestore lookup (services collection)
- `fetchForUser(userId)` — Events where user is assigned (via ApiClient)
- `fetchServicesForUser(userId)` — Filter all services by user in people field
- `fetchAllServices()` — Full collection query
- `fetchServicesByTemplates(templateIds)` — Filter by template
- `createEvent(name, date, start, templateId)` — Create with optional template-based steps
- `updateEvent(name, date, start, templateId)` — Update metadata
- `deleteEvent(id)` — Delete
- `updateEventDetails(id, steps, people, teams)` — Update full event
- `updateEventTemplate(eventId, templateId)` — Replace non-music steps with template's steps

### Default Steps (steps.json asset)
- Loaded from `steps.json` asset file
- Used when creating events without a template
- Default template also based on this

### Event Templates
Collection: `services_templates`
- `name`, `steps`, `userId`, `createdAt`
- `createDefaultTemplate()` — Creates from steps.json (step-type only, no music)
- `createTemplate(name, steps)` — Custom template
- `updateTemplate(id, name, steps)`
- `deleteTemplate(id)`
- Templates store only step-type steps, music steps are excluded

### Pages
- `agenda_section.dart` — Upcoming events list
- `event_editor_page.dart` — Full event creation/editing
- `event_viewer_page.dart` — Event detail view
- `event_history_page.dart` — Past events
- `event_template_page.dart` — List of templates
- `event_template_editor_page.dart` — Template CRUD
- `planning_section.dart` — Home tab for planning

### Event Form Components
- `widgets/event_form_sheet.dart` — Event metadata form
- `widgets/calendar_event_form_sheet.dart` — Calendar event form
- `widgets/batch_event_creator_sheet.dart` — Create multiple events at once
- `widgets/step_editor_sheet.dart` — Step editing

### Multi-tenant Changes Needed
- Events scoped to `churches/{churchId}/events/{eventId}`
- `EventPeople` becomes fully dynamic: `Map<roleId, List<userId>>`
- `EventTeams` becomes configurable: church admin defines team types
- Templates scoped to church, not global
- Batch event creation stays the same
- Steps remain generic (title/description/duration/type)
- Steps.json becomes optional — churches configure defaults via wizard
