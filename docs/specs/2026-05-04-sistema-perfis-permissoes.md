# Sistema de Perfis e Permissões — Design Spec

**Data:** 2026-05-04  
**Status:** Aprovado para implementação  
**Autor:** Documentação técnica gerada com base em análise do código e briefing do produto

---

## 1. Sumário Executivo

O Church Hub adota um sistema de **perfis configuráveis** para controlar o que cada usuário dentro de uma igreja pode acessar no app. O antigo controle binário (`UserRole.churchAdmin / member`) e o sistema de tiers (`free/basic/pro/max`) são substituídos por perfis nomeados e com permissões granulares, criados e gerenciados pelo admin da própria igreja.

---

## 2. Motivação / Problema Atual

### 2.1 UserRole binário é insuficiente

O `UserModel` atual possui:

```dart
enum UserRole { churchAdmin, member }
```

Isso cria apenas dois níveis: admin com acesso total, e membro sem capacidade de fazer nada além de visualizar. Igrejas reais têm estruturas mais complexas — líderes de louvor que planejam eventos mas não gerenciam membros, tesoureiros que acessam configurações mas não editam músicas, diáconos com acesso aos grupos, etc.

### 2.2 Tiers foram removidos — mas o código ainda referencia isPro/isMax

`AppState` expõe `isProTier = true` e `isMaxTier = true` (hardcoded) como workaround temporário após a remoção dos tiers. O `HomeShell` ainda usa `isPro` e `isMax` para condicionar a exibição de seções. Essa abordagem precisa ser substituída por verificações de permissão reais.

### 2.3 Aprovação de membros não oferece controle

Quando um novo usuário entra em uma igreja, ele recebe `role: UserRole.member` automaticamente. O admin não tem como atribuir um nível de acesso específico no momento da aprovação.

---

## 3. Escopo

### Incluso neste spec

- Modelo de dados `ProfileModel`
- Enumeração das permissões controláveis (`AppPermission`)
- Mudanças em `UserModel` (novo campo `profileId`, manutenção retrocompatível de `role`)
- Mudanças em `AppState` (carregamento do perfil do usuário atual, helper de verificação de permissão)
- Tela de gerenciamento de perfis (`ProfilesPage`) — acessível via Configurações da Igreja
- Integração da seleção de perfil no fluxo de aprovação de membros pendentes em `PeopleSection`
- Edição de perfil de membros existentes em `PeopleSection`
- Mudanças nas Firestore Security Rules
- Migração de usuários existentes
- Lista de arquivos a criar/modificar
- Ordem de implementação recomendada

### Fora do escopo

- Controle de permissões dentro do Firestore Security Rules por permissão individual (as rules continuam usando a distinção admin/membro; o controle fino de permissões é exclusivamente client-side, o que é adequado para o estágio atual)
- Notificações ao usuário quando seu perfil é alterado pelo admin (pode ser adicionado futuramente)
- Perfis globais compartilhados entre igrejas (cada igreja gerencia seus próprios perfis)
- Histórico de alterações de perfil

---

## 4. Design Detalhado

### 4.1 Enumeração de Permissões (`AppPermission`)

Cada permissão é uma `String` constante que mapeia diretamente ao campo `permissions` do documento Firestore. Usar `String` (em vez de enum) permite que futuras permissões sejam adicionadas sem migration de dados.

