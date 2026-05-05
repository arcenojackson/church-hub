# Sistema de Perfis e Permissões — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Substituir o controle de acesso binário (admin/member) por perfis configuráveis por igreja, com UI de gerenciamento, integração no fluxo de aprovação de membros e Firestore rules atualizadas.

**Architecture:** Novo módulo `profiles/` com `ProfileModel`, `ProfileRepository`, `ProfilesPage` e `ProfileEditorPage`. `AppState` ganha método `can(permission)` que verifica o perfil do usuário atual. `HomeShell` assina o stream de perfis e os injeta no AppState. `PeopleSection` ganha abas Ativos/Pendentes com bottom sheets de aprovação e ações.

**Tech Stack:** Flutter, Dart, Firebase Firestore, Provider (ProxyProvider pattern já estabelecido no projeto).

---

## Contexto crítico antes de começar

1. **Leia** `/Users/arcenojackson/www/church-apps/church-hub/church_hub/lib/main.dart` para entender o padrão ProxyProvider.
2. **Leia** o spec completo em `/Users/arcenojackson/www/church-apps/church-hub/superpowers/specs/2026-05-04-sistema-perfis-permissoes.md`.
3. **O Spec A pode já ter modificado** `home_shell.dart`, `app_state.dart` e `user_model.dart`. Leia o estado atual dos arquivos antes de editar.
4. **`onboarding_wizard_page.dart`** contém `appState.setChurchSubscription(...)` — esse método pode já ter sido removido pelo Spec A. Remova a chamada se ela não existir mais.

---

## File Map

| Ação | Arquivo |
|---|---|
| Criar | `lib/src/shared/permissions/app_permission.dart` |
| Criar | `lib/src/modules/profiles/models/profile_model.dart` |
| Criar | `lib/src/modules/profiles/data/profiles_repository.dart` |
| Criar | `lib/src/modules/profiles/presentation/profiles_page.dart` |
| Criar | `lib/src/modules/profiles/presentation/profile_editor_page.dart` |
| Criar | `test/models/profile_model_test.dart` |
| Modificar | `lib/src/modules/auth/models/user_model.dart` |
| Modificar | `lib/src/shared/state/app_state.dart` |
| Modificar | `lib/main.dart` |
| Modificar | `lib/src/modules/home/presentation/home_shell.dart` |
| Modificar | `lib/src/modules/people/data/people_repository.dart` |
| Modificar | `lib/src/modules/people/presentation/people_section.dart` |
| Modificar | `lib/src/modules/musics/presentation/musics_section.dart` |
| Modificar | `lib/src/modules/church/presentation/church_settings_page.dart` |
| Modificar | `lib/src/modules/church/presentation/wizard/onboarding_wizard_page.dart` |
| Modificar | `firestore.rules` |

---

## Task 1: Criar AppPermission (constantes de permissão)

**Arquivo:** `lib/src/shared/permissions/app_permission.dart` (novo)

- [ ] **Passo 1: Criar o diretório e arquivo**

```bash
mkdir -p /Users/arcenojackson/www/church-apps/church-hub/church_hub/lib/src/shared/permissions
```

```dart
// lib/src/shared/permissions/app_permission.dart

class AppPermission {
  AppPermission._();

  // Agenda e Eventos
  static const viewAgenda        = 'view_agenda';
  static const planEvents        = 'plan_events';
  static const viewServiceOrder  = 'view_service_order';

  // Calendário
  static const viewCalendar      = 'view_calendar';

  // Músicas
  static const viewMusics        = 'view_musics';
  static const editMusics        = 'edit_musics';

  // Membros
  static const viewPeople        = 'view_people';
  static const managePeople      = 'manage_people';

  // Chat de Evento
  static const viewEventChat     = 'view_event_chat';
  static const sendEventChat     = 'send_event_chat';

  // Grupos / Sociedades
  static const viewSocieties     = 'view_societies';
  static const manageSocieties   = 'manage_societies';

  // Avaliações Musicais
  static const viewEvaluations   = 'view_evaluations';
  static const submitEvaluations = 'submit_evaluations';
  static const manageEvaluations = 'manage_evaluations';

  // Holyrics
  static const configHolyrics    = 'config_holyrics';

  // Configurações da Igreja
  static const manageChurchSettings = 'manage_church_settings';

  /// Permissões padrão do perfil "Membro"
  static const Map<String, bool> memberDefaults = {
    viewAgenda:           true,
    planEvents:           false,
    viewServiceOrder:     true,
    viewCalendar:         true,
    viewMusics:           true,
    editMusics:           false,
    viewPeople:           false,
    managePeople:         false,
    viewEventChat:        true,
    sendEventChat:        true,
    viewSocieties:        true,
    manageSocieties:      false,
    viewEvaluations:      true,
    submitEvaluations:    true,
    manageEvaluations:    false,
    configHolyrics:       false,
    manageChurchSettings: false,
  };
}
```

- [ ] **Passo 2: Verificar**

```bash
cd /Users/arcenojackson/www/church-apps/church-hub/church_hub
flutter analyze
```

Esperado: 0 errors.

- [ ] **Passo 3: Commit**

```bash
git add lib/src/shared/permissions/app_permission.dart
git commit -m "feat: add AppPermission constants"
```

---

## Task 2: Criar ProfileModel

**Arquivo:** `lib/src/modules/profiles/models/profile_model.dart` (novo)
**Teste:** `test/models/profile_model_test.dart` (novo)

- [ ] **Passo 1: Escrever teste que falha**

```bash
mkdir -p /Users/arcenojackson/www/church-apps/church-hub/church_hub/lib/src/modules/profiles/models
mkdir -p /Users/arcenojackson/www/church-apps/church-hub/church_hub/lib/src/modules/profiles/data
mkdir -p /Users/arcenojackson/www/church-apps/church-hub/church_hub/lib/src/modules/profiles/presentation
```

