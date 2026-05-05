# Society Members & Leaders Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Adicionar UI completa de gestão de membros e líderes dentro de cada grupo (SocietyDetailsPage), incluindo adição via sheet de busca e remoção via swipe/lixeira.

**Architecture:** O campo `leadersIds` é adicionado ao modelo e persistido no Firestore via `arrayUnion`/`arrayRemove`. A `SocietyDetailsPage` passa a ser `StatefulWidget`, carrega todos os membros ativos da igreja e resolve nomes localmente. Um widget `_SwipeToRemoveTile` encapsula o padrão de remoção com swipe.

**Tech Stack:** Flutter, Cloud Firestore, Provider

---

## Files

| Ação | Arquivo |
|------|---------|
| Modify | `lib/src/modules/societies/models/society_model.dart` |
| Modify | `lib/src/modules/societies/data/societies_repository.dart` |
| Rewrite | `lib/src/modules/societies/presentation/society_details_page.dart` |

---

### Task 1: Adicionar `leadersIds` ao modelo

**Files:**
- Modify: `lib/src/modules/societies/models/society_model.dart`

- [ ] **Step 1: Adicionar o campo ao construtor e propriedades**

Em `SocietyModel`, adicionar `this.leadersIds = const []` no construtor e `final List<String> leadersIds;` como propriedade, ao lado de `membersIds`:

```dart
const SocietyModel({
  required this.id,
  required this.churchId,
  required this.name,
  required this.description,
  required this.color,
  required this.userId,
  this.membersIds = const [],
  this.leadersIds = const [],      // <-- novo
  this.boardWithPositions = const {},
  this.forumUsersByCategory = const {},
  this.vocaisIds = const [],
  this.ministrosIds = const [],
});

final List<String> leadersIds;    // <-- novo
```

- [ ] **Step 2: Atualizar `fromFirestore`**

Dentro de `SocietyModel.fromFirestore`, após o parse de `membersIds`, adicionar:

```dart
leadersIds: (data['leadersIds'] as List<dynamic>?)
    ?.map((e) => e.toString())
    .toList() ??
const [],
```

- [ ] **Step 3: Atualizar `toJson`**

No método `toJson`, adicionar após `'membersIds': membersIds`:

```dart
if (leadersIds.isNotEmpty) 'leadersIds': leadersIds,
```

- [ ] **Step 4: Atualizar `copyWith`**

No método `copyWith`, adicionar parâmetro e atribuição:

```dart
// parâmetro:
List<String>? leadersIds,

// atribuição:
leadersIds: leadersIds ?? this.leadersIds,
```

---

### Task 2: Adicionar métodos de líder no repositório

**Files:**
- Modify: `lib/src/modules/societies/data/societies_repository.dart`

- [ ] **Step 1: Adicionar `addLeader`**

Após o método `removeMember`, adicionar:

```dart
Future<void> addLeader(String societyId, String userId) async {
  await _societies.doc(societyId).update({
    'leadersIds': FieldValue.arrayUnion([userId]),
  });
}
```

- [ ] **Step 2: Adicionar `removeLeader`**

```dart
Future<void> removeLeader(String societyId, String userId) async {
  await _societies.doc(societyId).update({
    'leadersIds': FieldValue.arrayRemove([userId]),
  });
}
```

---

### Task 3: Reescrever `SocietyDetailsPage`

**Files:**
- Rewrite: `lib/src/modules/societies/presentation/society_details_page.dart`

A página passa a ser `StatefulWidget` que:
1. Carrega membros ativos da igreja via `PeopleRepository.fetchMembers()`
2. Resolve nomes localmente a partir dessa lista
3. Exibe seção de Líderes e seção de Membros, ambas com add/remove
4. Admin vê ações; não-admin vê somente leitura

- [ ] **Step 1: Escrever o esqueleto do StatefulWidget**

Substituir todo o conteúdo de `society_details_page.dart` por:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/models/user_model.dart';
import '../../people/data/people_repository.dart';
import '../../../shared/state/app_state.dart';
import '../data/societies_repository.dart';
import '../models/society_model.dart';

class SocietyDetailsPage extends StatefulWidget {
  const SocietyDetailsPage({super.key, required this.society});
  final SocietyModel society;

  @override
  State<SocietyDetailsPage> createState() => _SocietyDetailsPageState();
}

