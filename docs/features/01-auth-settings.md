# Feature: Authentication & Settings

## Current Implementation
**Module:** `auth/`
**Repository:** `lib/src/modules/auth/data/auth_repository.dart`

### Auth Methods
1. **Email/Password** — Firebase `signInWithEmailAndPassword` / `createUserWithEmailAndPassword`
2. **Google Sign-In** — `google_sign_in` package
3. **Apple Sign-In** — `sign_in_with_apple` package

### User Model (`UserModel`)
| Field | Type | Description |
|---|---|---|
| `id` | String | Firebase Auth UID |
| `name` | String | Display name |
| `email` | String | Auth email |
| `isAdmin` | bool | Admin vs member (boolean) |
| `isPending` | bool | Pending approval (new user) |
| `disabledNotifications` | List<String> | Opted-out notification types |

### Current Roles (Presbyterian-specific)
- `isAdmin && !isPending` → Administrator
- `!isAdmin && !isPending` → Standard member
- `!isAdmin && isPending` → New/pending user

### Token Refresh
- `_AppHome` in `app.dart` listens to app lifecycle
- On resume, refreshes Firebase ID token to avoid stale permission errors
- Critical for keeping users authenticated after long background periods

### Settings Page (`settings_page.dart`)
- User profile info
- Notification preferences toggle (which types to receive)
- Sign-out button
- App version display (`package_info_plus`)
- In-app upgrade prompts (`upgrader` package)

### Pages
- `login_page.dart` — Email/password login, Google/Apple buttons
- `settings_page.dart` — User settings

### Dependencies
- `firebase_auth` ^5.3.1
- `google_sign_in` ^6.2.1
- `sign_in_with_apple` ^6.1.3
- `cloud_firestore` ^5.4.3
- `flutter_local_notifications` ^18.0.1

### Multi-tenant Changes Needed
- `isAdmin` replaced with `role: String` (`superAdmin`, `churchAdmin`, `member`)
- Add `churchId` field (nullable — null until user joins/creates a church)
- New first-login flow: create church or join existing
- Super admin account hardcoded: `jackson.f205@gmail.com`
- Token refresh still needed but checks `churchId` validity on resume
