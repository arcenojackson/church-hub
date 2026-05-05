# Redesign "Você" + Padronização Planejar/Grupos + Remoção de Tiers — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesenhar a tela "Você" com ProfileCard + grid de acesso rápido, padronizar os estados de Planejar e Grupos, e remover o sistema de tiers de assinatura.

**Architecture:** Mudanças isoladas por arquivo — sem novos padrões arquiteturais. A SettingsSection é reescrita com widgets privados (`_ProfileCard`, `_QuickAccessGrid`, `_QuickAccessTile`, `_BadgePill`, `_DonationBanner`). EditProfilePage é uma nova tela independente. Os badges do grid usam FutureBuilders com queries Firestore diretas.

**Tech Stack:** Flutter 3.x, Dart, Firebase Firestore, Provider, `url_launcher` (já no pubspec), `intl` (já no pubspec).

---

## File Map

| Ação | Arquivo |
|---|---|
| Modificar | `lib/src/shared/state/app_state.dart` |
| Modificar | `lib/src/modules/home/presentation/home_shell.dart` |
| Modificar | `lib/src/modules/events/presentation/planning_section.dart` |
| Modificar | `lib/src/modules/societies/presentation/societies_page.dart` |
| Modificar | `lib/src/modules/auth/models/user_model.dart` |
| Modificar | `lib/src/modules/auth/data/auth_repository.dart` |
| Modificar | `lib/src/modules/auth/presentation/settings_page.dart` |
| Criar | `lib/src/modules/auth/presentation/edit_profile_page.dart` |
| Criar | `lib/src/modules/billing/presentation/donation_page.dart` |
| Criar | `test/models/user_model_test.dart` |

---

## Task 1: Remover sistema de tiers do AppState

**Arquivo:** `lib/src/shared/state/app_state.dart`

Remove campos e getters relacionados a subscription que são dead code.

- [ ] **Passo 1: Remover import de ChurchSubscriptionModel**

Em `app_state.dart`, remover a linha:
```dart
import '../../modules/church/models/church_subscription_model.dart';
```

- [ ] **Passo 2: Remover campo e getters de subscription**

Remover do corpo da classe `AppState`:
```dart
// Remover estas linhas:
ChurchSubscriptionModel? _churchSubscription;
ChurchSubscriptionModel? get churchSubscription => _churchSubscription;
bool get isProTier => true;
bool get isMaxTier => true;
void setChurchSubscription(ChurchSubscriptionModel sub) {
  _churchSubscription = sub;
  notifyListeners();
}
```

- [ ] **Passo 3: Limpar signOut()**

Em `signOut()`, remover a linha `_churchSubscription = null;`. O método fica:
```dart
Future<void> signOut() async {
  try {
    await _authRepository.signOut();
    _currentUser = null;
    _currentChurch = null;
    _churchSettings = null;
    notifyListeners();
  } catch (e) {
    _error = 'Erro ao fazer logout: ${e.toString()}';
    notifyListeners();
    rethrow;
  }
}
```

- [ ] **Passo 4: Verificar referências e analisar**

```bash
cd /Users/arcenojackson/www/church-apps/church-hub/church_hub
grep -r "isProTier\|isMaxTier\|churchSubscription\|setChurchSubscription\|ChurchSubscriptionModel" lib/
flutter analyze
```

Esperado: nenhuma referência restante, `flutter analyze` com 0 errors.

- [ ] **Passo 5: Commit**

```bash
git add lib/src/shared/state/app_state.dart
git commit -m "chore: remove tier subscription system from AppState"
```

---

## Task 2: Remover guards de tier do HomeShell

**Arquivo:** `lib/src/modules/home/presentation/home_shell.dart`

Remove as variáveis `isPro`/`isMax` e os guards `if (isPro)`/`if (isMax)` de `_buildDestinations`.

- [ ] **Passo 1: Reescrever `_buildDestinations`**

