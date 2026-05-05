# Feature: Church SaaS Landing Page & Web Dashboard

## Overview
This feature adds a Flutter Web-based marketing site and authenticated dashboard that works with the existing mobile app features.

**Current Implementation:** None — entirely new feature
**New Pages Required:**
- `landing_page.dart` — Public marketing site (web only)
- `web_dashboard_shell.dart` — Desktop-responsive shell for web
- `web_sidebar_nav.dart` — Left sidebar with church logo, navigation items
- `web_responsive_layout.dart` — Responsive wrapper that detects viewport size

## Landing Page (Unauthenticated Web Users)

### Sections
1. **Hero** — "Gerencie sua igreja com facilidade" — value prop + CTA
2. **Features Grid** — 6 feature cards with icons: Members, Events, Music, Chat, Calendar, ELO
3. **Pricing Table** — 4 tiers side-by-side: Free, Basic, Pro, Max with features listed
4. **Social Proof** — Testimonials, church logos (optional)
5. **CTA** — "Criar minha igreja" → triggers signup
6. **Footer** — Contact, privacy policy, terms of service

### Public Routes (Web)
When user is NOT authenticated and on web:
- `/` → Landing page
- `/signup` → Signup page (email/password, Google)
- `/login` → Login page
- `/pricing` → Pricing section (anchor)
- `/about` → About section

## Web Dashboard (Authenticated Web Users)

Shell: `web_dashboard_shell.dart` — replaces the mobile `home_shell.dart` on web viewport

### Layout
| Screen Size | Left Panel | Main Panel | Right Panel |
|---|---|---|---|
| Desktop (>1024px) | Sidebar (240px) | Content (flex) | Optional detail/chat |
| Tablet (768-1024px) | Collapsible sidebar | Content (flex) | — |
| Mobile (<768px) | Bottom nav (same as mobile) | Content (full) | — |

### Sidebar Content
- Church logo + name (top)
- Navigation items:
  - Agenda (events list)
  - Planning (service editor)
  - Calendar (month view)
  - Musics (music library)
  - People (members)
  - Societies (groups) — Pro+ tier
  - Evaluations (music evaluations) — Max tier
  - Settings (user + church settings)
- User avatar + name (bottom)
- Sign-out button

### Responsive Adaptation
- Mobile: BottomTabBar (existing)
- Tablet: NavigationRail (Material component)
- Desktop: PermanentDrawer or persistent sidebar

### Existing Pages to Wrap
These pages stay the same but need to be wrapped in responsive containers for web:
- `agenda_section.dart` → list layout, same card widgets
- `planning_section.dart` → full-width planning view
- `calendar_page.dart` → wider table_calendar display
- `musics_section.dart` → table view on desktop
- `societies_page.dart` → grid view on desktop
- `people_section.dart` → table view on desktop
- `event_viewer_page.dart` → detail panel on right
- `settings_page.dart` → form layout, wider

### Dependencies
- `flutter_web` (same Flutter SDK, web compilation target)
- No new dependencies required — Flutter's responsive widgets handle it

## Key Technical Considerations
- **Route handling:** Conditional route tree based on `kIsWeb` + auth state
- **Layout abstraction:** Extract a `ResponsiveLayout` widget that returns the right shell per screen size
- **State management:** Same `AppState` provider works for web
- **Firebase:** Same config works on web
- **Assets:** Ensure all assets are web-compatible (SVG or PNG, not platform-specific formats)
