# Church Hub — Progresso de Implementação

> Atualizado: 2026-04-21 | Sessão 1 — CONCLUÍDA
> **Status do build:** ✅ flutter analyze: 0 errors, 0 warnings, 6 infos

---

## Status Geral

| Fase | Status | Arquivos |
|------|--------|----------|
| Projeto Flutter base | ✅ | pubspec.yaml, main.dart, app.dart, firebase_options.dart |
| Core layer | ✅ | FirebaseConfig, AppConfig, ApiClient, AppException |
| Modelos de dados | ✅ | UserModel, ChurchModel, Settings, Subscription, EventModel, MusicModel, SocietyModel, ChatMessage, CalendarEvent, EvaluationModels, HolyricsModel |
| Auth (Login, Signup, Google, Apple) | ✅ | login_page.dart, auth_repository.dart, settings_page.dart |
| Onboarding Wizard (5 telas) | ✅ | wizard/onboarding_wizard_page.dart + 5 steps |
| First-login flow (criar/entrar) | ✅ | church_selection_page.dart, join_church_page.dart |
| AppState (com ProxyProvider) | ✅ | app_state.dart — providers dinâmicos por churchId |
| Home Shell Responsivo | ✅ | home_shell.dart (mobile/tablet/desktop) |
| Agenda Section | ✅ | agenda_section.dart |
| Planning Section | ✅ | planning_section.dart |
| Event Viewer (3 tabs: Roteiro/Equipe/Chat) | ✅ | event_viewer_page.dart |
| Event Editor | ✅ | event_editor_page.dart (básico) |
| Event Chat | ✅ | event_chat_page.dart |
| Calendar | ✅ | calendar_page.dart |
| Music Library | ✅ | musics_section.dart, music_detail_page.dart, music_form_sheet.dart |
| People/Members | ✅ | people_section.dart (com código de convite) |
| Societies/Groups (Pro+) | ✅ | societies_page.dart, society_details_page.dart |
| ELO Availability | ✅ | elo_availability_page.dart |
| Music Evaluations (Max) | ✅ | evaluations_list_page.dart, evaluation_form_viewer_page.dart |
| Holyrics Integration (Max) | ✅ | holyrics_settings_page.dart |
| Church Settings | ✅ | church_settings_page.dart |
| Billing / Plans | ✅ | billing_page.dart |
| Landing Page Web | ✅ | web/landing_page.dart (todas as seções) |
| Firebase Functions (TypeScript) | ✅ | functions/src/index.ts (8 functions) |
| Firestore Security Rules | ✅ | firestore.rules (multi-tenant, tier enforcement) |

**Total: 64 arquivos .dart**

---

## Localização do Código

```
/Users/arcenojackson/www/church-apps/church-hub/
  church_hub/                  ← App Flutter
    lib/
      firebase_options.dart    ← PRECISA SER REGENERADO com flutterfire configure
      main.dart                ← Entry point com ProxyProviders dinâmicos
      src/
        app.dart               ← Routing (splash → login/landing → church-sel → home)
        core/
          config/              ← AppConfig, AppSecrets, FirebaseConfig
          network/             ← ApiClient
          utils/               ← AppException
        modules/
          auth/                ← LoginPage, AuthRepository, SettingsPage
          church/              ← ChurchModel, ChurchRepository, Wizard(5 steps), Selection
          events/              ← EventModel, EventsRepository, AgendaSection, PlanningSection
                                  CalendarPage, EventViewer, EventEditor, EventChat
                                  EloAvailabilityPage, AvailabilityRepository
          musics/              ← MusicModel, MusicsRepository, MusicsSection, MusicDetail
          people/              ← PeopleRepository, PeopleSection
          societies/           ← SocietyModel, SocietiesRepository, SocietiesPage
          music_evaluations/   ← EvaluationModels, MusicEvaluationsRepository, EvaluationsListPage
          holyrics/            ← HolyricsModel, HolyricsRepository, HolyricsSettingsPage
          billing/             ← BillingPage (UI + Stripe TODO)
          notifications/       ← NotificationService (FCM)
          home/                ← HomeShell (mobile/tablet/desktop responsive)
        shared/
          state/               ← AppState (church, user, settings, subscription)
          theme/               ← app_theme.dart (dynamic accent color)
          services/            ← SessionStorage
          widgets/             ← SplashPage, GlassContainer
        web/
          landing_page.dart    ← Marketing site (hero, features, pricing, CTA, footer)
    functions/src/index.ts     ← 8 Cloud Functions TypeScript
    firestore.rules            ← Security rules (multi-tenant + tier enforcement)
    firebase.json
    firestore.indexes.json
  PROGRESS.md                  ← Este arquivo
```