Substituir o método completo por:
```dart
List<_Destination> _buildDestinations(UserModel user, AppState appState) {
  final isAdmin = user.isAdmin;

  return [
    _Destination(
      section: HomeSection.agenda,
      icon: Icons.calendar_month_outlined,
      label: 'Agenda',
      builder: (_) => AgendaSection(user: user),
    ),
    if (isAdmin)
      _Destination(
        section: HomeSection.planning,
        icon: Icons.auto_awesome_motion_outlined,
        label: 'Planejar',
        builder: (_) => PlanningSection(user: user),
      ),
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
    _Destination(
      section: HomeSection.calendar,
      icon: Icons.calendar_month_rounded,
      label: 'Calendário',
      builder: (_) => const CalendarPage(),
    ),
    _Destination(
      section: HomeSection.musics,
      icon: Icons.music_note_rounded,
      label: 'Músicas',
      builder: (_) => MusicsSection(isAdmin: isAdmin),
    ),
    if (isAdmin)
      _Destination(
        section: HomeSection.people,
        icon: Icons.people_outline_rounded,
        label: 'Pessoas',
        builder: (_) => const PeopleSection(),
      ),
    _Destination(
      section: HomeSection.evaluations,
      icon: Icons.star_outline_rounded,
      label: 'Avaliações',
      builder: (_) => const EvaluationsListPage(),
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
git add lib/src/modules/home/presentation/home_shell.dart
git commit -m "feat: remove tier gates — all sections now visible to all users"
```

---

## Task 3: Padronizar PlanningSection

**Arquivo:** `lib/src/modules/events/presentation/planning_section.dart`

Adiciona loading state, melhora empty state, reposiciona botão de adicionar.

- [ ] **Passo 1: Reescrever o widget `PlanningSection`**

Substituir o conteúdo completo do arquivo por:
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../auth/models/user_model.dart';
import '../data/events_repository.dart';
import '../models/event_model.dart';
import 'event_editor_page.dart';
import 'event_viewer_page.dart';

class PlanningSection extends StatelessWidget {
  const PlanningSection({super.key, required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<EventsRepository>();

    return StreamBuilder<List<EventModel>>(
      stream: repo.watchUpcoming(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final events = snapshot.data ?? [];

        if (events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome_motion_outlined,
                    size: 56, color: Colors.white24),
                const SizedBox(height: 16),
                const Text('Nenhum evento cadastrado',
                    style: TextStyle(color: Colors.white54)),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const EventEditorPage()),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Novo evento'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.add_rounded),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const EventEditorPage()),
                  ),
                ),
              ],
            ),
            Expanded(
              child: ListView.separated(
                itemCount: events.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final e = events[i];
                  return _PlanningCard(
                    event: e,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => EventViewerPage(eventId: e.id)),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PlanningCard extends StatelessWidget {
  const _PlanningCard({required this.event, required this.onTap});
  final EventModel event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.event_rounded, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd/MM/yyyy', 'pt_BR').format(event.date) +
                          (event.start.isNotEmpty
                              ? ' · ${event.start}'
                              : ''),
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Text(
                '${event.steps.length} passos',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Colors.white24),
            ],
          ),
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
git add lib/src/modules/events/presentation/planning_section.dart
git commit -m "feat: standardize PlanningSection — loading/empty states, top-right add button"
```

---

## Task 4: Padronizar SocietiesPage

**Arquivo:** `lib/src/modules/societies/presentation/societies_page.dart`

Única mudança: substituir `FilledButton.icon` por `IconButton` no estado com itens.

- [ ] **Passo 1: Substituir botão no estado com itens**

Localizar o bloco:
```dart
if (isAdmin)
  Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      FilledButton.icon(
        onPressed: () => _showCreateSheet(context),
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Novo grupo'),
      ),
    ],
  ),
```

Substituir por:
```dart
if (isAdmin)
  Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      IconButton(
        icon: const Icon(Icons.add_rounded),
        onPressed: () => _showCreateSheet(context),
      ),
    ],
  ),