Criar `test/models/profile_model_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:church_hub/src/modules/profiles/models/profile_model.dart';
import 'package:church_hub/src/shared/permissions/app_permission.dart';

void main() {
  group('ProfileModel', () {
    test('can() returns true for isAdminRole regardless of permissions', () {
      final adminProfile = ProfileModel(
        id: 'admin',
        name: 'Admin',
        permissions: {AppPermission.planEvents: false},
        isAdminRole: true,
      );
      expect(adminProfile.can(AppPermission.planEvents), isTrue);
    });

    test('can() returns true when permission is explicitly true', () {
      final profile = ProfileModel(
        id: 'lider',
        name: 'Líder de Louvor',
        permissions: {AppPermission.planEvents: true},
      );
      expect(profile.can(AppPermission.planEvents), isTrue);
    });

    test('can() returns false when permission is explicitly false', () {
      final profile = ProfileModel(
        id: 'member',
        name: 'Membro',
        permissions: {AppPermission.planEvents: false},
      );
      expect(profile.can(AppPermission.planEvents), isFalse);
    });

    test('can() returns false for unknown permission', () {
      final profile = ProfileModel(
        id: 'member',
        name: 'Membro',
        permissions: {},
      );
      expect(profile.can('unknown_permission'), isFalse);
    });

    test('fromJson parses correctly', () {
      final json = {
        'id': 'lider',
        'name': 'Líder de Louvor',
        'isAdminRole': false,
        'isDefault': false,
        'permissions': {
          'plan_events': true,
          'view_musics': true,
        },
      };
      final profile = ProfileModel.fromJson(json);
      expect(profile.name, 'Líder de Louvor');
      expect(profile.can(AppPermission.planEvents), isTrue);
      expect(profile.can(AppPermission.editMusics), isFalse);
    });

    test('toJson round-trips correctly', () {
      final profile = ProfileModel(
        id: 'lider',
        name: 'Líder',
        permissions: {AppPermission.planEvents: true},
        isAdminRole: false,
        isDefault: false,
      );
      final json = profile.toJson();
      final restored = ProfileModel.fromJson({'id': 'lider', ...json});
      expect(restored.name, profile.name);
      expect(restored.can(AppPermission.planEvents), isTrue);
    });
  });
}
```

- [ ] **Passo 2: Rodar teste — deve falhar**

```bash
flutter test test/models/profile_model_test.dart
```

Esperado: FAIL (arquivo não existe ainda).

- [ ] **Passo 3: Criar ProfileModel**

```dart
// lib/src/modules/profiles/models/profile_model.dart

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
  final Map<String, bool> permissions;
  final bool isAdminRole;
  final bool isDefault;

  bool can(String permission) {
    if (isAdminRole) return true;
    return permissions[permission] ?? false;
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final rawPerms = json['permissions'];
    final Map<String, bool> perms = {};
    if (rawPerms is Map) {
      rawPerms.forEach((k, v) {
        if (v is bool) perms[k.toString()] = v;
      });
    }
    return ProfileModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      permissions: perms,
      isAdminRole: json['isAdminRole'] as bool? ?? false,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'isAdminRole': isAdminRole,
    'isDefault': isDefault,
    'permissions': permissions,
  };

  ProfileModel copyWith({
    String? id,
    String? name,
    Map<String, bool>? permissions,
    bool? isAdminRole,
    bool? isDefault,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      permissions: permissions ?? this.permissions,
      isAdminRole: isAdminRole ?? this.isAdminRole,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
```

- [ ] **Passo 4: Rodar teste — deve passar**

```bash
flutter test test/models/profile_model_test.dart
```

Esperado: PASS em todos os 5 testes.

- [ ] **Passo 5: Verificar e commitar**

```bash
flutter analyze
git add lib/src/modules/profiles/models/profile_model.dart \
        lib/src/shared/permissions/app_permission.dart \
        test/models/profile_model_test.dart
git commit -m "feat: add ProfileModel with permission checking"
```

---

## Task 3: Criar ProfileRepository

**Arquivo:** `lib/src/modules/profiles/data/profiles_repository.dart` (novo)

- [ ] **Passo 1: Criar o arquivo**

```dart
// lib/src/modules/profiles/data/profiles_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/config/firebase_config.dart';
import '../../../../shared/permissions/app_permission.dart';
import '../models/profile_model.dart';

class ProfilesRepository {
  ProfilesRepository({required this.churchId});

  final String churchId;
  final FirebaseFirestore _db = FirebaseConfig.firestore;

  Stream<List<ProfileModel>> watchProfiles() {
    return _db
        .collection('churches')
        .doc(churchId)
        .collection('profiles')
        .snapshots()
        .asyncMap((snap) async {
      if (snap.docs.isEmpty && churchId.isNotEmpty) {
        // Primeira vez: seed automático
        await seedDefaultProfiles();
        return _defaultProfiles();
      }
      return snap.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return ProfileModel.fromJson(data);
      }).toList();
    });
  }

  Future<ProfileModel?> fetchProfile(String profileId) async {
    final doc = await _db
        .collection('churches')
        .doc(churchId)
        .collection('profiles')
        .doc(profileId)
        .get();
    if (!doc.exists) return null;
    final data = Map<String, dynamic>.from(doc.data()!);
    data['id'] = doc.id;
    return ProfileModel.fromJson(data);
  }

  Future<void> saveProfile(ProfileModel profile) async {
    final ref = profile.id.isEmpty
        ? _db.collection('churches').doc(churchId).collection('profiles').doc()
        : _db
            .collection('churches')
            .doc(churchId)
            .collection('profiles')
            .doc(profile.id);
    await ref.set(profile.toJson());
  }

  Future<void> deleteProfile(String profileId) async {
    await _db
        .collection('churches')
        .doc(churchId)
        .collection('profiles')
        .doc(profileId)
        .delete();
  }

  Future<void> seedDefaultProfiles() async {
    final batch = _db.batch();
    final base = _db
        .collection('churches')
        .doc(churchId)
        .collection('profiles');

    batch.set(base.doc('admin'), {
      'name': 'Admin',
      'isAdminRole': true,
      'isDefault': false,
      'permissions': <String, bool>{},
    });

    batch.set(base.doc('member'), {
      'name': 'Membro',
      'isAdminRole': false,
      'isDefault': true,
      'permissions': AppPermission.memberDefaults,
    });

    await batch.commit();
  }

  List<ProfileModel> _defaultProfiles() => [
    ProfileModel(
      id: 'admin',
      name: 'Admin',
      permissions: {},
      isAdminRole: true,
    ),
    ProfileModel(
      id: 'member',
      name: 'Membro',
      permissions: AppPermission.memberDefaults,
      isDefault: true,
    ),
  ];
}
```

