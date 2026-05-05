# Feature: Calendar Art

## Current Implementation
**Module:** `events/` (calendar art files)
**Tier:** Pro+ only

### Data Model (`CalendarArtTemplate`)
- Visual template configuration for calendar display
- Stored per-church or per-society
- Controls colors, fonts, layout of calendar image for sharing

### Pages
- `calendar_art_page.dart` — Full calendar art view
- `widgets/calendar_art_widget.dart` — Calendar art preview widget
- `widgets/calendar_art_template_sheet.dart` — Template selection

### Functionality
- Generates a visual calendar image with event dots/markers
- Selectable templates (styles, colors, fonts)
- Can be shared or downloaded (uses `share_plus` and `path_provider`)
- Shows event indicators (dots) on calendar days
- Society can have its own calendar art template (`society.calendarArtTemplate`)

### Dependencies
- `path_provider` ^2.1.4
- `share_plus` ^10.1.3
- `cached_network_image` ^3.4.1

### Multi-tenant Changes Needed
- Calendar art templates per-church
- Society-scoped templates also per-church
- Events data referenced is already church-scoped
- Only available on Pro+ tier (Security Rules + UI gate)