```

- [ ] **Passo 2: Verificar**

```bash
flutter analyze
```

Esperado: 0 errors.

- [ ] **Passo 3: Commit**

```bash
git add lib/src/modules/societies/presentation/societies_page.dart
git commit -m "feat: standardize SocietiesPage add button to IconButton (paridade com Planejar)"
```

---

## Task 5: Adicionar phone e birthday ao UserModel

**Arquivo:** `lib/src/modules/auth/models/user_model.dart`
**Teste:** `test/models/user_model_test.dart`

- [ ] **Passo 1: Escrever teste que falha**

Criar `test/models/user_model_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:church_hub/src/modules/auth/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('fromJson parses phone and birthday', () {
      final json = {
        'id': 'u1',
        'name': 'João Silva',
        'email': 'joao@test.com',
        'role': 'member',
        'status': 'active',
        'phone': '+55 48 99999-0000',
        'birthday': {'_seconds': 820454400, '_nanoseconds': 0},
      };

      final user = UserModel.fromJson(json);

      expect(user.phone, '+55 48 99999-0000');
      expect(user.birthday, isNotNull);
      expect(user.birthday!.year, 1996);
    });

    test('fromJson works without phone and birthday', () {
      final json = {
        'id': 'u1',
        'name': 'João Silva',
        'email': 'joao@test.com',
        'role': 'member',
        'status': 'active',
      };

      final user = UserModel.fromJson(json);

      expect(user.phone, isNull);
      expect(user.birthday, isNull);
    });

    test('toJson includes phone and birthday when set', () {
      final birthday = DateTime(1996, 1, 1);
      final user = UserModel(
        id: 'u1',
        name: 'João Silva',
        email: 'joao@test.com',
        role: UserRole.member,
        status: UserStatus.active,
        phone: '+55 48 99999-0000',
        birthday: birthday,
      );

      final json = user.toJson();

      expect(json['phone'], '+55 48 99999-0000');
      expect(json['birthday'], isNotNull);
    });

    test('toJson omits phone and birthday when null', () {
      final user = UserModel(
        id: 'u1',
        name: 'João Silva',
        email: 'joao@test.com',
        role: UserRole.member,
        status: UserStatus.active,
      );

      final json = user.toJson();

      expect(json.containsKey('phone'), isFalse);
      expect(json.containsKey('birthday'), isFalse);
    });

    test('copyWith preserves phone and birthday', () {
      final user = UserModel(
        id: 'u1',
        name: 'João',
        email: 'joao@test.com',
        role: UserRole.member,
        status: UserStatus.active,
        phone: '+55 48 99999-0000',
        birthday: DateTime(1996, 1, 1),
      );

      final updated = user.copyWith(name: 'João Silva');

      expect(updated.phone, '+55 48 99999-0000');
      expect(updated.birthday, DateTime(1996, 1, 1));
    });
  });
}
```

- [ ] **Passo 2: Rodar teste — deve falhar**

```bash
cd /Users/arcenojackson/www/church-apps/church-hub/church_hub
flutter test test/models/user_model_test.dart
```

Esperado: FAIL — campos `phone` e `birthday` não existem ainda.

- [ ] **Passo 3: Atualizar UserModel**

Substituir o conteúdo completo de `user_model.dart` por:
```dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { churchAdmin, member }