---

## Arquitetura Multi-Tenant

- **users/{userId}** → profile (churchId, role, availability)
- **churches/{churchId}** → profile, settings, subscription
- **churches/{churchId}/events/** → EventModel (people: Map<roleId, List<userId>>)
- **churches/{churchId}/musics/** → MusicModel
- **churches/{churchId}/societies/** → SocietyModel (Pro+)
- **churches/{churchId}/evaluations/** → EvaluationForms (Max)
- **churches/{churchId}/holyrics_config/** → HolyricsConfig (Max)

## Sistema de Tiers

| Tier | Limite | Features |
|------|--------|---------|
| free | 30 membros | Tudo básico + ads |
| basic | 100 | Sem ads + add-ons |
| pro | 300 | + Sociedades, Calendar Art |
| max | Ilimitado | + Avaliações, Holyrics |

## ProxyProvider Pattern

Os repositories com `churchId` são criados dinamicamente via `ProxyProvider<AppState, Repository>`. Quando o usuário faz onboarding e ganha um `churchId`, os repositories são re-instanciados automaticamente.

---

## O QUE PRECISA SER FEITO (Próxima Sessão)

### 🔴 BLOQUEADOR — Firebase Setup (Ação Manual do Jackson)
```bash
# 1. Criar projeto Firebase "church-hub" no console (console.firebase.google.com)
# 2. Rodar dentro de church_hub/:
cd /Users/arcenojackson/www/church-apps/church-hub/church_hub
flutterfire configure --project=<firebase-project-id>
# 3. Deploy rules:
firebase deploy --only firestore:rules
# 4. Deploy functions:
cd functions && npm install && firebase deploy --only functions
```

### 🟡 PENDENTE — Melhorias importantes
1. **Event Editor completo** — atualmente só edita nome/data/horário. Falta:
   - Gerenciar steps (adicionar/remover/reordenar)
   - Atribuir pessoas por role (EventPeople assignment)
   - Atribuir equipes por teamType (EventTeams assignment)
   - Batch event creator (criar vários de uma vez)

2. **People Section** — Clipboard import faltando em `people_section.dart`
   - Adicionar: `import 'package:flutter/services.dart';`
   - Descomentar a linha de clipboard: `Clipboard.setData(ClipboardData(text: code));`

3. **Calendar Art** (Pro tier) — Não implementado ainda
   - Template-based calendar image generation
   - Usar `CalendarArtTemplate` model do IPE

4. **Notification Settings** — SettingsPage tem TODO
   - Toggle por tipo de notificação
   - Atualizar `disabledNotifications` no Firestore

5. **Church Settings → ELO roles/team types management** — só edita nome/cor/cidade
   - Interface para adicionar/remover roles do ELO
   - Interface para teamTypes e boardPositions

6. **Event History** — Ver eventos passados (análogo ao `event_history_page.dart` do IPE)

7. **Weekly Team Assignments** — Overview semanal das escalas

8. **Society Chat** — Chat nas sociedades (o modelo existe, só falta a UI)

9. **Music Selector para steps** — Vincular música a um EventStepModel

### 🟢 OPCIONAIS (Nice to have)
- Super Admin Dashboard (platform-wide admin)
- Push notification deep linking (abrir tela correta ao tocar notificação)
- Pexels image picker (para músicas)
- YouTube player inline (para músicas)
- Calendar Art export/share

---

## Comandos

```bash
# Análise estática (deve ter 0 errors, 0 warnings)
cd /Users/arcenojackson/www/church-apps/church-hub/church_hub && flutter analyze

# Rodar
flutter run

# Build web
flutter build web

# Build iOS
flutter build ios --release

# Build Android
flutter build appbundle --release
```

---

## Para Continuar em Nova Sessão

1. Ler este arquivo PROGRESS.md
2. Verificar estado atual com `flutter analyze`
3. Resolver o Firebase setup (ação manual do Jackson)
4. Implementar Event Editor completo (maior gap funcional)
5. Corrigir o Clipboard import em people_section.dart
6. Implementar Society Chat
7. Implementar Calendar Art (Pro tier)