```
// lib/src/shared/permissions/app_permission.dart

class AppPermission {
  // Agenda e Eventos
  static const viewAgenda         = 'view_agenda';         // ver lista de eventos/cultos
  static const planEvents         = 'plan_events';         // criar e editar eventos (PlanningSection)
  static const viewServiceOrder   = 'view_service_order';  // ver roteiro do culto (EventViewerPage)

  // Calendário
  static const viewCalendar       = 'view_calendar';       // ver CalendarPage

  // Músicas
  static const viewMusics         = 'view_musics';         // ver biblioteca musical
  static const editMusics         = 'edit_musics';         // criar/editar/excluir músicas

  // Membros
  static const viewPeople         = 'view_people';         // ver lista de membros
  static const managePeople       = 'manage_people';       // aprovar, editar perfil, desativar membros

  // Chat de Evento
  static const viewEventChat      = 'view_event_chat';     // ver mensagens no chat do evento
  static const sendEventChat      = 'send_event_chat';     // enviar mensagens no chat do evento

  // Grupos / Sociedades
  static const viewSocieties      = 'view_societies';      // ver grupos e sociedades
  static const manageSocieties    = 'manage_societies';    // criar/editar/excluir grupos

  // Avaliações Musicais
  static const viewEvaluations    = 'view_evaluations';    // ver avaliações
  static const submitEvaluations  = 'submit_evaluations';  // responder avaliações
  static const manageEvaluations  = 'manage_evaluations';  // criar/configurar formulários

  // Holyrics
  static const configHolyrics     = 'config_holyrics';    // configurar integração Holyrics

  // Configurações da Igreja
  static const manageChurchSettings = 'manage_church_settings'; // editar dados e configs da igreja
}
```

**Decisão de design:** Permissões são separadas em "ver" e "gerenciar/editar" onde faz sentido. Isso evita que um líder de louvor consiga editar o banco de músicas por ter acesso à funcionalidade. A separação `view_` vs `edit_`/`manage_` é o padrão mais seguro.

---

### 4.2 Modelo de Dados: `ProfileModel`

**Arquivo:** `lib/src/modules/profiles/models/profile_model.dart`

```dart
class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.name,
    required this.permissions,
    this.isAdminRole = false,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final Map<String, bool> permissions;  // AppPermission.* -> true/false
  final bool isAdminRole;   // true apenas para o perfil Admin fixo
  final bool isDefault;     // true para o perfil Membro padrão

  bool can(String permission) {
    if (isAdminRole) return true;  // admin sempre tem acesso total
    return permissions[permission] ?? false;
  }
}
```

**Documento Firestore** em `churches/{churchId}/profiles/{profileId}`:

```json
{
  "name": "Líder de Louvor",
  "isAdminRole": false,
  "isDefault": false,
  "permissions": {
    "view_agenda": true,
    "plan_events": true,
    "view_service_order": true,
    "view_calendar": true,
    "view_musics": true,
    "edit_musics": false,
    "view_people": true,
    "manage_people": false,
    "view_event_chat": true,
    "send_event_chat": true,
    "view_societies": true,
    "manage_societies": false,
    "view_evaluations": true,
    "submit_evaluations": true,
    "manage_evaluations": false,
    "config_holyrics": false,
    "manage_church_settings": false
  }
}
```

**Perfis pré-criados no onboarding da igreja:**

| Perfil | `isAdminRole` | `isDefault` | Comportamento |
|--------|--------------|------------|---------------|
| Admin | true | false | Acesso total, não pode ser deletado, não pode ter permissões alteradas |
| Membro | false | true | Permissões básicas (ver agenda, calendário, chat, músicas, avaliações, grupos). Não pode ser deletado. |

Os dois perfis fixos são criados automaticamente ao criar uma nova igreja. O campo `isAdminRole = true` indica que `can()` sempre retorna `true` para esse perfil, independente das permissões salvas.

**Permissões padrão do perfil "Membro":**

| Permissão | Padrão |
|-----------|--------|
| view_agenda | ✅ |
| plan_events | ❌ |
| view_service_order | ✅ |
| view_calendar | ✅ |
| view_musics | ✅ |
| edit_musics | ❌ |
| view_people | ❌ |
| manage_people | ❌ |
| view_event_chat | ✅ |
| send_event_chat | ✅ |
| view_societies | ✅ |
| manage_societies | ❌ |
| view_evaluations | ✅ |
| submit_evaluations | ✅ |
| manage_evaluations | ❌ |
| config_holyrics | ❌ |
| manage_church_settings | ❌ |

---

### 4.3 Mudanças em `UserModel`