enum UserStatus { pending, active, disabled }

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.churchId,
    this.fcmToken,
    this.phone,
    this.birthday,
    this.disabledNotifications = const [],
    this.availability = const [],
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final UserStatus status;
  final String? churchId;
  final String? fcmToken;
  final String? phone;
  final DateTime? birthday;
  final List<String> disabledNotifications;
  final List<DateTime> availability;

  bool get isAdmin => role == UserRole.churchAdmin;
  bool get isChurchAdmin => role == UserRole.churchAdmin;
  bool get isMember => role == UserRole.member;
  bool get isPending => status == UserStatus.pending;
  bool get isActive => status == UserStatus.active;
  bool get hasChurch => churchId != null && churchId!.isNotEmpty;

  bool isNotificationEnabled(String notificationId) =>
      !disabledNotifications.contains(notificationId);

  bool hasAvailabilityForDate(DateTime date) {
    return availability.any(
      (d) => d.year == date.year && d.month == date.month && d.day == date.day,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedBirthday;
    final rawBirthday = json['birthday'];
    if (rawBirthday is Map && rawBirthday['_seconds'] != null) {
      parsedBirthday = DateTime.fromMillisecondsSinceEpoch(
        (rawBirthday['_seconds'] as int) * 1000,
      );
    } else if (rawBirthday is Timestamp) {
      parsedBirthday = rawBirthday.toDate();
    }

    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: _parseRole(json['role']?.toString()),
      status: _parseStatus(json['status']?.toString()),
      churchId: json['churchId']?.toString(),
      fcmToken: json['fcmToken']?.toString(),
      phone: json['phone']?.toString(),
      birthday: parsedBirthday,
      disabledNotifications:
          (json['disabledNotifications'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      availability: (json['availability'] as List<dynamic>?)
              ?.map((e) {
                if (e is Map && e['_seconds'] != null) {
                  return DateTime.fromMillisecondsSinceEpoch(
                    (e['_seconds'] as int) * 1000,
                  );
                }
                return DateTime.now();
              })
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role.name,
    'status': status.name,
    if (churchId != null) 'churchId': churchId,
    if (fcmToken != null) 'fcmToken': fcmToken,
    if (phone != null) 'phone': phone,
    if (birthday != null) 'birthday': Timestamp.fromDate(birthday!),
    if (disabledNotifications.isNotEmpty)
      'disabledNotifications': disabledNotifications,
  };

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    UserStatus? status,
    String? churchId,
    String? fcmToken,
    String? phone,
    DateTime? birthday,
    List<String>? disabledNotifications,
    List<DateTime>? availability,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      churchId: churchId ?? this.churchId,
      fcmToken: fcmToken ?? this.fcmToken,
      phone: phone ?? this.phone,
      birthday: birthday ?? this.birthday,
      disabledNotifications: disabledNotifications ?? this.disabledNotifications,
      availability: availability ?? this.availability,
    );
  }

  static UserRole _parseRole(String? value) {
    switch (value) {
      case 'churchAdmin':
        return UserRole.churchAdmin;
      default:
        return UserRole.member;
    }
  }

  static UserStatus _parseStatus(String? value) {
    switch (value) {
      case 'active':
        return UserStatus.active;
      case 'disabled':
        return UserStatus.disabled;
      default:
        return UserStatus.pending;
    }
  }
}
```

- [ ] **Passo 4: Rodar teste — deve passar**

```bash
flutter test test/models/user_model_test.dart
```

Esperado: PASS em todos os 5 testes.

- [ ] **Passo 5: Verificar análise estática**

```bash
flutter analyze
```

Esperado: 0 errors.

- [ ] **Passo 6: Commit**

```bash
git add lib/src/modules/auth/models/user_model.dart test/models/user_model_test.dart
git commit -m "feat: add phone and birthday fields to UserModel"
```

---

## Task 6: Adicionar updateUserProfile ao AuthRepository

**Arquivo:** `lib/src/modules/auth/data/auth_repository.dart`

Adiciona método que persiste nome, telefone e aniversário no Firestore.

- [ ] **Passo 1: Adicionar método `updateUserProfile`**

Logo após o método `updateUserName` existente (por volta da linha 201), adicionar:
```dart
Future<UserModel> updateUserProfile({
  required String name,
  String? phone,
  DateTime? birthday,
}) async {
  final firebaseUser = _auth.currentUser;
  if (firebaseUser == null) throw AppException(message: 'Nenhum usuário logado');

  await firebaseUser.updateDisplayName(name);

  final data = <String, dynamic>{'name': name};
  if (phone != null) data['phone'] = phone;
  if (birthday != null) {
    data['birthday'] = Timestamp.fromDate(birthday);
  }
  await _db.collection('users').doc(firebaseUser.uid).update(data);

  final updated = await _getUserFromFirestore(firebaseUser.uid);
  if (updated == null) throw AppException(message: 'Erro ao buscar usuário atualizado');
  await _sessionStorage.saveUser(updated);
  return updated;
}
```

Também adicionar o import do Firestore Timestamp no topo do arquivo (se não estiver já importado via `cloud_firestore`): o import `import 'package:cloud_firestore/cloud_firestore.dart';` já deve existir dado o uso de `FirebaseFirestore`.

- [ ] **Passo 2: Verificar**

```bash
flutter analyze
```

Esperado: 0 errors.

- [ ] **Passo 3: Commit**

```bash
git add lib/src/modules/auth/data/auth_repository.dart
git commit -m "feat: add updateUserProfile to AuthRepository (name, phone, birthday)"
```

---

## Task 7: Adicionar updateUserProfile ao AppState

**Arquivo:** `lib/src/shared/state/app_state.dart`

- [ ] **Passo 1: Adicionar método `updateUserProfile`**

Logo após o método `updateUserName` existente (linha ~113), adicionar:
```dart
Future<void> updateUserProfile({
  required String name,
  String? phone,
  DateTime? birthday,
}) async {
  await _exec(() async {
    _currentUser = await _authRepository.updateUserProfile(
      name: name,
      phone: phone,
      birthday: birthday,
    );
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
git add lib/src/shared/state/app_state.dart
git commit -m "feat: add updateUserProfile to AppState"
```

---

## Task 8: Criar EditProfilePage

**Arquivo:** `lib/src/modules/auth/presentation/edit_profile_page.dart` (novo)

- [ ] **Passo 1: Criar o arquivo**

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../shared/state/app_state.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  DateTime? _birthday;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppState>().currentUser!;
    _nameCtrl = TextEditingController(text: user.name);
    _phoneCtrl = TextEditingController(text: user.phone ?? '');
    _birthday = user.birthday;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<AppState>().updateUserProfile(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        birthday: _birthday,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar. Tente novamente.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickBirthday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) setState(() => _birthday = picked);
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0].toUpperCase()}${parts[1][0].toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar perfil'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Salvar'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
                    child: Text(
                      _initials(_nameCtrl.text),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Em breve: suporte a foto de perfil'),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_outlined,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nome *',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Nome obrigatório' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Telefone',
                prefixIcon: Icon(Icons.phone_outlined),
                hintText: '+55 48 99999-0000',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              readOnly: true,
              onTap: _pickBirthday,
              decoration: InputDecoration(
                labelText: 'Aniversário',
                prefixIcon: const Icon(Icons.cake_outlined),
                hintText: 'Selecione a data',
                suffixIcon: _birthday != null
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () => setState(() => _birthday = null),
                      )
                    : null,
              ),
              controller: TextEditingController(
                text: _birthday != null
                    ? DateFormat('dd/MM/yyyy', 'pt_BR').format(_birthday!)
                    : '',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Nota sobre `locale` no `showDatePicker`:** requer `GlobalMaterialLocalizations.delegate` no MaterialApp. Verificar se já está configurado em `app.dart`. Se não estiver, usar `initialDatePickerMode` sem locale (o picker ainda funciona, apenas em inglês).

- [ ] **Passo 2: Verificar**

```bash
flutter analyze
```

Esperado: 0 errors.

- [ ] **Passo 3: Commit**

```bash
git add lib/src/modules/auth/presentation/edit_profile_page.dart
git commit -m "feat: add EditProfilePage with name, phone, and birthday editing"
```

---

## Task 9: Criar DonationPage

**Arquivo:** `lib/src/modules/billing/presentation/donation_page.dart` (novo, substitui qualquer versão anterior)

- [ ] **Passo 1: Verificar se `donation_page.dart` já existe**

```bash
ls /Users/arcenojackson/www/church-apps/church-hub/church_hub/lib/src/modules/billing/presentation/
```

Se existir, sobrescrever. Se não existir, criar.

- [ ] **Passo 2: Criar/sobrescrever o arquivo**

```dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DonationPage extends StatelessWidget {
  const DonationPage({super.key});

  // Substituir pela URL real de doação quando definida (PIX, Stripe, etc.)
  static const String _donationUrl = 'https://churchhub.app/apoiar';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apoiar o Church Hub')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.favorite_rounded,
                size: 64, color: Colors.pinkAccent),
            const SizedBox(height: 24),
            Text(
              'Apoiar o Church Hub',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'O Church Hub é gratuito e mantido pela comunidade. '
              'Se o app tem ajudado a sua igreja, considere fazer uma doação '
              'para que possamos continuar melhorando.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, height: 1.5),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () async {
                final uri = Uri.parse(_donationUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Não foi possível abrir o link.'),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Fazer uma doação'),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Passo 3: Verificar**

```bash
flutter analyze
```

Esperado: 0 errors.

- [ ] **Passo 4: Commit**

```bash
git add lib/src/modules/billing/presentation/donation_page.dart
git commit -m "feat: add simplified DonationPage replacing BillingPage"
```

---

## Task 10: Reescrever SettingsSection

**Arquivo:** `lib/src/modules/auth/presentation/settings_page.dart`

Esta é a maior mudança. Substituir o conteúdo completo do arquivo.

- [ ] **Passo 1: Substituir o conteúdo completo de `settings_page.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../shared/state/app_state.dart';
import '../models/user_model.dart';
import 'edit_profile_page.dart';
import '../../church/presentation/church_settings_page.dart';
import '../../billing/presentation/donation_page.dart';
import '../../events/presentation/calendar_page.dart';
import '../../musics/presentation/musics_section.dart';
import '../../music_evaluations/presentation/evaluations_list_page.dart';
import '../../people/presentation/people_section.dart';

// Usado pelo desktop HomeShell como wrapper com AppBar
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: const SettingsSection(),
    );
  }
}

class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;
    final church = appState.currentChurch;
    final isAdmin = user?.isAdmin ?? false;

    return ListView(
      children: [
        if (user != null)
          _ProfileCard(user: user, church: church?.name),
        const SizedBox(height: 8),
        _QuickAccessGrid(isAdmin: isAdmin, churchId: church?.id),
        const SizedBox(height: 16),
        _DonationBanner(),
        const Divider(height: 32),
        ListTile(
          leading: const Icon(Icons.notifications_outlined),
          title: const Text('Notificações'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () {}, // TODO: Notification settings
        ),
        ListTile(
          leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
          title: const Text('Sair', style: TextStyle(color: Colors.redAccent)),
          onTap: () => _confirmSignOut(context, appState),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Future<void> _confirmSignOut(BuildContext context, AppState appState) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sair',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await appState.signOut();
      if (context.mounted) {
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    }
  }
}

// ---- Profile Card ----

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user, this.church});
  final UserModel user;
  final String? church;

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0].toUpperCase()}${parts[1][0].toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Card(
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const EditProfilePage()),
          ),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor:
                          colorScheme.primary.withValues(alpha: 0.2),
                      child: Text(
                        _initials(user.name),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(user.email,
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 13)),
                          const SizedBox(height: 6),
                          _RoleChip(role: user.role),
                        ],
                      ),
                    ),
                    const Icon(Icons.edit_outlined,
                        size: 18, color: Colors.white38),
                  ],
                ),
                if (church != null) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Colors.white12),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.church_rounded,
                          size: 16, color: Colors.white38),
                      const SizedBox(width: 6),
                      Text(
                        church!,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---- Quick Access Grid ----

class _QuickAccessGrid extends StatelessWidget {
  const _QuickAccessGrid({required this.isAdmin, this.churchId});
  final bool isAdmin;
  final String? churchId;

  @override
  Widget build(BuildContext context) {
    final tiles = _buildTiles(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: tiles,
      ),
    );
  }

  List<Widget> _buildTiles(BuildContext context) {
    final isAdmin = this.isAdmin;
    final churchId = this.churchId;

    return [
      _QuickAccessTile(
        icon: Icons.church_rounded,
        label: 'Igreja',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ChurchSettingsPage()),
        ),
      ),
      _QuickAccessTile(
        icon: Icons.calendar_month_rounded,
        label: 'Calendário',
        badgeFuture: churchId != null
            ? _eventsThisWeek(churchId)
            : Future.value(null),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => const _SectionShell(
                  title: 'Calendário', child: CalendarPage())),
        ),
      ),
      _QuickAccessTile(
        icon: Icons.music_note_rounded,
        label: 'Músicas',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => _SectionShell(
                  title: 'Músicas',
                  child: MusicsSection(isAdmin: isAdmin))),
        ),
      ),
      if (isAdmin)
        _QuickAccessTile(
          icon: Icons.people_outline_rounded,
          label: 'Pessoas',
          badgeFuture: churchId != null
              ? _pendingMembers(churchId)
              : Future.value(null),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => const _SectionShell(
                    title: 'Pessoas', child: PeopleSection())),
          ),
        ),
      _QuickAccessTile(
        icon: Icons.star_outline_rounded,
        label: 'Avaliações',
        badgeFuture: churchId != null
            ? _pendingEvaluations(churchId)
            : Future.value(null),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => const _SectionShell(
                  title: 'Avaliações', child: EvaluationsListPage())),
        ),
      ),
    ];
  }

  Future<String?> _eventsThisWeek(String churchId) async {
    final now = DateTime.now();
    final startOfWeek =
        DateTime(now.year, now.month, now.day - now.weekday + 1);
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    try {
      final snap = await FirebaseFirestore.instance
          .collection('churches')
          .doc(churchId)
          .collection('events')
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
          .where('date', isLessThan: Timestamp.fromDate(endOfWeek))
          .count()
          .get();

      final count = snap.count ?? 0;
      return count > 0 ? '$count esta semana' : null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _pendingMembers(String churchId) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('churchId', isEqualTo: churchId)
          .where('status', isEqualTo: 'pending')
          .count()
          .get();

      final count = snap.count ?? 0;
      return count > 0 ? '$count aguardando' : null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _pendingEvaluations(String churchId) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('churches')
          .doc(churchId)
          .collection('evaluations')
          .where('status', isEqualTo: 'pending')
          .count()
          .get();

      final count = snap.count ?? 0;
      return count > 0 ? '$count pendentes' : null;
    } catch (_) {
      return null;
    }
  }
}

class _QuickAccessTile extends StatelessWidget {
  const _QuickAccessTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badgeFuture,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Future<String?>? badgeFuture;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: Colors.white70),
              const SizedBox(height: 8),
              Text(label,
                  style: Theme.of(context).textTheme.labelMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 6),
              if (badgeFuture != null)
                FutureBuilder<String?>(
                  future: badgeFuture,
                  builder: (_, snap) {
                    final text = snap.data;
                    if (text == null) return const SizedBox(height: 18);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        text,
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                )
              else
                const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Donation Banner ----

class _DonationBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const DonationPage()),
          ),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.favorite_rounded,
                    color: Colors.pinkAccent, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Apoiar o Church Hub',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const Text('Ajude-nos a manter o app gratuito',
                          style: TextStyle(
                              color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: Colors.white24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---- Section Shell (navegação mobile para seções extras) ----

class _SectionShell extends StatelessWidget {
  const _SectionShell({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D1220), Color(0xFF05070D)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 4),
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Role Chip ----

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role});
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (role) {
      UserRole.churchAdmin => ('Admin', Theme.of(context).colorScheme.primary),
      UserRole.member => ('Membro', Colors.white38),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
```

- [ ] **Passo 2: Verificar análise estática**

```bash
flutter analyze
```

Esperado: 0 errors, 0 warnings.

- [ ] **Passo 3: Rodar testes**

```bash
flutter test test/models/user_model_test.dart
```

Esperado: PASS em todos os testes.

- [ ] **Passo 4: Commit final**

```bash
git add lib/src/modules/auth/presentation/settings_page.dart
git commit -m "feat: redesign SettingsSection — ProfileCard, QuickAccessGrid, DonationBanner"
```

---

## Task 11: Verificação final

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

- [ ] **Passo 3: Verificar referências órfãs**

```bash
grep -r "isProTier\|isMaxTier\|churchSubscription\|setChurchSubscription\|BillingPage" lib/
```

Esperado: 0 resultados (BillingPage pode aparecer no próprio arquivo billing_page.dart — ignorar).

- [ ] **Passo 4: Commit de fechamento**

```bash
git add -p  # revisar qualquer arquivo não commitado
git commit -m "chore: voce-redesign — implementation complete"
```

---

## Notas importantes para o agente

1. **Locale no DatePicker:** `showDatePicker` com `locale: const Locale('pt', 'BR')` requer `GlobalMaterialLocalizations.delegate` no `MaterialApp`. Verificar `lib/src/app.dart`. Se não estiver, remover o parâmetro `locale` do `showDatePicker` (o picker funciona em inglês sem problemas).

2. **Aggregate queries (`.count()`):** Requerem Firestore SDK `^5.0`. O projeto usa `cloud_firestore: ^5.4.3` — está ok. Em modo offline/emulador sem dados, o `.count()` retorna 0 graciosamente.

3. **`_pendingEvaluations` query:** O campo `status` na coleção `evaluations` pode não existir nos dados de produção atuais — o `catch (_) { return null; }` garante que o badge simplesmente não aparece sem quebrar nada.

4. **`DonationPage._donationUrl`:** É um placeholder. A URL real de doação deve ser substituída antes do deploy em produção.

5. **Ordem de implementação importa:** Respeitar a ordem das tasks. Em especial, Task 5 (UserModel) deve ser feita antes de Task 6 (AuthRepository) e Task 7 (AppState), e todos antes de Task 8 (EditProfilePage).
