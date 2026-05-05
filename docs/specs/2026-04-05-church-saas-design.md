# Church SaaS Platform — Design Specification

> **Date:** 2026-04-05
> **Status:** Draft — awaiting review
> **Author:** Jackson Felipe + Claude

## Executive Summary

Build a multi-tenant, commercial SaaS version of the current IPE Flutter church management app. The current app (hardcoded for IPB Estreito) continues to exist unchanged. This is a new project in a new directory that extracts all features into a generic, configurable platform any church can use.

## Table of Contents

1. [Architecture](#1-architecture)
2. [Data Models](#2-data-models)
3. [Firestore Structure](#3-firestore-structure)
4. [Onboarding Wizard](#4-onboarding-wizard)
5. [Authentication Flow](#5-authentication-flow)
6. [Roles & Permissions](#6-roles--permissions)
7. [Tier System](#7-tier-system)
8. [Dynamic Roles Configuration](#8-dynamic-roles-configuration)
9. [Firebase Functions](#9-firebase-functions)
10. [Security Rules](#10-security-rules)
11. [Billing System](#11-billing-system)
12. [Landing Page (Flutter Web)](#12-landing-page-flutter-web)
13. [Web Dashboard Layout](#13-web-dashboard-layout)
14. [Feature Inventory](#14-feature-inventory)
15. [Implementation Challenges](#15-implementation-challenges)
16. [Out of Scope](#16-out-of-scope)

---

## 1. Architecture

### Tech Stack
- **Frontend:** Flutter (single codebase for iOS, Android, Web)
- **Backend:** Firebase (Auth, Firestore, Cloud Functions, FCM, Storage)
- **Shared Firebase project** across all churches (multi-tenant via `churchId`)

### App Structure
- **Landing Page** — Flutter Web only. Public marketing site with pricing, feature info, and signup button. Only visible to unauthenticated users on web.
- **Church App** — Full feature set. Available on mobile and web. Same codebase, responsive layout adapts to screen size.

### Multi-tenancy
- Every data document is scoped under a `churchId`
- Users have a `churchId` field linking them to one church
- Security rules enforce church boundaries at the database level
- The existing IPE app is unchanged — this is a separate project

---

## 2. Data Models

### New Top-Level Models

#### `ChurchModel`
| Field | Type | Description |
|---|---|---|
| `id` | String | Firestore doc ID |
| `name` | String | Church display name |
| `logo` | String? | URL or emoji |
| `city` | String? | City |
| `state` | String? | State/region |
| `description` | String? | Short description |
| `accentColor` | int | Primary accent color (hex int) |
| `tier` | String | Current tier: free/basic/pro/max |
| `createdAt` | Timestamp | Creation timestamp |
| `setupCompleted` | bool | Whether wizard is complete |

#### `ChurchSettingsModel` | Stored under `churches/{churchId}/settings` | Custom roles, team types, board positions, default steps, schedule config, reminder rules

#### `ChurchSubscriptionModel` | Stored under `churches/{churchId}/subscription` | Tier, user limit, addon packages, billing status, billing cycle, stripeCustomerId (if applicable)

#### `ChurchFeatureConfigModel` | Stored under `churches/{churchId}/featureConfig` | Per-church toggles for available features (evaluations if Max, societies if Pro+)

### Modified Existing Models

#### `UserModel` (multi-tenant version)
| Field | Type | Description |
|---|---|---|
| `id` | String | Firebase Auth UID |
| `name` | String | Display name |
| `email` | String | Auth email |
| `churchId` | String? | Null until user joins or creates a church |
| `role` | String | `superAdmin` / `churchAdmin` / `member` |
| `status` | String | `pending` / `active` / `disabled` |
| `disabledNotifications` | List<String> | Disabled notification types |

#### `EventModel` (multi-tenant version)
- Lives under `churches/{churchId}/events/{eventId}`
- `EventPeople` changes from fixed fields to dynamic `Map<String, List<String>>` where keys are role IDs
- Structure: `Map<roleId, List<userId>>` — each church defines its own roles, roles map to user lists

#### `SocietyModel` (multi-tenant version)
- Lives under `churches/{churchId}/societies/{societyId}`
- Board positions defined per-church instead of hardcoded enum
- Forum categories per-church instead of hardcoded

#### `MusicModel`
- Lives under `churches/{churchId}/musics/{musicId}`
- No structural changes needed

#### `EvaluationModel`
- Lives under `churches/{churchId}/evaluations/...`
- Category names and evaluation criteria per-church

#### `EventTemplateModel`
- Lives under `churches/{churchId}/templates/{templateId}`
- No structural changes needed

### Models That Stay Unchanged
- `CalendarEventModel` — just scoped to church
- `EventStepModel` — generic (title, description, duration, type)
- `ChatMessage` — same structure
- `NotificationModel` — same structure
- `HolyricsConfig` — same, scoped to church
- `CalendarArtTemplate` — same

---

## 3. Firestore Structure

```
users/{userId}/                           # Top-level user profiles
  churchId, name, email, role, status, disabledNotifications, createdAt

churches/{churchId}/
  └── profile: { name, logo, city, state, description, accentColor, tier, setupCompleted, createdAt }
  └── settings: { roles, teamTypes, boardPositions, defaultSteps, reminderRules, evaluationConfig }
  └── subscription: { tier, userLimit, addons, billingStatus, billingCycle, stripeCustomerId }

  # Church-scoped collections
  ├── people/{personId}/                   # Church members
  ├── events/{eventId}/                    # Services & events
  │   ├── steps: [...]                     # Service steps
  │   ├── people: { roleId: [userId, ...], ... }
  │   ├── teams: { teamRole: societyId }
  │   └── messages/{messageId}/            # Event chat messages
  ├── templates/{templateId}/              # Service templates
  ├── events_calendar/{calendarEventId}/   # Calendar events
  ├── societies/{societyId}/               # Groups/committees
  │   ├── members: [userId, ...]
  │   ├── board: { position: [userId, ...] }
  │   ├── vocais: [userId, ...]
  │   ├── ministros: [userId, ...]
  │   └── messages/{messageId}/            # Society chat messages
  ├── musics/{musicId}/                    # Music library
  ├── music_categories/{categoryId}/       # Music categories
  ├── evaluations/
  │   ├── forms/{formId}/                  # Evaluation form definitions
  │   ├── categories/{catId}/              # Evaluation categories
  │   └── responses/{responseId}/          # Evaluation responses
  ├── holyrics/                            # Holyrics integration config
  ├── holyrics_config/{configId}/
  └── elo/                                 # ELO (Equipe de Louvor) — always exists
      ├── roles/{roleId}/                  # Roles within ELO
      └── availability/{userId}/           # Worship team availability data
```

---

## 4. Onboarding Wizard

### For New Church Administrators (5 screens)

1. **Church Identity** — Name, logo (upload image or pick emoji), city, state, description
2. **ELO Configuration** — Add roles to the default ELO group (e.g., "Canto", "Guitarra", "Vocal"). Roles can be freely named and described
3. **Service Templates** — Select from presets (Culto Dominical, EBD, Reunião de Oração, Ensaio de Louvor) or create custom. Each includes default steps
4. **Service Structure** — Define default step structure (e.g., Oração → Louvor → Pregação → Encerramento). Editable later
5. **Schedule & Reminders** — Configure when automated reminders trigger (e.g., "Remind Elo members X days before", "Send Friday liturgy check")

### Completion
- `churches/{churchId}.setupCompleted` → `true`
- User assigned `role: churchAdmin`
- Redirect to main dashboard

---

## 5. Authentication Flow

### First Login Path
1. User signs up via Google / Apple / Email
2. Redirected to a choice screen:
   - **"Register new church"** → Opens onboarding wizard
   - **"Go to a church"** → Input invite code or accept invite link

### "Register New Church" Path
- Completes wizard → `churchId` assigned → `role: churchAdmin`

### "Go to a Church" Path
- Receives invite link: `app.churchapp.com/invite/{encryptedChurchId}`
- Link opens app, auto-joins church as `role: member`
- If user has no account, sign up first then auto-join

### Platform Admin Account
- `jackson.f205@gmail.com` — hardcoded as `role: superAdmin`
- Full platform-wide access: all churches, billing, feature flags

---

## 6. Roles & Permissions

### Role Hierarchy

| Role | Permissions |
|---|---|
| `superAdmin` | All churches, billing management, platform settings, feature flags |
| `churchAdmin` | Manage own church: members, events, societies, settings, tier config |
| `member` | View events, calendar, music, participate in chat, manage own availability |

### Granular Permissions

- **Event creation:** churchAdmin, or churchAdmin can assign event creators
- **Society admin:** churchAdmin designates per-society admins (board members)
- **Evaluation management:** churchAdmin creates/manages forms, members participate
- **Music management:** churchAdmin or delegated music team leaders

---

## 7. Tier System

### Feature Gating

| Feature | Free | Basic | Pro | Max |
|---|---|---|---|---|
| Auth, settings | ✅ | ✅ | ✅ | ✅ |
| Members list | ✅ | ✅ | ✅ | ✅ |
| Events/Services + planning | ✅ | ✅ | ✅ | ✅ |
| Calendar | ✅ | ✅ | ✅ | ✅ |
| Chat (event-level) | ✅ | ✅ | ✅ | ✅ |
| Music library | ✅ | ✅ | ✅ | ✅ |
| ELO management | ✅ | ✅ | ✅ | ✅ |
| Ads | ✅ | ❌ | ❌ | ❌ |
| Societies/Groups + chat | ❌ | ❌ | ✅ | ✅ |
| Calendar art | ❌ | ❌ | ✅ | ✅ |
| Music evaluations | ❌ | ❌ | ❌ | ✅ |
| Holyrics integration | ❌ | ❌ | ❌ | ✅ |

### Tier Limits

| Tier | Max Users | Price | Add-on User Packages |
|---|---|---|---|
| Free | 30 | Free | N/A |
| Basic | 100 | Paid | 50 or 200 user add-ons |
| Pro | 300 | Paid | 200 or 500 user add-ons |
| Max | Unlimited | Paid | N/A |

---

## 8. Dynamic Roles Configuration

### ELO (Default — always exists)

ELO is the only hardcoded group. Every church has an ELO with configurable roles:

```json
{
  "defaultGroups": {
    "elo": {
      "name": "ELO (Equipe de Louvor)",
      "roles": []  // Church admin configures these
    }
  }
}
```

### Per-Church Custom Roles

Church settings store role definitions:

```json
{
  "settings": {
    "roles": {
      "role_abc123": {
        "name": "Canto",
        "description": "Vocalistas",
        "groupId": "elo"
      },
      "role_def456": {
        "name": "Guitarra",
        "description": "Guitarrista",
        "groupId": "elo"
      }
    },
    "teamTypes": {
      "team_liturgy": { "name": "Liturgia", "description": "..." },
      "team_lanche": { "name": "Lanche", "description": "..." }
    },
    "boardPositions": {
      "pos_presidente": { "name": "Presidente" },
      "pos_vice": { "name": "Vice" }
    }
  }
}
```

### Event People Assignment

Events reference role IDs instead of hardcoded fields:

```json
{
  "people": {
    "role_abc123": ["user_123", "user_456"],
    "role_def456": ["user_789"]
  }
}
```

---

## 9. Firebase Functions

### Modified Existing Functions

All functions gain `churchId` awareness through their parent document context:

| Function | Collection | Trigger | Purpose |
|---|---|---|---|
| `onMessageCreated` | `churches/{churchId}/events/{eventId}/messages/{messageId}` | onCreate | Chat mention notifications |
| `onSocietyMessageCreated` | `churches/{churchId}/societies/{societyId}/messages/{messageId}` | onCreate | Society chat notifications |
| `onServicePeopleUpdated` | `churches/{churchId}/events/{eventId}` | onUpdate | Scale assignment notifications |
| `onServiceStepsUpdated` | `churches/{churchId}/events/{eventId}` | onUpdate | Step change notifications |

### New Functions

| Function | Trigger | Purpose |
|---|---|---|
| `onChurchCreated` | onCreate `churches/{churchId}` | Initialize ELO group, default settings, send welcome |
| `onUserAddedToChurch` | onCreate `users/{userId}` with churchId | Set up user profile, assign church, notify admin |
| `onSubscriptionChanged` | onUpdate `churches/{churchId}/subscription` | Apply tier changes: disable/enable features |
| `dailyReminders` | Scheduled (every 6 hours) | Check all churches for due reminders (liturgy, prayer, availability) |
| `subscriptionChecker` | Scheduled (daily) | Check for downgrades/expired trials, apply limits |

### Per-Church Reminders

Instead of hardcoded Friday/Monday rules, each church stores `reminderRules` in settings. The scheduled function iterates all active churches and checks which have reminders due.

---

## 10. Security Rules

### Core Principle

Every read/write verifies:
1. User is authenticated
2. User belongs to the church being accessed
3. User has appropriate role for the action
4. Feature is enabled for the church's tier

### Rule Helpers

```javascript
match /databases/{database}/documents {
  function isLoggedIn() {
    return request.auth != null;
  }

  function getUserData() {
    return get(/databases/$(database)/documents/users/$(request.auth.uid)).data;
  }

  function getChurchData(churchId) {
    return get(/databases/$(database)/documents/churches/$(churchId)).data;
  }

  function isChurchMember() {
    return isLoggedIn() && getUserData().churchId == resource.data.churchId;
  }

  function isChurchAdmin() {
    return isLoggedIn() &&
      getUserData().churchId == resource.data.churchId &&
      (getUserData().role == 'churchAdmin' || getUserData().role == 'superAdmin');
  }

  function isSuperAdmin() {
    return isLoggedIn() && getUserData().role == 'superAdmin';
  }

  function churchTier(churchId) {
    return getChurchData(churchId).tier;
  }
}
```

### Cross-Church Prevention

Every sub-collection check resolves the user's `churchId` from their `users/{userId}` document and compares it to the parent church ID. If they don't match, the request is denied regardless of authentication status.

### Tier Enforcement

```javascript
match /churches/{churchId}/evaluations/{evalId} {
  allow read: if isChurchMember() && churchTier(churchId) >= 'max';
  allow write: if isChurchAdmin() && churchTier(churchId) >= 'max';
}

match /churches/{churchId}/societies/{societyId} {
  allow read: if isChurchMember() && churchTier(churchId) >= 'pro';
  allow write: if isChurchAdmin() && churchTier(churchId) >= 'pro';
}
```

### Performance Consideration

Document-based `get()` in rules is used over custom claims. Firestore caches these reads efficiently for rule evaluation. Custom claims would require token refresh on every church change, which is more complex.

---

## 11. Billing System

### Payment Flow
- Integration with Stripe via Firebase Functions (or Stripe Extensions for Firebase)
- Church admin manages subscription from in-app settings page
- Automated emails for: trial ending, billing failure, tier change confirmation

### Add-on User Packages
- Basic tier: add 50 users ($X/month) or 200 users ($Y/month)
- Pro tier: add 200 users ($X/month) or 500 users ($Y/month)
- Max tier: no add-ons needed (unlimited)
- Free tier: no add-ons available

### Tier Change Behavior
- **Upgrade:** immediate feature unlock
- **Downgrade:** features disabled at next billing cycle (grace period)
- **Below user limit:** excess members are not deleted, but cannot be invited until under limit

---

## 12. Landing Page (Flutter Web)

### Sections
1. **Hero** — Value proposition: "Gerencie sua igreja com facilidade"
2. **Features** — 6 feature cards: Members, Events, Music, Chat, Calendar, ELO
3. **Pricing** — 3 tier cards: Free/Basic/Pro/Max (comparison table)
4. **Testimonials** — (optional) Social proof
5. **CTA** — "Criar minha igreja" → opens signup
6. **Footer** — Contact, privacy policy, terms

### Public vs Authenticated
- Landing page visible to unauthenticated web users
- After login → navigates to the full church dashboard
- Same Flutter codebase, different route trees

---

## 13. Web Dashboard Layout

### Mobile Layout (existing)
- Bottom navigation: Agenda, Planning, Calendar, Musics
- Full-screen pages, swipe gestures

### Web Adaptations
- **Sidebar navigation** on left with church logo/name at top
- **Multi-panel layout** where applicable (e.g., chat panel + event detail side-by-side)
- **Responsive breakpoints:** mobile (< 768px), tablet (768-1024px), desktop (> 1024px)
- Same feature set, different layout composition
- Extract shared widgets into responsive containers

---

## 14. Feature Inventory

### Feature Details

Each feature has been analyzed and documented in a separate file under `docs/superpowers/features/`:

| File | Feature | Source Module | Notes |
|---|---|---|---|
| `/features/01-auth-settings.md` | Authentication & Settings | `auth/` | Email/Google/Apple, admin role, token refresh |
| `/features/02-members.md` | Member Management | `people/` | Member list, invite, profiles |
| `/features/03-events-services.md` | Events & Service Planning | `events/` | Events, templates, steps, teams, batch creation |
| `/features/04-calendar.md` | Calendar | `events/` + `events/events_calendar` | Combined calendar view, categories, date ranges |
| `/features/05-chat.md` | Event Chat | `events/` subcollection | @mentions, quoted messages, search |
| `/features/06-elo.md` | ELO (default team) | `events/` + `churches/elo` | Availability, role management, always exists |
| `/features/07-societies.md` | Societies/Groups | `societies/` | Groups, board positions, forum, custom roles, chat |
| `/features/08-music-library.md` | Music Library | `musics/` | CRUD, categories, YouTube, tone selection, Pexels |
| `/features/09-evaluations.md` | Music Evaluations | `music_evaluations/` | Forms, categories, ratings, permissions, responses |
| `/features/10-holyrics.md` | Holyrics Integration | `holyrics/` | Service projection config |
| `/features/11-calendar-art.md` | Calendar Art | `events/` | Template-based calendar image generation |
| `/features/12-notifications.md` | Push Notifications | `notifications/` | FCM, preferences, scheduled reminders |
| `/features/13-billing.md` | Billing & Tiers | New | Stripe integration, subscription management |
| `/features/14-onboarding.md` | Onboarding Wizard | New | 5-screen setup flow |
| `/features/15-web-dashboard.md` | Web Dashboard | New | Responsive layout, sidebar nav, landing page |

### Firestore Collections Reference

| Collection | Path | Purpose |
|---|---|---|
| `users` | Top-level | User profiles with church assignment |
| `churches` | Top-level | Church profiles, settings, subscriptions |
| `people` | `churches/{id}/people/` | Church members |
| `events` | `churches/{id}/events/` | Services and events |
| `events_calendar` | `churches/{id}/events_calendar/` | Calendar events |
| `templates` | `churches/{id}/templates/` | Service templates |
| `societies` | `churches/{id}/societies/` | Groups/committees |
| `musics` | `churches/{id}/musics/` | Music library |
| `music_categories` | `churches/{id}/music_categories/` | Music categories |
| `evaluations` | `churches/{id}/evaluations/` | Evaluation system |
| `holyrics_config` | `churches/{id}/holyrics_config/` | Holyrics config |

---

## 15. Implementation Challenges

### 1. Security Rules (Primary Concern)
- Cross-church isolation must be bulletproof
- Rule performance with document-based `get()` calls
- Tier enforcement at database level
- Custom role-based access checks

### 2. Flexible Roles System
- `EventPeople` changes from fixed fields to dynamic `Map<roleId, List<userId>>`
- Every piece of code reading/writing event people needs updating
- Role creation/deletion must handle existing event assignments

### 3. Flutter Web Responsive Layout
- Current UI is mobile-first only
- Web needs sidebar navigation, multi-panel layouts
- Extract responsive layout wrappers from existing pages
- Landing page is additional Flutter route tree

### 4. Tier Feature Gating
- UI-level: hide/disable buttons and pages
- Backend: Cloud Functions enforce tier limits
- Both must be consistent

### 5. Scheduled Reminders Per-Church
- Current hardcoded Friday/Monday logic
- New system reads `reminderRules` from each church's settings
- Must be efficient — don't loop through all churches for every check

---

## 16. Out of Scope

- Payment processing UI — uses Stripe checkout or hosted payment link
- Real-time analytics dashboard — future enhancement
- Multi-church membership (user belongs to multiple churches) — future enhancement
- Church-to-church messaging — future enhancement
- Advanced reporting — future enhancement
- API access for third-party integrations — future enhancement

---

## Appendix: Accent Color Palette

The app uses the existing theme, with one accent color configurable per church. Available accent options (16 pre-defined):

| # | Color | Hex |
|---|---|---|
| 1 | Red | `#C0392B` |
| 2 | Orange | `#E67E22` |
| 3 | Yellow/Gold | `#F39C12` |
| 4 | Green (original) | `#3E6C3E` |
| 5 | Blue | `#2980B9` |
| 6 | Navy | `#2C3E50` |
| 7 | Purple | `#8E44AD` |
| 8 | Teal | `#16A085` |
| 9 | Rose | `#C0392B` |
| 10 | Amber | `#FFA000` |
| 11 | Emerald | `#0D6C2E` |
| 12 | Slate | `#5D6D7E` |
| 13 | Burgundy | `#7B2D26` |
| 14 | Indigo | `#3949AB` |
| 15 | Coral | `#FF6F61` |
| 16 | Forest | `#2E7D32` |