- [ ] **Passo 2: Verificar**

```bash
flutter analyze
```

Esperado: 0 errors.

- [ ] **Passo 3: Commit**

```bash
git add lib/src/modules/profiles/data/profiles_repository.dart
git commit -m "feat: add ProfilesRepository with CRUD and auto-seed"
```

---

## Task 4: Adicionar profileId ao UserModel

**Arquivo:** `lib/src/modules/auth/models/user_model.dart`

**Atenção:** O Spec A pode já ter adicionado `phone` e `birthday` a este arquivo. Leia o estado atual antes de editar.

- [ ] **Passo 1: Ler o arquivo atual**

```bash
cat /Users/arcenojackson/www/church-apps/church-hub/church_hub/lib/src/modules/auth/models/user_model.dart
```

- [ ] **Passo 2: Adicionar profileId ao construtor**

Adicionar `this.profileId` como campo opcional após os campos existentes:
```dart
final String? profileId;
```

No construtor, adicionar:
```dart
this.profileId,
```

No `fromJson`, adicionar após os outros campos:
```dart
profileId: json['profileId']?.toString(),
```

No `toJson`, adicionar:
```dart
if (profileId != null) 'profileId': profileId,
```

No `copyWith`, adicionar parâmetro e uso:
```dart
// parâmetro:
String? profileId,
// uso:
profileId: profileId ?? this.profileId,
```

- [ ] **Passo 3: Verificar e rodar testes**

```bash
flutter analyze
flutter test test/models/user_model_test.dart
```

Esperado: 0 errors, testes passando.

- [ ] **Passo 4: Commit**

```bash
git add lib/src/modules/auth/models/user_model.dart
git commit -m "feat: add profileId field to UserModel"
```

---

## Task 5: Atualizar AppState com perfis e método can()

**Arquivo:** `lib/src/shared/state/app_state.dart`

**Atenção:** O Spec A pode já ter removido `isProTier`, `isMaxTier` e `_churchSubscription`. Leia o estado atual antes de editar.

- [ ] **Passo 1: Ler o arquivo atual**

```bash
cat /Users/arcenojackson/www/church-apps/church-hub/church_hub/lib/src/shared/state/app_state.dart
```

- [ ] **Passo 2: Adicionar imports necessários**

No topo do arquivo, adicionar:
```dart
import '../../modules/profiles/models/profile_model.dart';
import '../permissions/app_permission.dart';
```

- [ ] **Passo 3: Adicionar campos de estado**

Dentro da classe `AppState`, após as declarações de campo existentes, adicionar:
```dart
List<ProfileModel> _churchProfiles = [];
ProfileModel? _currentUserProfile;

List<ProfileModel> get churchProfiles => _churchProfiles;
ProfileModel? get currentUserProfile => _currentUserProfile;
```

- [ ] **Passo 4: Adicionar método can()**

Após os getters existentes:
```dart
/// Verifica se o usuário atual tem uma permissão.
/// Admins (pelo campo role legado) sempre têm acesso total.
/// Usuários sem profileId são tratados como perfil 'member'.
bool can(String permission) {
  if (_currentUser?.isAdmin ?? false) return true;
  if (_currentUserProfile != null) {
    return _currentUserProfile!.can(permission);
  }
  // Fallback: sem perfil carregado, usar defaults do Membro
  return AppPermission.memberDefaults[permission] ?? false;
}
```

- [ ] **Passo 5: Adicionar método setChurchProfiles()**

```dart
void setChurchProfiles(List<ProfileModel> profiles) {
  _churchProfiles = profiles;
  // Resolver o perfil do usuário atual
  final profileId = _currentUser?.profileId ?? 'member';
  _currentUserProfile = profiles.firstWhere(
    (p) => p.id == profileId,
    orElse: () => profiles.firstWhere(
      (p) => p.isDefault,
      orElse: () => ProfileModel(
        id: 'member',
        name: 'Membro',
        permissions: AppPermission.memberDefaults,
        isDefault: true,
      ),
    ),
  );
  notifyListeners();
}
```

- [ ] **Passo 6: Limpar churchProfiles no signOut()**

No método `signOut()`, adicionar após `_churchSettings = null;`:
```dart
_churchProfiles = [];
_currentUserProfile = null;
```

- [ ] **Passo 7: Verificar**

```bash
flutter analyze
```

Esperado: 0 errors.

- [ ] **Passo 8: Commit**

```bash
git add lib/src/shared/state/app_state.dart
git commit -m "feat: add can() and profile state to AppState"
```

---

## Task 6: Registrar ProfileRepository no main.dart

**Arquivo:** `lib/main.dart`

- [ ] **Passo 1: Adicionar import**

```dart
import 'src/modules/profiles/data/profiles_repository.dart';
```

- [ ] **Passo 2: Adicionar ProxyProvider após os existentes**

Dentro do `MultiProvider`, após o `ProxyProvider<AppState, SocietiesRepository>`:
```dart
ProxyProvider<AppState, ProfilesRepository>(
  update: (_, state, __) =>
      ProfilesRepository(churchId: state.currentUser?.churchId ?? ''),
),
```

- [ ] **Passo 3: Verificar**

```bash
flutter analyze
```

Esperado: 0 errors.

- [ ] **Passo 4: Commit**

```bash
git add lib/main.dart
git commit -m "feat: register ProfilesRepository as ProxyProvider"
```

---

## Task 7: Carregar perfis no HomeShell e usar can() em _buildDestinations

**Arquivo:** `lib/src/modules/home/presentation/home_shell.dart`

**Atenção:** O Spec A pode já ter modificado `_buildDestinations` (removendo isPro/isMax). Leia o estado atual antes de editar.

- [ ] **Passo 1: Ler o arquivo atual**

```bash
cat /Users/arcenojackson/www/church-apps/church-hub/church_hub/lib/src/modules/home/presentation/home_shell.dart
```

- [ ] **Passo 2: Adicionar imports**

```dart
import '../../../shared/permissions/app_permission.dart';
import '../../profiles/data/profiles_repository.dart';
```

