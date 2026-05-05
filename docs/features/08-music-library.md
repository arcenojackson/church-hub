# Feature: Music Library

## Current Implementation
**Module:** `musics/`
**Repository:** `lib/src/modules/musics/data/musics_repository.dart`

### Data Model (`MusicModel`)
| Field | Type | Description |
|---|---|---|
| `id` | String | Firestore doc ID |
| `title` | String | Song title |
| `artist` | String | Artist name |
| `obs` | String? | Notes/observations |
| `youtube` | String? | YouTube video URL |
| `cipher` | String | Musical chord cipher/notation |
| `lyrics` | String? | Song lyrics |
| `bpm` | String? | Beats per minute |
| `tempo` | String? | Tempo marking |
| `tone` | String | Key (e.g., "C", "Dm") |
| `minorTone` | bool | Whether tone is minor |
| `category` | String | Category name |
| `selectedTimes` | List<String> | Times the music was used in services |

### Operations
- Create, read, update, delete music
- Search/filter by title, artist, category
- YouTube playback via `youtube_player_iframe`
- Tone selection via `tone_selector_sheet.dart`
- Link music to event steps (music-type steps in EventStepModel)

### Pages
- `musics_section.dart` — Music library list (home tab)
- `widgets/music_form_sheet.dart` — Music create/edit form
- `widgets/music_selector_sheet.dart` — Music picker for event steps
- `widgets/tone_selector_sheet.dart` — Key selector

### Pexels Image Picker
- `widgets/pexels_image_picker_modal.dart` — Free stock image search
- Used for calendar art, event images
- External API: Pexels (no auth required, just API key)

### Music in Events
- Event steps can be `EventStepType.music`
- Music steps link to `musicId` and specify `musicTone`
- When creating a service from template, music steps can be added from library
- Music steps are preserved when replacing templates (non-music steps replaced)

### Categories
- Stored in Firestore, configurable
- Used to filter and organize music library

### Multi-tenant Changes Needed
- Music scoped to `churches/{churchId}/musics/{musicId}`
- Categories scoped to church
- Tone selector unchanged
- Pexels integration unchanged (external service)
- Music linking to event steps unchanged
- `selectedTimes` stays the same (tracks usage within church)
