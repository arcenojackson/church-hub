# Feature: Calendar

## Current Implementation
**Module:** `events/` (calendar-related files)
**Repository:** `EventsRepository` — calendar methods

### Data Model (`CalendarEventModel`)
| Field | Type | Description |
|---|---|---|
| `id` | String | Firestore doc ID |
| `name` | String | Event name |
| `date` | DateTime | Event date |
| `category` | String | Category filter (e.g., "Geral", "Feriados") |
| `start` | String | Start time "HH:mm" |
| `sourceCollection` | String? | 'events' or 'services' |

### Calendar Operations
- `fetchAllCalendarEvents()` — All events from `events` collection
- `fetchCalendarEventsByCategory(category)` — Filter by category
- `fetchCalendarEventsByCategories(categories)` — Multi-category + services merge
- `fetchCalendarEventsByDateRange(start, end, category)` — Date range filter
- `fetchCalendarEventsByDate(date, category)` — Single day
- `fetchAllEventsForCalendar()` — Combined: `events` + `services` (deduplicated)
- `fetchAllEventsForCalendarInRange(start, end)` — Combined with date range
- `createCalendarEvent(name, date, category, start)` — New calendar event
- `updateCalendarEvent(id, name, date, category, start)`
- `deleteCalendarEvent(id)`

### Dual Collection Strategy
- **`events`** collection: Calendar events (standalone, not services)
- **`services`** collection: Full service events with steps/teams
- Calendar view merges both, deduplicates by name+date+start match

### Pages
- `calendar_page.dart` — `table_calendar` based monthly view
- `widgets/calendar_art_widget.dart` — Calendar art preview
- `calendar_art_page.dart` — Full calendar art view

### Calendar Art
- `widgets/calendar_art_template_sheet.dart` — Select art template
- `calendar_art_template.dart` — Calendar visual template model
- Generates styled calendar image with event dots for sharing

### Multi-tenant Changes Needed
- Calendar events scoped to `churches/{churchId}/events_calendar/{eventId}`
- Sources: church-scoped `events_calendar` + church-scoped `events` (services)
- Categories configurable per-church (not hardcoded "Geral", "Feriados", etc.)
- Art stays the same — just references church-scoped events
- Deduplication logic unchanged