- [ ] **Passo 3: Converter HomeShell para StatefulWidget e adicionar stream subscription**

`HomeShell` precisa se tornar `StatefulWidget` para gerenciar o subscription. Substituir a declaração da classe:

```dart
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialSection});
  final HomeSection? initialSection;

  @override
  State<HomeShell> createState() => _HomeShellState();
}
```

No `_HomeShellState`, adicionar campo e override de initState/dispose:
```dart
late StreamSubscription<List<ProfileModel>> _profilesSub;

@override
void initState() {
  super.initState();
  // Carrega e mantém perfis da igreja atualizados em AppState
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final repo = context.read<ProfilesRepository>();
    final appState = context.read<AppState>();
    _profilesSub = repo.watchProfiles().listen((profiles) {
      appState.setChurchProfiles(profiles);
    });
  });
}

@override
void dispose() {
  _profilesSub.cancel();
  super.dispose();
}
```

Adicionar o import necessário:
```dart
import 'dart:async';
import '../../profiles/models/profile_model.dart';
```

- [ ] **Passo 4: Atualizar _buildDestinations para usar appState.can()**

Substituir o método `_buildDestinations` para usar `appState.can()`:

```dart
List<_Destination> _buildDestinations(UserModel user, AppState appState) {
  return [
    _Destination(
      section: HomeSection.agenda,
      icon: Icons.calendar_month_outlined,
      label: 'Agenda',
      builder: (_) => AgendaSection(user: user),
    ),
    if (appState.can(AppPermission.planEvents))
      _Destination(
        section: HomeSection.planning,
        icon: Icons.auto_awesome_motion_outlined,
        label: 'Planejar',
        builder: (_) => PlanningSection(user: user),
      ),
    if (appState.can(AppPermission.viewSocieties))
      _Destination(
        section: HomeSection.societies,
        icon: Icons.groups_outlined,
        label: 'Grupos',
        builder: (_) => const SocietiesPage(),
      ),
    _Destination(
      section: HomeSection.settings,
      icon: Icons.person_outline_rounded,
      label: 'Você',
      builder: (_) => const SettingsSection(),
    ),
    if (appState.can(AppPermission.viewCalendar))
      _Destination(
        section: HomeSection.calendar,
        icon: Icons.calendar_month_rounded,
        label: 'Calendário',
        builder: (_) => const CalendarPage(),
      ),
    if (appState.can(AppPermission.viewMusics))
      _Destination(
        section: HomeSection.musics,
        icon: Icons.music_note_rounded,
        label: 'Músicas',
        builder: (_) => MusicsSection(
          canEdit: appState.can(AppPermission.editMusics),
        ),
      ),
    if (appState.can(AppPermission.viewPeople))
      _Destination(
        section: HomeSection.people,
        icon: Icons.people_outline_rounded,
        label: 'Pessoas',
        builder: (_) => const PeopleSection(),
      ),
    if (appState.can(AppPermission.viewEvaluations))
      _Destination(
        section: HomeSection.evaluations,
        icon: Icons.star_outline_rounded,
        label: 'Avaliações',
        builder: (_) => const EvaluationsListPage(),
      ),
  ];
}
```

- [ ] **Passo 5: Atualizar _primaryDestinations para usar can()**

```dart
List<_Destination> get _primaryDestinations {
  final primarySections = {
    HomeSection.agenda,
    HomeSection.planning,
    HomeSection.societies,
    HomeSection.settings,
  };
  return _destinations.where((d) => primarySections.contains(d.section)).toList();
}
```

(Sem mudança — já é assim. Societies só aparece se o can() acima o incluiu em _destinations.)

- [ ] **Passo 6: Verificar**

```bash
flutter analyze
```

Esperado: 0 errors.

- [ ] **Passo 7: Commit**

```bash
git add lib/src/modules/home/presentation/home_shell.dart
git commit -m "feat: HomeShell loads profiles and uses can() for section visibility"
```

---

## Task 8: Criar ProfilesPage (lista de perfis)

**Arquivo:** `lib/src/modules/profiles/presentation/profiles_page.dart` (novo)

- [ ] **Passo 1: Criar o arquivo**

```dart
// lib/src/modules/profiles/presentation/profiles_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/state/app_state.dart';
import '../data/profiles_repository.dart';
import '../models/profile_model.dart';
import 'profile_editor_page.dart';

class ProfilesPage extends StatelessWidget {
  const ProfilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ProfilesRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfis e Permissões'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ProfileEditorPage(),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<ProfileModel>>(
        stream: repo.watchProfiles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final profiles = snapshot.data ?? [];

          if (profiles.isEmpty) {
            return const Center(child: Text('Nenhum perfil encontrado'));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: profiles.length,
            itemBuilder: (_, i) {
              final p = profiles[i];
              return ListTile(
                leading: Icon(
                  p.isAdminRole
                      ? Icons.shield_rounded
                      : p.isDefault
                          ? Icons.star_rounded
                          : Icons.badge_outlined,
                  color: p.isAdminRole
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white54,
                ),
                title: Text(p.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (p.isAdminRole)
                      const _Badge('fixo')
                    else if (p.isDefault)
                      const _Badge('padrão'),
                    const Icon(Icons.chevron_right_rounded,
                        color: Colors.white24),
                  ],
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProfileEditorPage(profile: p),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, color: Colors.white54),
      ),
    );
  }
}
```

- [ ] **Passo 2: Verificar**

```bash
flutter analyze
```

Esperado: 0 errors.

- [ ] **Passo 3: Commit**

```bash
git add lib/src/modules/profiles/presentation/profiles_page.dart
git commit -m "feat: add ProfilesPage"
```

---

## Task 9: Criar ProfileEditorPage (criar/editar perfil)

**Arquivo:** `lib/src/modules/profiles/presentation/profile_editor_page.dart` (novo)

- [ ] **Passo 1: Criar o arquivo**

