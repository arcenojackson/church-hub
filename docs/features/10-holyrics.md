# Feature: Holyrics Integration

## Current Implementation
**Module:** `holyrics/`
**Repository:** `lib/src/modules/holyrics/data/holyrics_config.dart` + `holyrics_service.dart`
**Availability:** Max tier only

### Overview
Holyrics is a 3rd-party projection software used in church services for lyrics, announcements, and worship visuals.

### Configuration
- `holyrics_config.dart` — Stores connection info (IP, port, auth if any)
- `holyrics_service.dart` — HTTP communication with Holyrics instance

### Pages
- `holyrics_settings_screen.dart` — Connection config UI
- `widgets/holyrics_connection_status.dart` — Status indicator widget

### Operations
- Configure Holyrics server endpoint
- Test connection
- Send data to Holyrics (lyrics, announcements)
- Display connection status

### Dependencies
- `http` package for API calls
- Network connectivity required

### Multi-tenant Changes Needed
- Holyrics config scoped to `churches/{churchId}/holyrics_config/`
- Each church manages its own Holyrics connection
- Feature gated: only available on Max tier
- Security rules prevent non-Max churches from creating/updating holyrics config
- Connection status stays the same