**Arquivo:** `lib/src/modules/auth/models/user_model.dart`

**Campos adicionados:**

```dart
final String? profileId;  // referência ao perfil da igreja
```

**Campo `role` mantido temporariamente** para retrocompatibilidade com usuários existentes e com as Firestore Security Rules, que ainda usam `role == 'churchAdmin'` para autorizar writes. O campo `role` passa a ser usado **apenas** para as security rules. No código do app, toda verificação de capacidade usa `profileId` + `ProfileModel.can()`.

**Getters atualizados:**

```dart
// Mantidos para retrocompatibilidade com security rules e lógica de migração
bool get isAdmin => role == UserRole.churchAdmin;
bool get isChurchAdmin => role == UserRole.churchAdmin;

// DEPRECATED — não usar em código novo. Use AppState.currentUserProfile.can(permission).
bool get isMember => role == UserRole.member;
```

**`fromJson` / `toJson`:** adicionar leitura/escrita de `profileId`.

---

### 4.4 Mudanças em `AppState`

**Arquivo:** `lib/src/shared/state/app_state.dart`

**Novo estado carregado:**

```dart
ProfileModel? _currentUserProfile;
List<ProfileModel> _churchProfiles = [];

ProfileModel? get currentUserProfile => _currentUserProfile;
List<ProfileModel> get churchProfiles => _churchProfiles;
```

**Helper de verificação de permissão:**

```dart
bool can(String permission) {
  // Admin de church (pelo role, campo legado) sempre tem acesso total
  if (_currentUser?.isAdmin ?? false) return true;
  return _currentUserProfile?.can(permission) ?? false;
}
```

**Nota:** o double-check `isAdmin` garante que admins existentes que ainda não tiverem `profileId` atribuído continuem com acesso total durante o período de migração.

**Carregamento dos perfis:**  
Os perfis da igreja são carregados após `setChurch()` ser chamado, via `ProfileRepository.watchProfiles(churchId)`. O perfil do usuário atual (`_currentUserProfile`) é resolvido a partir de `currentUser.profileId` dentro da lista carregada.

**Remoção das flags legadas de tier:**

```dart
// REMOVER — substituídos por can()
bool get isProTier => true;
bool get isMaxTier => true;
```

---

### 4.5 Tela de Gerenciamento de Perfis (`ProfilesPage`)

**Arquivo:** `lib/src/modules/profiles/presentation/profiles_page.dart`

**Acesso:** Via `ChurchSettingsPage` → novo item de menu "Perfis e Permissões".

**Layout da tela principal (lista de perfis):**

```
┌─────────────────────────────────┐
│  Perfis e Permissões            │
│                            [+]  │
├─────────────────────────────────┤
│  🔒 Admin          [fixo]       │
│  ★  Membro         [padrão]     │
│     Líder de Louvor      [>]    │
│     Diácono              [>]    │
└─────────────────────────────────┘
```

- Perfis com `isAdminRole = true` ou `isDefault = true` exibem badge e não têm botão de deletar
- Tap em qualquer perfil abre `ProfileEditorPage`
- Botão `[+]` abre `ProfileEditorPage` no modo criação

**`ProfileEditorPage`** — tela de criação/edição:

```
┌─────────────────────────────────┐
│  ← Líder de Louvor         [🗑] │
├─────────────────────────────────┤
│  Nome do perfil                 │
│  [________________________]     │
│                                 │
│  Permissões                     │
│  ─────────────────────────────  │
│  AGENDA E EVENTOS               │
│  Ver agenda              [  ●]  │
│  Planejar eventos        [●  ]  │
│  Ver roteiro do culto    [  ●]  │
│                                 │
│  CALENDÁRIO                     │
│  Ver calendário          [  ●]  │
│                                 │
│  MÚSICAS                        │
│  Ver músicas             [  ●]  │
│  Editar músicas          [●  ]  │
│                                 │
│  MEMBROS                        │
│  Ver membros             [  ●]  │
│  Gerenciar membros       [●  ]  │
│  ...                            │
│                                 │
│  [      Salvar perfil      ]    │
└─────────────────────────────────┘
```