```dart
// lib/src/modules/profiles/presentation/profile_editor_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/firebase_config.dart';
import '../../../shared/permissions/app_permission.dart';
import '../data/profiles_repository.dart';
import '../models/profile_model.dart';

class ProfileEditorPage extends StatefulWidget {
  const ProfileEditorPage({super.key, this.profile});
  final ProfileModel? profile;

  @override
  State<ProfileEditorPage> createState() => _ProfileEditorPageState();
}

class _ProfileEditorPageState extends State<ProfileEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late Map<String, bool> _permissions;
  bool _saving = false;
  bool _deleting = false;

  bool get _isEditing => widget.profile != null;
  bool get _canDelete =>
      _isEditing &&
      !(widget.profile!.isAdminRole) &&
      !(widget.profile!.isDefault);

  static const _categories = [
    ('Agenda e Eventos', [
      (AppPermission.viewAgenda, 'Ver agenda'),
      (AppPermission.planEvents, 'Planejar eventos'),
      (AppPermission.viewServiceOrder, 'Ver roteiro do culto'),
    ]),
    ('Calendário', [
      (AppPermission.viewCalendar, 'Ver calendário'),
    ]),
    ('Músicas', [
      (AppPermission.viewMusics, 'Ver músicas'),
      (AppPermission.editMusics, 'Editar músicas'),
    ]),
    ('Membros', [
      (AppPermission.viewPeople, 'Ver membros'),
      (AppPermission.managePeople, 'Gerenciar membros'),
    ]),
    ('Chat', [
      (AppPermission.viewEventChat, 'Ver chat do evento'),
      (AppPermission.sendEventChat, 'Enviar mensagens no chat'),
    ]),
    ('Grupos', [
      (AppPermission.viewSocieties, 'Ver grupos'),
      (AppPermission.manageSocieties, 'Gerenciar grupos'),
    ]),
    ('Avaliações', [
      (AppPermission.viewEvaluations, 'Ver avaliações'),
      (AppPermission.submitEvaluations, 'Responder avaliações'),
      (AppPermission.manageEvaluations, 'Gerenciar avaliações'),
    ]),
    ('Holyrics', [
      (AppPermission.configHolyrics, 'Configurar Holyrics'),
    ]),
    ('Configurações', [
      (AppPermission.manageChurchSettings, 'Configurações da Igreja'),
    ]),
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile?.name ?? '');
    _permissions = Map<String, bool>.from(
      widget.profile?.permissions ?? AppPermission.memberDefaults,
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = context.read<ProfilesRepository>();
      final profile = ProfileModel(
        id: widget.profile?.id ?? '',
        name: _nameCtrl.text.trim(),
        permissions: _permissions,
        isAdminRole: widget.profile?.isAdminRole ?? false,
        isDefault: widget.profile?.isDefault ?? false,
      );
      await repo.saveProfile(profile);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil salvo!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final repo = context.read<ProfilesRepository>();
    final churchId = repo.churchId;

    // Contar usuários com este perfil
    final snap = await FirebaseConfig.firestore
        .collection('users')
        .where('churchId', isEqualTo: churchId)
        .where('profileId', isEqualTo: widget.profile!.id)
        .count()
        .get();
    final count = snap.count ?? 0;

    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir perfil?'),
        content: Text(count > 0
            ? '$count ${count == 1 ? 'membro tem' : 'membros têm'} este perfil. '
                'Eles serão migrados para o perfil Membro padrão.'
            : 'Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      // Migrar usuários afetados para perfil 'member'
      if (count > 0) {
        final users = await FirebaseConfig.firestore
            .collection('users')
            .where('churchId', isEqualTo: churchId)
            .where('profileId', isEqualTo: widget.profile!.id)
            .get();
        final batch = FirebaseConfig.firestore.batch();
        for (final doc in users.docs) {
          batch.update(doc.reference, {'profileId': 'member'});
        }
        await batch.commit();
      }

      await repo.deleteProfile(widget.profile!.id);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFixed = widget.profile?.isAdminRole == true ||
        widget.profile?.isDefault == true;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? widget.profile!.name : 'Novo Perfil'),
        actions: [
          if (_canDelete)
            IconButton(
              icon: _deleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline_rounded,
                      color: Colors.redAccent),
              onPressed: _deleting ? null : _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _nameCtrl,
              enabled: !isFixed,
              decoration: const InputDecoration(
                labelText: 'Nome do perfil *',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              maxLength: 40,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Nome obrigatório' : null,
            ),
            if (isFixed) ...[
              const SizedBox(height: 8),
              const Text(
                'Este é um perfil fixo do sistema e não pode ser editado.',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            ..._categories.map((cat) {
              final (categoryName, perms) = cat;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      categoryName.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  ...perms.map((perm) {
                    final (permKey, permLabel) = perm;
                    return SwitchListTile(
                      title: Text(permLabel),
                      value: _permissions[permKey] ?? false,
                      onChanged: isFixed
                          ? null
                          : (v) => setState(
                              () => _permissions[permKey] = v),
                      contentPadding: EdgeInsets.zero,
                    );
                  }),
                ],
              );
            }),
            const SizedBox(height: 24),
            if (!isFixed)
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Salvar perfil'),
              ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Passo 2: Verificar**

```bash
flutter analyze
```

Esperado: 0 errors.

- [ ] **Passo 3: Commit**

```bash
git add lib/src/modules/profiles/presentation/profile_editor_page.dart
git commit -m "feat: add ProfileEditorPage with permission toggles and delete flow"
```

---

## Task 10: Adicionar "Perfis e Permissões" à ChurchSettingsPage

**Arquivo:** `lib/src/modules/church/presentation/church_settings_page.dart`

- [ ] **Passo 1: Adicionar import**

```dart
import '../../../modules/profiles/presentation/profiles_page.dart';
```

- [ ] **Passo 2: Adicionar ListTile antes do botão Salvar**

Antes de `const SizedBox(height: 40)` e do `FilledButton`, adicionar:
```dart
const Divider(height: 40),
ListTile(
  contentPadding: EdgeInsets.zero,
  leading: const Icon(Icons.badge_outlined),
  title: const Text('Perfis e Permissões'),
  subtitle: const Text('Gerencie os perfis de acesso dos membros',
      style: TextStyle(fontSize: 12, color: Colors.white38)),
  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24),
  onTap: () => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const ProfilesPage()),
  ),
),
const SizedBox(height: 24),
```

- [ ] **Passo 3: Verificar**

```bash
flutter analyze
```

Esperado: 0 errors.

- [ ] **Passo 4: Commit**

```bash
git add lib/src/modules/church/presentation/church_settings_page.dart
git commit -m "feat: add Perfis e Permissões entry to ChurchSettingsPage"
```

---

## Task 11: Atualizar PeopleRepository

**Arquivo:** `lib/src/modules/people/data/people_repository.dart`

- [ ] **Passo 1: Adicionar métodos**

Após o método `removeMemberFromChurch`, adicionar:

```dart
Stream<List<UserModel>> watchPendingMembers() {
  return _db
      .collection('users')
      .where('churchId', isEqualTo: churchId)
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((q) => q.docs.map(_fromDoc).toList());
}

