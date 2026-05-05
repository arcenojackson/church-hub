# Feature: Music Evaluations

## Current Implementation
**Module:** `music_evaluations/`
**Repository:** `lib/src/modules/music_evaluations/data/music_evaluations_repository.dart`
**Availability:** Max tier only

### Data Models

#### `EvaluationCategory` (CURRENT — hardcoded)
| Category | Label |
|---|---|
| `theological` | Teológica |
| `congregational` | Congregacional |
| `musical` | Musical |

#### `EvaluationForm`
- Form definition for evaluating music
- Contains evaluation items per category
- Stored in Firestore

#### `EvaluationMusic`
- Music entry in evaluation form
- Links to `MusicModel`
- Evaluation criteria per category

#### `EvaluationResponse`
- User's response to an evaluation form
- Ratings per category/item
- Stored per-user per-form

### Pages
- `evaluations_list_page.dart` — List of evaluation forms
- `evaluation_form_editor_page.dart` — Admin: create/edit evaluation forms
- `evaluation_form_viewer_page.dart` — View form (read-only)
- `evaluation_responses_viewer_page.dart` — View submitted responses (admin)
- `evaluation_permissions_sheet.dart` — Who can evaluate (admin config)
- `category_description_card.dart` — Category description display
- `rating_selector.dart` — Rating UI component
- `evaluation_response_form.dart` — Response submission form
- `music_item_form_sheet.dart` — Add/edit music item in evaluation

### Permissions
- `evaluation_permissions_sheet.dart` — Church admin configures who can evaluate
- Only enabled on Max tier

### Multi-tenant Changes Needed
- All scoped to `churches/{churchId}/evaluations/...`
- Categories configurable per-church (not hardcoded theological/congregational/musical)
- Permission system stays the same (admin configures evaluators)
- Response viewer stays the same
- Max tier gated: Security Rules and UI both enforce this