- Campo de nome com validação (não pode estar vazio, máx 40 chars)
- Permissões agrupadas por categoria com `SwitchListTile`
- Botão de deletar (ícone lixeira no AppBar) visível apenas quando `!profile.isAdminRole && !profile.isDefault`
- Ao deletar, verificar se algum usuário tem esse `profileId`. Se sim, exibir confirmação: _"X membros têm este perfil. Eles serão migrados para o perfil Membro padrão."_ Deletar o perfil e atualizar os usuários afetados em batch write.
- Ao salvar: operação de `set` no Firestore (upsert), feedback com `SnackBar`

**Categorias de permissão exibidas na UI:**

| Categoria | Permissões |
|-----------|-----------|
| Agenda e Eventos | view_agenda, plan_events, view_service_order |
| Calendário | view_calendar |
| Músicas | view_musics, edit_musics |
| Membros | view_people, manage_people |
| Chat | view_event_chat, send_event_chat |
| Grupos | view_societies, manage_societies |
| Avaliações | view_evaluations, submit_evaluations, manage_evaluations |
| Holyrics | config_holyrics |
| Configurações | manage_church_settings |

---

### 4.6 Integração com Aprovação de Membros em `PeopleSection`

**Arquivo:** `lib/src/modules/people/presentation/people_section.dart`

#### 4.6.1 Aba de membros pendentes

`PeopleSection` passa a ter duas abas: **Ativos** (comportamento atual) e **Pendentes** (usuários com `status == pending` e `churchId == currentChurch.id`).

`PeopleRepository` ganha novo stream:

```dart
Stream<List<UserModel>> watchPendingMembers()
```

#### 4.6.2 Fluxo de aprovação

Ao tocar em um membro pendente, o admin vê um bottom sheet com:

1. Nome e email do usuário
2. Dropdown/selector "Perfil" com a lista de perfis da igreja (exceto Admin)
3. Botão "Aprovar"
4. Botão "Recusar" (remove churchId do usuário e mantém status pending)

Ao confirmar aprovação, `PeopleRepository.approveUser(userId, profileId)` executa:

```
users/{userId}:
  status = 'active'
  profileId = <selectedProfileId>
  // role mantido como 'member' para compatibilidade com security rules
```

O perfil padrão (Membro) vem pré-selecionado no dropdown.

#### 4.6.3 Edição de perfil de membros ativos

No `ListTile` de cada membro ativo, o trailing passa a mostrar o **nome do perfil** do membro (em vez da Chip "Admin"). Ao tocar no membro, admin vê opções:

- **Alterar perfil:** abre o mesmo selector de perfis, salva `profileId` no Firestore
- **Desativar membro:** comportamento atual (`disableMember`)
- **Remover da igreja:** comportamento atual (`removeMemberFromChurch`)

**Decisão de design:** manter a edição inline no bottom sheet (não uma tela separada) para manter a UX simples e consistente com a tela de aprovação.

---

### 4.7 Verificação de Permissões no App (`HomeShell` e outros)

**Arquivo:** `lib/src/modules/home/presentation/home_shell.dart`

`_buildDestinations` para de usar `isAdmin`, `isPro`, `isMax` e passa a usar `appState.can(permission)`:

```dart
// ANTES
if (isAdmin)
  _Destination(section: HomeSection.planning, ...)

// DEPOIS  
if (appState.can(AppPermission.planEvents))
  _Destination(section: HomeSection.planning, ...)
```

Mapeamento completo das seções para permissões:

| Seção / Feature | Permissão requerida |
|----------------|-------------------|
| AgendaSection | `view_agenda` |
| PlanningSection | `plan_events` |
| CalendarPage | `view_calendar` |
| MusicsSection (read-only) | `view_musics` |
| MusicsSection (editar) | `edit_musics` |
| PeopleSection (ver) | `view_people` |
| PeopleSection (aprovar/editar) | `manage_people` |
| SocietiesPage | `view_societies` |
| EvaluationsListPage | `view_evaluations` |
| ChurchSettingsPage | `manage_church_settings` |
| HolyricsPage | `config_holyrics` |