Future<void> approveUser(String userId, String profileId) async {
  await _db.collection('users').doc(userId).update({
    'status': 'active',
    'profileId': profileId,
  });
}

Future<void> updateMemberProfile(String userId, String profileId) async {
  await _db.collection('users').doc(userId).update({
    'profileId': profileId,
  });
}
```

- [ ] **Passo 2: Verificar**

```bash
flutter analyze
```

Esperado: 0 errors.

- [ ] **Passo 3: Commit**

```bash
git add lib/src/modules/people/data/people_repository.dart
git commit -m "feat: add watchPendingMembers, approveUser, updateMemberProfile to PeopleRepository"
```

---

## Task 12: Atualizar PeopleSection (abas + aprovação + ações)

**Arquivo:** `lib/src/modules/people/presentation/people_section.dart`

- [ ] **Passo 1: Substituir o conteúdo completo**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../auth/models/user_model.dart';
import '../data/people_repository.dart';
import '../../../shared/state/app_state.dart';
import '../../../modules/profiles/models/profile_model.dart';

class PeopleSection extends StatelessWidget {
  const PeopleSection({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final canManage = appState.can('manage_people');

    return DefaultTabController(
      length: canManage ? 2 : 1,
      child: Column(
        children: [
          if (canManage)
            const TabBar(
              tabs: [
                Tab(text: 'Ativos'),
                Tab(text: 'Pendentes'),
              ],
            ),
          Expanded(
            child: canManage
                ? const TabBarView(children: [
                    _ActiveMembersTab(),
                    _PendingMembersTab(),
                  ])
                : const _ActiveMembersTab(),
          ),
        ],
      ),
    );
  }
}

// ---- Aba Ativos ----

class _ActiveMembersTab extends StatelessWidget {
  const _ActiveMembersTab();

  @override
  Widget build(BuildContext context) {
    final repo = context.read<PeopleRepository>();
    final appState = context.read<AppState>();
    final church = appState.currentChurch;
    final canManage = appState.can('manage_people');

    return StreamBuilder<List<UserModel>>(
      stream: repo.watchMembers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final members = snapshot.data ?? [];

        if (members.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people_outline,
                    size: 56, color: Colors.white24),
                const SizedBox(height: 16),
                const Text('Nenhum membro ativo'),
                const SizedBox(height: 24),
                if (church != null) _InviteCard(churchId: church.id),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (church != null) ...[
              _InviteCard(churchId: church.id),
              const SizedBox(height: 16),
            ],
            Text(
              '${members.length} ${members.length == 1 ? 'membro' : 'membros'}',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: Colors.white38),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: members.length,
                itemBuilder: (_, i) {
                  final m = members[i];
                  final profileName = _resolveProfileName(
                      m.profileId, appState.churchProfiles);
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.2),
                      child: Text(
                        m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    title: Text(m.name),
                    subtitle: Text(m.email,
                        style: const TextStyle(color: Colors.white38)),
                    trailing: Text(
                      m.isAdmin ? 'Admin' : profileName,
                      style: TextStyle(
                        color: m.isAdmin
                            ? Theme.of(context).colorScheme.primary
                            : Colors.white38,
                        fontSize: 12,
                        fontWeight: m.isAdmin
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    onTap: canManage && !m.isAdmin
                        ? () => _showMemberActions(context, m, appState)
                        : null,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _resolveProfileName(
      String? profileId, List<ProfileModel> profiles) {
    if (profileId == null || profileId.isEmpty) return 'Membro';
    return profiles
        .firstWhere(
          (p) => p.id == profileId,
          orElse: () => ProfileModel(
              id: '', name: 'Membro', permissions: {}),
        )
        .name;
  }

  void _showMemberActions(
      BuildContext context, UserModel member, AppState appState) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _MemberActionsSheet(
        member: member,
        appState: appState,
      ),
    );
  }
}

class _MemberActionsSheet extends StatefulWidget {
  const _MemberActionsSheet(
      {required this.member, required this.appState});
  final UserModel member;
  final AppState appState;

  @override
  State<_MemberActionsSheet> createState() => _MemberActionsSheetState();
}

class _MemberActionsSheetState extends State<_MemberActionsSheet> {
  late String _selectedProfileId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedProfileId = widget.member.profileId ?? 'member';
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<PeopleRepository>();
    final profiles = widget.appState.churchProfiles
        .where((p) => !p.isAdminRole)
        .toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.member.name,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(widget.member.email,
              style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 24),
          const Text('Perfil',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: profiles.any((p) => p.id == _selectedProfileId)
                ? _selectedProfileId
                : (profiles.isNotEmpty ? profiles.first.id : 'member'),
            items: profiles
                .map((p) => DropdownMenuItem(
                      value: p.id,
                      child: Text(p.name),
                    ))
                .toList(),
            onChanged: (v) =>
                setState(() => _selectedProfileId = v ?? 'member'),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving
                ? null
                : () async {
                    setState(() => _saving = true);
                    try {
                      await repo.updateMemberProfile(
                          widget.member.id, _selectedProfileId);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Perfil atualizado!')),
                        );
                        Navigator.of(context).pop();
                      }
                    } finally {
                      if (mounted) setState(() => _saving = false);
                    }
                  },
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Alterar perfil'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent),
            onPressed: () async {
              await repo.disableMember(widget.member.id);
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Desativar membro'),
          ),
          const SizedBox(height: 8),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.white38),
            onPressed: () async {
              await repo.removeMemberFromChurch(widget.member.id);
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Remover da igreja'),
          ),
        ],
      ),
    );
  }
}

// ---- Aba Pendentes ----

class _PendingMembersTab extends StatelessWidget {
  const _PendingMembersTab();

  @override
  Widget build(BuildContext context) {
    final repo = context.read<PeopleRepository>();
    final appState = context.read<AppState>();

    return StreamBuilder<List<UserModel>>(
      stream: repo.watchPendingMembers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final pending = snapshot.data ?? [];

        if (pending.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    size: 56, color: Colors.white24),
                SizedBox(height: 16),
                Text('Nenhuma solicitação pendente',
                    style: TextStyle(color: Colors.white54)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: pending.length,
          itemBuilder: (_, i) {
            final m = pending[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange.withValues(alpha: 0.2),
                child: Text(
                  m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: Colors.orange, fontWeight: FontWeight.w700),
                ),
              ),
              title: Text(m.name),
              subtitle: Text(m.email,
                  style: const TextStyle(color: Colors.white38)),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: Colors.white24),
              onTap: () => _showApprovalSheet(context, m, appState),
            );
          },
        );
      },
    );
  }

  void _showApprovalSheet(
      BuildContext context, UserModel member, AppState appState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) =>
          _ApprovalSheet(member: member, appState: appState),
    );
  }
}

class _ApprovalSheet extends StatefulWidget {
  const _ApprovalSheet({required this.member, required this.appState});
  final UserModel member;
  final AppState appState;

  @override
  State<_ApprovalSheet> createState() => _ApprovalSheetState();
}

class _ApprovalSheetState extends State<_ApprovalSheet> {
  late String _selectedProfileId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Pré-selecionar perfil padrão
    final defaultProfile = widget.appState.churchProfiles.firstWhere(
      (p) => p.isDefault,
      orElse: () => ProfileModel(
          id: 'member', name: 'Membro', permissions: {}),
    );
    _selectedProfileId = defaultProfile.id;
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<PeopleRepository>();
    final profiles = widget.appState.churchProfiles
        .where((p) => !p.isAdminRole)
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Aprovar membro',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Text(widget.member.name,
              style: Theme.of(context).textTheme.titleMedium),
          Text(widget.member.email,
              style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 24),
          const Text('Atribuir perfil',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: profiles.any((p) => p.id == _selectedProfileId)
                ? _selectedProfileId
                : (profiles.isNotEmpty ? profiles.first.id : 'member'),
            items: profiles
                .map((p) => DropdownMenuItem(
                      value: p.id,
                      child: Text(p.name),
                    ))
                .toList(),
            onChanged: (v) =>
                setState(() => _selectedProfileId = v ?? 'member'),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving
                ? null
                : () async {
                    setState(() => _saving = true);
                    try {
                      await repo.approveUser(
                          widget.member.id, _selectedProfileId);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  '${widget.member.name} aprovado!')),
                        );
                        Navigator.of(context).pop();
                      }
                    } finally {
                      if (mounted) setState(() => _saving = false);
                    }
                  },
            icon: const Icon(Icons.check_rounded),
            label: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Aprovar'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent),
            onPressed: () async {
              await repo.removeMemberFromChurch(widget.member.id);
              if (context.mounted) Navigator.of(context).pop();
            },
            icon: const Icon(Icons.close_rounded),
            label: const Text('Recusar'),
          ),
        ],
      ),
    );
  }
}

// ---- Shared ----

class _InviteCard extends StatelessWidget {
  const _InviteCard({required this.churchId});
  final String churchId;

  @override
  Widget build(BuildContext context) {
    final code = churchId.substring(0, 8).toUpperCase();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.link_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Código de convite',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                Text(code,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Código copiado!')),
              );
            },
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Passo 2: Verificar**

```bash
flutter analyze
```

Esperado: 0 errors.

- [ ] **Passo 3: Commit**

```bash
git add lib/src/modules/people/presentation/people_section.dart
git commit -m "feat: PeopleSection with tabs, approval flow, and profile assignment"
```

---

## Task 13: Atualizar MusicsSection — isAdmin → canEdit

**Arquivo:** `lib/src/modules/musics/presentation/musics_section.dart`

- [ ] **Passo 1: Renomear parâmetro**

Substituir:
```dart
class MusicsSection extends StatefulWidget {
  const MusicsSection({super.key, required this.isAdmin});
  final bool isAdmin;
```

Por:
```dart
class MusicsSection extends StatefulWidget {
  const MusicsSection({super.key, required this.canEdit});
  final bool canEdit;
```

- [ ] **Passo 2: Atualizar referências internas**

Substituir todas as ocorrências de `widget.isAdmin` por `widget.canEdit` dentro do arquivo.

```bash
grep -n "isAdmin" /Users/arcenojackson/www/church-apps/church-hub/church_hub/lib/src/modules/musics/presentation/musics_section.dart
```

Para cada ocorrência dentro do arquivo, substituir `widget.isAdmin` por `widget.canEdit`.

- [ ] **Passo 3: Verificar referências externas**

O `HomeShell` já foi atualizado na Task 7 para usar `canEdit: appState.can(AppPermission.editMusics)`. Verificar se há outros lugares que usam `MusicsSection(isAdmin: ...)`:

```bash
grep -rn "MusicsSection" /Users/arcenojackson/www/church-apps/church-hub/church_hub/lib/
```

Para cada chamada encontrada com `isAdmin:`, substituir por `canEdit:`. O parâmetro `isAdmin` no `settings_page.dart` (SettingsSection) já foi tratado na Task A do plano anterior — verificar o estado atual do arquivo.

- [ ] **Passo 4: Verificar**

```bash
flutter analyze
```

Esperado: 0 errors.

- [ ] **Passo 5: Commit**

```bash
git add lib/src/modules/musics/presentation/musics_section.dart
git commit -m "feat: rename MusicsSection.isAdmin to canEdit for permission-based access"
```

---

## Task 14: Seed de perfis no wizard de onboarding

**Arquivo:** `lib/src/modules/church/presentation/wizard/onboarding_wizard_page.dart`

- [ ] **Passo 1: Ler o arquivo atual**

```bash
cat /Users/arcenojackson/www/church-apps/church-hub/church_hub/lib/src/modules/church/presentation/wizard/onboarding_wizard_page.dart
```

Se houver `appState.setChurchSubscription(...)`, remover essa linha (o Spec A pode já ter feito isso).

- [ ] **Passo 2: Adicionar import do ProfilesRepository**

```dart
import '../../../../modules/profiles/data/profiles_repository.dart';
```

- [ ] **Passo 3: Adicionar seed de perfis no método _finish()**

No método `_finish()`, após `appState.setChurch(completedChurch);` (ou o passo equivalente de setup completo), adicionar:

```dart
// Criar perfis padrão da nova igreja
final profileRepo = ProfilesRepository(churchId: church.id);
await profileRepo.seedDefaultProfiles();
```

- [ ] **Passo 4: Verificar**

```bash
flutter analyze
```

Esperado: 0 errors.

- [ ] **Passo 5: Commit**

```bash
git add lib/src/modules/church/presentation/wizard/onboarding_wizard_page.dart
git commit -m "feat: seed default profiles when creating new church"
```

---

## Task 15: Atualizar Firestore Security Rules

**Arquivo:** `firestore.rules`

- [ ] **Passo 1: Adicionar funções helper após as existentes**

Após a função `isChurchMember`, adicionar:

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

- [ ] **Passo 2: Adicionar regra para subcoleção profiles**

Dentro de `match /churches/{churchId} { ... }`, após a regra de `/settings/{doc}`, adicionar:

```js
match /profiles/{profileId} {
  allow read: if isChurchMember(churchId);
  allow write: if isChurchAdmin(churchId);
}
```

- [ ] **Passo 3: Atualizar regras de events**

Substituir:
```js
match /events/{eventId} {
  allow read: if isChurchMember(churchId);
  allow create: if isChurchAdmin(churchId);
  allow update: if isChurchAdmin(churchId);
  allow delete: if isChurchAdmin(churchId);

  match /messages/{messageId} {
    allow read: if isChurchMember(churchId);
    allow create: if isChurchMember(churchId) &&
      request.resource.data.userId == request.auth.uid;
    allow delete: if isChurchAdmin(churchId) ||
      (isChurchMember(churchId) && resource.data.userId == request.auth.uid);
  }
}
```

Por:
```js
match /events/{eventId} {
  allow read: if isChurchMember(churchId);
  allow create: if hasChurchPermission(churchId, 'plan_events');
  allow update: if hasChurchPermission(churchId, 'plan_events');
  allow delete: if isChurchAdmin(churchId);

  match /messages/{messageId} {
    allow read: if hasChurchPermission(churchId, 'view_event_chat');
    allow create: if hasChurchPermission(churchId, 'send_event_chat') &&
      request.resource.data.userId == request.auth.uid;
    allow delete: if isChurchAdmin(churchId) ||
      (isChurchMember(churchId) && resource.data.userId == request.auth.uid);
  }
}
```

- [ ] **Passo 4: Atualizar regra de musics**

Substituir:
```js
match /musics/{musicId} {
  allow read: if isChurchMember(churchId);
  allow write: if isChurchAdmin(churchId);
}
```

Por:
```js
match /musics/{musicId} {
  allow read: if hasChurchPermission(churchId, 'view_musics');
  allow write: if hasChurchPermission(churchId, 'edit_musics');
}
```

- [ ] **Passo 5: Atualizar regra de societies**

Substituir:
```js
match /societies/{societyId} {
  allow read: if isChurchMember(churchId);
  allow create: if isChurchAdmin(churchId);
```

Por:
```js
match /societies/{societyId} {
  allow read: if hasChurchPermission(churchId, 'view_societies');
  allow create: if hasChurchPermission(churchId, 'manage_societies');
  allow update: if hasChurchPermission(churchId, 'manage_societies');
  allow delete: if isChurchAdmin(churchId);
```

(Verificar se `update` e `delete` já existem no bloco atual e ajustar conforme necessário.)

- [ ] **Passo 6: Verificar e commitar**

```bash
flutter analyze
git add firestore.rules
git commit -m "feat: update firestore rules with profile-based permissions"
```

---

## Task 16: Verificação final

- [ ] **Passo 1: Análise estática completa**

```bash
cd /Users/arcenojackson/www/church-apps/church-hub/church_hub
flutter analyze
```

Esperado: 0 errors, 0 warnings.

- [ ] **Passo 2: Rodar todos os testes**

```bash
flutter test
```

Esperado: todos passam.

- [ ] **Passo 3: Verificar que não há referências a isProTier/isMaxTier**

```bash
grep -r "isProTier\|isMaxTier\|MusicsSection(isAdmin" lib/
```

Esperado: 0 resultados.

- [ ] **Passo 4: Commit de fechamento**

```bash
git commit --allow-empty -m "chore: sistema-perfis-permissoes — implementation complete"
```

---

## Notas importantes para o agente

1. **Ordem de implementação é crítica:** Tasks 1-5 (fundação) devem ser concluídas antes de Tasks 6-9 (UI), que devem ser concluídas antes de Tasks 10-13 (integração). A Task 14 (wizard) e Task 15 (rules) podem ser feitas em qualquer ordem após Task 3.

2. **Conflito com Spec A:** O Spec A modifica `user_model.dart`, `app_state.dart` e `home_shell.dart`. Leia SEMPRE o estado atual de cada arquivo antes de editar — não sobrescreva mudanças do Spec A.

3. **`_categories` com Records do Dart:** A sintaxe `(String, List<(String, String)>)` usa Records do Dart 3. O projeto usa Dart `^3.9.2` — compatível. Se o analisador reclamar, substitua por uma lista de Maps tipados.

4. **Aggregate `.count()` queries:** Usadas na Task 9 (ProfileEditorPage ao deletar). Requerem Firestore SDK `^5.0` — o projeto usa `^5.4.3`. Funciona.

5. **`isChurchAdmin` nas security rules:** A função já existe no `firestore.rules`. Não a remover ou modificar — apenas adicionar as novas funções `getUserProfile` e `hasChurchPermission`.

6. **Deploy das rules:** O agente não faz deploy das rules — apenas edita o arquivo local. Deploy (`firebase deploy --only firestore:rules`) é responsabilidade do usuário após revisão.