class _SocietyDetailsPageState extends State<SocietyDetailsPage> {
  List<UserModel> _allMembers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final repo = context.read<PeopleRepository>();
    final members = await repo.fetchMembers();
    if (mounted) setState(() { _allMembers = members; _loading = false; });
  }

  UserModel? _resolve(String id) =>
      _allMembers.cast<UserModel?>().firstWhere((m) => m?.id == id, orElse: () => null);

  @override
  Widget build(BuildContext context) {
    // Rebuilt via StreamBuilder below
    final repo = context.read<SocietiesRepository>();

    return StreamBuilder<SocietyModel?>(
      stream: repo.watchById(widget.society.id),
      builder: (context, snap) {
        final society = snap.data ?? widget.society;
        return _buildScaffold(context, society);
      },
    );
  }

  Widget _buildScaffold(BuildContext context, SocietyModel society) {
    final isAdmin = context.read<AppState>().currentUser?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(society.name)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (society.description.isNotEmpty) ...[
                  Text(society.description,
                      style: const TextStyle(color: Colors.white60)),
                  const SizedBox(height: 24),
                ],
                _SectionHeader(
                  title: 'Líderes (${society.leadersIds.length})',
                  icon: Icons.star_rounded,
                  onAdd: isAdmin ? () => _showAddSheet(context, society, isLeader: true) : null,
                ),
                const SizedBox(height: 8),
                if (society.leadersIds.isEmpty)
                  const _EmptyHint(text: 'Nenhum líder definido')
                else
                  ...society.leadersIds.map((id) {
                    final user = _resolve(id);
                    return _SwipeToRemoveTile(
                      key: ValueKey('leader_$id'),
                      name: user?.name ?? id,
                      badge: const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                      canRemove: isAdmin,
                      onRemove: () => context.read<SocietiesRepository>()
                          .removeLeader(society.id, id),
                    );
                  }),
                const SizedBox(height: 24),
                _SectionHeader(
                  title: 'Membros (${society.membersIds.length})',
                  icon: Icons.people_rounded,
                  onAdd: isAdmin ? () => _showAddSheet(context, society, isLeader: false) : null,
                ),
                const SizedBox(height: 8),
                if (society.membersIds.isEmpty)
                  const _EmptyHint(text: 'Nenhum membro adicionado')
                else
                  ...society.membersIds.map((id) {
                    final user = _resolve(id);
                    final isLeader = society.leadersIds.contains(id);
                    return _SwipeToRemoveTile(
                      key: ValueKey('member_$id'),
                      name: user?.name ?? id,
                      badge: isLeader
                          ? const Icon(Icons.star_rounded, size: 14, color: Colors.amber)
                          : null,
                      canRemove: isAdmin,
                      onRemove: () => context.read<SocietiesRepository>()
                          .removeMember(society.id, id),
                    );
                  }),
              ],
            ),
    );
  }

  void _showAddSheet(BuildContext context, SocietyModel society, {required bool isLeader}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddMemberSheet(
        allMembers: _allMembers,
        excludeIds: isLeader ? society.leadersIds : society.membersIds,
        onSelect: (userId) {
          final repo = context.read<SocietiesRepository>();
          if (isLeader) {
            repo.addLeader(society.id, userId);
          } else {
            repo.addMember(society.id, userId);
          }
        },
      ),
    );
  }
}
```

- [ ] **Step 2: Adicionar `watchById` ao repositório**

Em `societies_repository.dart`, adicionar após `fetchById`:

```dart
Stream<SocietyModel?> watchById(String societyId) {
  return _societies.doc(societyId).snapshots().map((doc) {
    if (!doc.exists) return null;
    return SocietyModel.fromFirestore(doc, churchId);
  });
}
```

- [ ] **Step 3: Escrever `_SectionHeader`**

Adicionar ao final de `society_details_page.dart`:

```dart
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    this.onAdd,
  });
  final String title;
  final IconData icon;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white54),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ),
        if (onAdd != null)
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Adicionar',
            onPressed: onAdd,
          ),
      ],
    );
  }
}
```

- [ ] **Step 4: Escrever `_SwipeToRemoveTile`**

```dart
class _SwipeToRemoveTile extends StatelessWidget {
  const _SwipeToRemoveTile({
    super.key,
    required this.name,
    required this.canRemove,
    required this.onRemove,
    this.badge,
  });
  final String name;
  final bool canRemove;
  final Future<void> Function() onRemove;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final tile = ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor:
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(child: Text(name)),
          if (badge != null) ...[const SizedBox(width: 4), badge!],
        ],
      ),
      trailing: canRemove
          ? IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Colors.redAccent),
              onPressed: onRemove,
            )
          : null,
    );

    if (!canRemove) return tile;

    return Dismissible(
      key: key ?? ValueKey(name),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.redAccent),
      ),
      confirmDismiss: (_) async {
        await onRemove();
        return false; // StreamBuilder rebuild faz o tile desaparecer
      },
      child: tile,
    );
  }
}
```

- [ ] **Step 5: Escrever `_EmptyHint`**

```dart
class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(text,
          style: const TextStyle(color: Colors.white38, fontSize: 13)),
    );
  }
}
```

- [ ] **Step 6: Escrever `_AddMemberSheet`**

```dart
class _AddMemberSheet extends StatefulWidget {
  const _AddMemberSheet({
    required this.allMembers,
    required this.excludeIds,
    required this.onSelect,
  });
  final List<UserModel> allMembers;
  final List<String> excludeIds;
  final void Function(String userId) onSelect;

  @override
  State<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<_AddMemberSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final available = widget.allMembers
        .where((m) => !widget.excludeIds.contains(m.id))
        .where((m) =>
            _query.isEmpty ||
            m.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollCtrl) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Buscar membro...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: available.isEmpty
                  ? const Center(
                      child: Text('Nenhum membro disponível',
                          style: TextStyle(color: Colors.white38)))
                  : ListView.builder(
                      controller: scrollCtrl,
                      itemCount: available.length,
                      itemBuilder: (_, i) {
                        final m = available[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.15),
                            child: Text(
                              m.name.isNotEmpty
                                  ? m.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color:
                                    Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          title: Text(m.name),
                          subtitle: Text(m.email,
                              style:
                                  const TextStyle(color: Colors.white38)),
                          onTap: () {
                            widget.onSelect(m.id);
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 7: Hot reload e verificação manual**

Rodar o app e navegar até um grupo. Verificar:
- Seção Líderes e Membros aparecem corretamente
- Botão `+` visível apenas para admin
- Swipe para esquerda mostra fundo vermelho e remove o item
- Ícone de lixeira também remove
- Sheet de adição filtra membros já presentes
- Busca por nome funciona
- Líderes exibem badge de estrela na seção de Membros

---

## Notas

- `confirmDismiss` retorna `false` porque o `StreamBuilder` rebuilda a lista automaticamente — não é necessário remover o widget manualmente, o que evita flash de UI.
- `leadersIds` não tem constraint com `membersIds` no modelo — um líder não precisa estar em `membersIds`. A UI trata as duas listas independentemente.
- `watchById` usa snapshot de documento único, mais eficiente que `watchAll` para uma tela de detalhe.