**Decisão de design:** `manage_church_settings` é verificado para acessar a `ChurchSettingsPage`. Dentro da settings page, a sub-seção "Perfis e Permissões" é acessível somente para usuários com `isAdmin == true` (campo role legado) — ou seja, somente o admin original da igreja pode modificar perfis. Isso garante que um perfil personalizado não consiga escalar privilégios ao editar perfis.

**Decisão de design:** `MusicsSection` recebe `canEdit: appState.can(AppPermission.editMusics)` como parâmetro, em vez de `isAdmin`. Isso permite que um "Líder de Louvor" edite músicas sem ser admin.

---

### 4.8 Repositório de Perfis

**Arquivo:** `lib/src/modules/profiles/data/profiles_repository.dart`

Métodos:

```dart
// Streams
Stream<List<ProfileModel>> watchProfiles(String churchId)

// Reads
Future<ProfileModel?> fetchProfile(String churchId, String profileId)

// Writes
Future<void> saveProfile(String churchId, ProfileModel profile)    // create ou update
Future<void> deleteProfile(String churchId, String profileId)

// Seed para novas igrejas
Future<void> seedDefaultProfiles(String churchId)
```

`seedDefaultProfiles` cria os dois perfis fixos (Admin e Membro) com IDs determinísticos: `'admin'` e `'member'`. IDs fixos simplificam referências e evitam a necessidade de buscar o perfil padrão por campo.

---

### 4.9 Migração de Usuários Existentes

**Estratégia:** migração lazy no client-side, sem script de backend.

**Regra de migração:**

| `role` atual | `profileId` atual | Ação |
|-------------|------------------|------|
| `churchAdmin` | null | Continuar funcionando via `isAdmin` check em `AppState.can()`. Admin existente não precisa de `profileId` — o getter `isAdmin` garante acesso total. |
| `member` | null | Na inicialização do app, se `profileId == null` e `status == active`, `AppState` trata como se tivesse o perfil `'member'` (ID fixo). Não requer escrita no Firestore. |
| qualquer | não-null | Usar o `profileId` normalmente. |

**Perfis padrão da igreja:** ao carregar perfis de uma igreja que ainda não tem a subcoleção `profiles`, `ProfileRepository.watchProfiles` chama `seedDefaultProfiles` automaticamente (one-time seed).

**Não há migration de dados em batch** — o sistema funciona corretamente com usuários que têm `profileId = null`, usando os IDs fixos como fallback.

---

## 5. Firestore Security Rules

### 5.1 Nova subcoleção `profiles`

```js
// dentro de match /churches/{churchId} { ... }

match /profiles/{profileId} {
  // Qualquer membro ativo pode ler os perfis da sua igreja
  allow read: if isChurchMember(churchId);
  // Apenas churchAdmin pode escrever perfis
  allow write: if isChurchAdmin(churchId);
}
```

### 5.2 Regra de aprovação de membros pendentes

A regra atual para `users/{userId}` já permite ao `churchAdmin` atualizar membros da sua igreja:

```js
allow update: if isLoggedIn() && (
  request.auth.uid == userId ||
  (getUserData().role == 'churchAdmin' &&
   resource.data.churchId == getUserData().churchId)
);
```

Esta regra **já cobre** a escrita de `profileId` pelo admin ao aprovar ou reatribuir um perfil. Nenhuma alteração adicional necessária para usuários.

### 5.3 Regra de eventos — `plan_events`

As rules atuais exigem `isChurchAdmin` para criar/editar eventos. Com o novo sistema, um usuário com perfil "Líder de Louvor" (`plan_events = true`) mas `role = member` não conseguiria criar eventos pelo Firestore.

**Decisão de design:** As security rules permanecem com `isChurchAdmin` para writes em eventos. Usuários que precisam planejar eventos mas não são admins de sistema devem ter `role = churchAdmin` no Firestore **ou** a regra deve ser relaxada.

**Solução adotada:** Adicionar uma função helper `hasPermissionForChurch` que verifica o perfil no Firestore:

```js
function getUserProfile(churchId) {
  let userData = getUserData();
  let profileId = userData.get('profileId', 'member');
  return get(/databases/$(database)/documents/churches/$(churchId)/profiles/$(profileId)).data;
}

function hasChurchPermission(churchId, permission) {
  return isLoggedIn() &&
    getUserData().churchId == churchId &&
    getUserData().status == 'active' && (
      getUserData().role == 'churchAdmin' ||
      getUserProfile(churchId).get('isAdminRole', false) == true ||
      getUserProfile(churchId).permissions.get(permission, false) == true
    );
}
```

**Nota importante:** `get()` extra em security rules conta como leitura faturável. Para o estágio atual do projeto, isso é aceitável. Se o volume escalar, pode-se otimizar com custom claims via Firebase Auth.

**Regras atualizadas para eventos:**

```js
match /events/{eventId} {
  allow read: if isChurchMember(churchId);
  allow create: if hasChurchPermission(churchId, 'plan_events');
  allow update: if hasChurchPermission(churchId, 'plan_events');
  allow delete: if isChurchAdmin(churchId);  // delete mantido apenas para admin

  match /messages/{messageId} {
    allow read: if hasChurchPermission(churchId, 'view_event_chat');
    allow create: if hasChurchPermission(churchId, 'send_event_chat') &&
      request.resource.data.userId == request.auth.uid;
    allow delete: if isChurchAdmin(churchId) ||
      (isChurchMember(churchId) && resource.data.userId == request.auth.uid);
  }
}
```

**Regras atualizadas para músicas:**

```js
match /musics/{musicId} {
  allow read: if hasChurchPermission(churchId, 'view_musics');
  allow write: if hasChurchPermission(churchId, 'edit_musics');
}
```

**Regras atualizadas para sociedades:**

```js
match /societies/{societyId} {
  allow read: if hasChurchPermission(churchId, 'view_societies');
  allow create: if hasChurchPermission(churchId, 'manage_societies');
  allow update: if hasChurchPermission(churchId, 'manage_societies');
  allow delete: if isChurchAdmin(churchId);
}
```

As demais coleções (`templates`, `events_calendar`, `elo`, `evaluations`, `holyrics_config`, `calendar_art_templates`) mantêm a regra atual de `isChurchAdmin` para writes — estas são features exclusivas do admin e não há perfil planejado que precise de escrita granular nelas por ora.

### 5.4 Regra final de `profiles` no arquivo completo

```js
match /churches/{churchId} {
  // ... regras existentes ...

  match /profiles/{profileId} {
    allow read: if isChurchMember(churchId);
    allow write: if isChurchAdmin(churchId);
  }
}
```

---

## 6. Arquivos a Criar / Modificar

### Novos arquivos

```
lib/src/modules/profiles/
  models/profile_model.dart
  data/profiles_repository.dart
  presentation/profiles_page.dart          // lista de perfis
  presentation/profile_editor_page.dart    // criar/editar perfil

lib/src/shared/permissions/
  app_permission.dart                      // constantes de permissão
```

### Arquivos modificados

```
lib/src/modules/auth/models/user_model.dart
  + campo profileId: String?
  + fromJson/toJson para profileId

lib/src/shared/state/app_state.dart
  + _currentUserProfile: ProfileModel?
  + _churchProfiles: List<ProfileModel>
  + getter currentUserProfile
  + getter churchProfiles
  + método can(String permission): bool
  + carregamento de perfis via ProfileRepository
  - remover isProTier e isMaxTier

lib/src/modules/people/data/people_repository.dart
  + watchPendingMembers(): Stream<List<UserModel>>
  + approveUser(String userId, String profileId): Future<void>
  + updateUserProfile(String userId, String profileId): Future<void>

lib/src/modules/people/presentation/people_section.dart
  + abas Ativos / Pendentes
  + bottom sheet de aprovação com seleção de perfil
  + trailing com nome do perfil no ListTile de membros ativos
  + bottom sheet de ações (alterar perfil, desativar, remover)

lib/src/modules/home/presentation/home_shell.dart
  + substituir isAdmin/isPro/isMax por appState.can(AppPermission.*)

lib/src/modules/musics/presentation/musics_section.dart
  + parâmetro canEdit: bool (em vez de isAdmin)

lib/src/modules/church/presentation/church_settings_page.dart
  + novo item de menu → ProfilesPage (visible only para isAdmin)

lib/src/modules/church/presentation/wizard/
  wizard_steps/step_final.dart (ou step existente de conclusão)
  + chamar ProfileRepository.seedDefaultProfiles após criar a igreja

firestore.rules
  + função hasChurchPermission()
  + função getUserProfile()
  + subcoleção profiles
  + regras atualizadas para events, musics, societies, event messages
```

---

## 7. Ordem de Implementação Recomendada

### Fase 1 — Fundação (sem breaking changes)

1. Criar `app_permission.dart` com todas as constantes
2. Criar `ProfileModel` com `fromJson/toJson` e método `can()`
3. Criar `ProfileRepository` com CRUD e `seedDefaultProfiles`
4. Adicionar `profileId` em `UserModel` (campo opcional, retrocompatível)
5. Atualizar `AppState`: carregar perfis, adicionar método `can()`, manter `isProTier/isMaxTier` por enquanto

### Fase 2 — Tela de gestão de perfis

6. Criar `ProfilesPage` e `ProfileEditorPage`
7. Adicionar entrada em `ChurchSettingsPage`
8. Testar CRUD completo de perfis

### Fase 3 — Integração com Pessoas

9. Adicionar `watchPendingMembers()` e `approveUser()` em `PeopleRepository`
10. Atualizar `PeopleSection`: abas Ativos/Pendentes, bottom sheets
11. Garantir que seed de perfis padrão acontece ao criar nova igreja

### Fase 4 — Verificação de permissões no HomeShell

12. Atualizar `HomeShell._buildDestinations` para usar `appState.can()`
13. Atualizar `MusicsSection` para receber `canEdit`
14. Remover `isProTier` e `isMaxTier` de `AppState`

### Fase 5 — Firestore Security Rules

15. Adicionar funções `hasChurchPermission` e `getUserProfile`
16. Atualizar regras de `events`, `messages`, `musics`, `societies`
17. Adicionar regra para subcoleção `profiles`
18. Testar rules no emulador antes de fazer deploy

---

## Apêndice A — Perfis de Exemplo para Documentação

| Perfil | Planejamento | Músicas (editar) | Membros (ver) | Grupos | Avaliações (responder) |
|--------|-------------|-----------------|--------------|--------|----------------------|
| Admin | ✅ | ✅ | ✅ | ✅ | ✅ |
| Membro | ❌ | ❌ | ❌ | ✅ | ✅ |
| Líder de Louvor | ✅ | ✅ | ✅ | ✅ | ✅ |
| Diácono | ❌ | ❌ | ✅ | ✅ | ✅ |
| Tesoureiro | ❌ | ❌ | ✅ | ❌ | ❌ |

---

## Apêndice B — Glossário

| Termo | Significado neste contexto |
|-------|--------------------------|
| Perfil | Um conjunto nomeado de permissões atribuível a usuários de uma igreja |
| Permissão | Uma capacidade específica dentro do app (ex: `plan_events`) |
| `isAdminRole` | Flag que indica que o perfil representa o administrador total da igreja; `can()` retorna sempre `true` |
| `isDefault` | Flag do perfil padrão atribuído automaticamente a novos membros aprovados sem escolha explícita |
| ID fixo | `'admin'` e `'member'` são IDs determinísticos usados como fallback na migração |
