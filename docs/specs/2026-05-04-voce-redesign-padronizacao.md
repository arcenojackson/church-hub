# Spec: Redesign da tela "Você", Padronização de Planejar/Grupos e Remoção de Tiers

**Data:** 2026-05-04
**Status:** Aprovado — pronto para implementação
**Arquivos principais afetados:** `settings_page.dart`, `planning_section.dart`, `societies_page.dart`, `home_shell.dart`, `app_state.dart`

---

## Sumário executivo

Este spec consolida três melhorias relacionadas no Church Hub: o redesign completo da tela "Você" (SettingsSection), que passa de uma lista linear genérica para um layout em card de perfil + grid de acesso rápido + ações de suporte; a padronização dos estados de carregamento, vazio e com itens entre as seções Planejar e Grupos; e a remoção definitiva do sistema de tiers de assinatura, tornando todas as funcionalidades disponíveis para todos os usuários sem distinção.

---

## Motivação / problema atual

**Tela "Você":** A SettingsSection atual mistura seções de navegação (Calendário, Músicas, Pessoas, Avaliações) com configurações do perfil e da conta em uma ListView linear sem hierarquia visual. O card de perfil exibe apenas a primeira inicial do nome (não duas), e o acesso rápido a seções secundárias como Músicas e Pessoas está enterrado em uma lista sem contexto. Igreja e "Apoiar o Church Hub" aparecem como ListTiles de igual peso junto com Notificações e Sair, sem distinção visual.

**Planejar:** Não tem estado de carregamento — o StreamBuilder exibe lista vazia imediatamente enquanto o Firestore ainda não respondeu. O estado vazio exibe apenas texto plano sem ação. O botão "Novo" está em uma Row com o título "Próximos eventos", que ocupa espaço visual de forma desnecessária.

**Grupos:** O estado com itens tem o botão "Novo grupo" como FilledButton.icon em uma Row alinhada à direita, que é funcionalmente correto mas ligeiramente diferente de como Planejar vai funcionar — os dois precisam ser visualmente equivalentes.

**Sistema de tiers:** `isProTier` e `isMaxTier` em AppState já retornam `true` hardcoded (dead code), mas os guards `if (isPro)` e `if (isMax)` ainda existem em `_buildDestinations` do HomeShell, deixando o código com lógica condicional que não tem mais efeito real. Isso confunde quem lê o código e precisa ser limpado.

---

## Escopo

### Incluso

- Redesign completo da SettingsSection (layout, ProfileCard, QuickAccessGrid, DonationBanner, lista de configurações simplificada)
- Nova tela `EditProfilePage` para editar nome (foto de perfil: suporte a atualização via URL ou upload simples — ver Decisão D1)
- Padronização dos estados de loading/empty/filled em `PlanningSection` e `SocietiesPage`
- Remoção dos guards de tier em `HomeShell._buildDestinations` e `SettingsSection`
- Limpeza de `AppState`: remoção dos getters `isProTier` e `isMaxTier` e do campo `_churchSubscription` (e seu setter)
- Remoção das referências a `BillingPage` do código de navegação
- Criação de `DonationPage` simplificada (tela estática com botão de doação — ver Decisão D2)

### Não incluso

- Mudanças no sistema de controle de acesso por perfil (admin vs. membro) — permanece como está
- Upload de foto de perfil para Firebase Storage — ver Decisão D1
- Alteração do visual dos cards de eventos ou grupos — os cards permanecem exatamente iguais
- Mudanças nas telas de destino (EventEditorPage, ChurchSettingsPage, etc.)
- Mudanças em layout tablet/desktop (NavigationRail, sidebar desktop) — apenas o mobile pill nav é afetado pela remoção de guards
- Implementação de notificações (o TODO existente permanece como TODO)

---

## Design detalhado por feature

### 1. Redesign da SettingsSection

#### Estrutura geral

`SettingsSection` passa a ser um `ListView` com as seguintes seções em ordem:

```
[A] ProfileCard          — padding: 20h, 24v
[B] QuickAccessGrid      — GridView 2 colunas, padding: 20h, 16v
[C] DonationBanner       — padding: 20h, 8v
    Divider
[D] Notificações         — ListTile padrão
    Sair                 — ListTile vermelho com confirm dialog
```

Nenhum `SizedBox` de espaçamento extravagante entre seções — o padding interno de cada bloco cria o respiro visual.

#### A — ProfileCard

Widget: `_ProfileCard` (privado, StatelessWidget).

Layout: `Card` de largura total com `borderRadius: 20` e `padding: EdgeInsets.all(20)`.

Conteúdo interno (Column, crossAxisAlignment: start):
1. `Row` com `CircleAvatar(radius: 40)` à esquerda e dados do usuário à direita.
   - CircleAvatar: `backgroundColor: colorScheme.primary.withValues(alpha: 0.2)`, texto com as **duas iniciais** do nome (mesmo algoritmo `_initials` já presente no desktop do HomeShell), `fontSize: 20`, `fontWeight: w700`, `color: colorScheme.primary`.
   - Coluna de dados: nome em `textTheme.titleLarge` bold, email em `TextStyle(color: Colors.white54)`, depois `_RoleChip` já existente.
2. `SizedBox(height: 12)`.
3. `Divider(height: 1, color: Colors.white12)`.
4. `SizedBox(height: 12)`.
5. `Row` com `Icon(Icons.church_rounded, size: 16, color: Colors.white38)`, `SizedBox(width: 6)`, `Text(church.name, style: TextStyle(color: Colors.white54, fontSize: 13))`.

O Card inteiro tem `onTap` que navega para `EditProfilePage`. O tap target inclui toda a área do card — não apenas o nome.

Quando `church` é null (usuário sem igreja associada), a linha de igreja é omitida silenciosamente (uso de `if (church != null) ...`).

#### B — QuickAccessGrid

Widget: `_QuickAccessGrid` (privado, StatelessWidget). Recebe `user`, `church` e `isAdmin`.

`GridView.count(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, shrinkWrap: true, physics: NeverScrollableScrollPhysics(), childAspectRatio: 1.0)`.

Tiles sempre visíveis (sem guarda de role, exceto "Pessoas" que é admin-only como antes):

| Tile | Ícone | Badge contextual | Destino |
|---|---|---|---|
| Igreja | `Icons.church_rounded` | — | `ChurchSettingsPage` |
| Calendário | `Icons.calendar_month_rounded` | "X eventos esta semana" | `CalendarPage` |
| Músicas | `Icons.music_note_rounded` | — | `MusicsSection` |
| Pessoas | `Icons.people_outline_rounded` | "X aguardando aprovação" (só admin) | `PeopleSection` |
| Avaliações | `Icons.star_outline_rounded` | "X pendentes" | `EvaluationsListPage` |

Quando `isAdmin` é false, o tile "Pessoas" é omitido do grid (o grid terá 4 ou 5 tiles dependendo do role).

Cada tile — widget `_QuickAccessTile`:
- `Card` com `borderRadius: 16`, `onTap` via `InkWell`.
- `Column(mainAxisAlignment: MainAxisAlignment.center)`:
  - `Icon(icon, size: 28, color: Colors.white70)`.
  - `SizedBox(height: 8)`.
  - `Text(label, style: textTheme.labelMedium, textAlign: center)`.
  - `SizedBox(height: 6)`.
  - Badge pill: `_BadgePill(text: badgeText)` — visível apenas quando `badgeText != null`.

`_BadgePill`: `Container` com `padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2)`, `decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20))`, `Text(text, style: TextStyle(color: colorScheme.primary, fontSize: 11, fontWeight: w600))`.

Dados contextuais dos badges são carregados via `FutureBuilder` diretamente dentro de `_QuickAccessTile`. Enquanto o Future não resolveu, o espaço do badge é ocupado por um `SizedBox(height: 18)` invisível (não há spinner — o tile fica estático). Se o Future falhar, o badge simplesmente não aparece (silencia o erro — não é dado crítico).

Queries necessárias para os badges:
- **Calendário — "X eventos esta semana":** Consulta na coleção `events` do Firestore, filtro `date >= início da semana atual` e `date <= fim da semana atual`. Retorna count. String: `"$count esta semana"` (se count == 0, badge invisível).
- **Pessoas — "X aguardando aprovação":** Consulta `users` com `churchId == church.id` e `status == 'pending'`. Retorna count. String: `"$count aguardando"` (se count == 0, badge invisível — não existe campo `status` hoje: ver Decisão D3).
- **Avaliações — "X pendentes":** Consulta `music_evaluations` com `status == 'pending'` ou equivalente. String: `"$count pendentes"` (se count == 0, badge invisível — ver Decisão D3).

Os `FutureBuilder`s são inicializados uma única vez — não atualizam em tempo real. A tela inteira reconstrói quando o usuário retorna de uma subpage (comportamento padrão do Flutter com o ciclo de vida da rota mãe).

Destinos navegam usando `_SectionShell` existente (mesmo padrão atual), exceto `Igreja` que usa `ChurchSettingsPage` diretamente com `MaterialPageRoute` puro (já tem AppBar próprio).

#### C — DonationBanner

Widget: `_DonationBanner` (privado, StatelessWidget).

`Card` com fundo levemente tinted (usar `colorScheme.surfaceContainerHighest` ou equivalente), `padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)`, `onTap` navega para `DonationPage`.

Layout: `Row`:
- `Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 22)`.
- `SizedBox(width: 12)`.
- `Expanded(child: Column(crossAxisAlignment: start))`:
  - `Text('Apoiar o Church Hub', style: textTheme.labelLarge?.copyWith(fontWeight: w600))`.
  - `Text('Ajude-nos a manter o app gratuito', style: TextStyle(color: Colors.white54, fontSize: 12))`.
- `Icon(Icons.chevron_right_rounded, color: Colors.white24)`.

#### D — Lista de configurações (fina)

Apenas dois itens, sem agrupamento com Divider entre eles:

1. **Notificações:**
   ```
   ListTile(
     leading: Icon(Icons.notifications_outlined),
     title: Text('Notificações'),
     trailing: Icon(Icons.chevron_right_rounded),
     onTap: () {}, // TODO: Notification settings
   )
   ```

2. **Sair:** Mantém exatamente o comportamento atual (confirm dialog com AlertDialog, `signOut()`, `popUntil(isFirst)`). Sem mudanças.

Igreja e "Apoiar o Church Hub" saem desta lista — Igreja vai para o grid, doação vira o DonationBanner.

#### Remoção do AppBar

`SettingsPage` (o wrapper com `AppBar(title: Text('Configurações'))`) não é removida — ela é usada no desktop quando o usuário clica no ícone de settings. A mudança é apenas na `SettingsSection` inline do mobile. O título "Você" já aparece via `_AppHeader` do HomeShell — não duplicar título na SettingsSection.

---

### 2. Nova tela EditProfilePage

Arquivo: `lib/src/modules/auth/presentation/edit_profile_page.dart`.

`StatefulWidget` com `Scaffold` + AppBar padrão com title `'Editar perfil'` e botão de salvar no `actions` (TextButton `'Salvar'`).

Campos editáveis:
- **Foto de perfil:** CircleAvatar de iniciais com `IconButton(Icons.camera_alt_outlined)` sobreposto — exibe `SnackBar('Em breve: suporte a foto de perfil')` quando tocado (Decisão D1).
- **Nome:** `TextFormField` obrigatório. Pré-populado com `appState.currentUser!.name`.
- **Telefone:** `TextFormField` opcional. `keyboardType: TextInputType.phone`. Pré-populado com `appState.currentUser!.phone` (campo a adicionar em `UserModel`).
- **Aniversário:** `TextFormField` somente leitura com `onTap` abrindo `showDatePicker`. Exibe a data formatada como `dd/MM/yyyy`. Pré-populado com `appState.currentUser!.birthday` (campo a adicionar em `UserModel`).

`UserModel` ganha dois campos opcionais: `phone: String?` e `birthday: DateTime?`, ambos mapeados para Firestore (`phone` como string, `birthday` como Timestamp).

Ao salvar: chama `appState.updateUserProfile(name, phone, birthday)` (método novo em AppState, que chama `FirebaseFirestore` para atualizar os campos no documento do usuário). Exibe `CircularProgressIndicator` inline no botão enquanto salva. Em caso de erro, exibe SnackBar com a mensagem de erro. Em caso de sucesso, `Navigator.of(context).pop()`.

---

### 3. Nova tela DonationPage (simplificada)

Arquivo: `lib/src/modules/billing/presentation/donation_page.dart` (substituição da `DonationPage` existente que era referenciada mas possivelmente já existia no código antigo).

Tela estática, `Scaffold` com AppBar `'Apoiar o Church Hub'`.

Corpo (Column centralizada, padding 24):
- Ícone `Icons.favorite_rounded` tamanho 64, cor `Colors.pinkAccent`.
- `SizedBox(height: 24)`.
- `Text('Apoiar o Church Hub', style: textTheme.headlineSmall, textAlign: center)`.
- `SizedBox(height: 12)`.
- `Text` com parágrafo de agradecimento e explicação de que o app é gratuito e mantido pela comunidade, `textAlign: center, color: Colors.white70`.
- `SizedBox(height: 32)`.
- `FilledButton.icon(icon: Icon(Icons.open_in_new_rounded), label: Text('Fazer uma doação'))` que abre URL externa (usar `url_launcher` — se já estiver no `pubspec.yaml`; caso contrário ver Decisão D4).

`BillingPage` permanece no codebase mas não é mais referenciada por nenhuma rota de navegação. Pode ser deletada numa limpeza futura (não faz parte deste spec).

---

### 4. Padronização PlanningSection

#### Estado de carregamento (novo)

Adicionar verificação de `ConnectionState.waiting` no StreamBuilder, antes de verificar `events.isEmpty`:

```
if (snapshot.connectionState == ConnectionState.waiting) {
  return const Center(child: CircularProgressIndicator());
}
```

#### Estado vazio (melhorado)

Substituir o `Center(child: Text('Nenhum evento cadastrado'))` por:

```
Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.auto_awesome_motion_outlined, size: 56, color: Colors.white24),
      SizedBox(height: 16),
      Text('Nenhum evento cadastrado', style: TextStyle(color: Colors.white54)),
      SizedBox(height: 24),
      FilledButton.icon(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const EventEditorPage()),
        ),
        icon: Icon(Icons.add_rounded),
        label: Text('Novo evento'),
      ),
    ],
  ),
)
```

O botão de criar no empty state é exibido **independente do role** do usuário (Decisão D5 — ver abaixo). O controle de acesso dentro do EventEditorPage já valida se o usuário pode criar eventos.

#### Estado com itens (botão reposicionado)

Remover a `Row` com `Text('Próximos eventos')` e `FilledButton.icon('Novo')`.

Substituir o `Column` raiz do StreamBuilder por um `Stack`:
- Camada base: `ListView.separated` (sem alterações no card).
- Camada superior: `Positioned(top: 0, right: 0, child: IconButton(icon: Icon(Icons.add_rounded), onPressed: ...))`.

Alternativamente (mais simples e consistente com Grupos): usar `Column` com um `Row(mainAxisAlignment: end)` contendo apenas `IconButton(Icons.add_rounded)` no topo, seguido do `Expanded(ListView)`. Esta abordagem é preferida por não introduzir `Stack` desnecessário.

Estrutura final do estado com itens:
```
Column(
  children: [
    Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          icon: Icon(Icons.add_rounded),
          onPressed: () => Navigator.push(EventEditorPage),
        ),
      ],
    ),
    Expanded(child: ListView.separated(...)),
  ],
)
```

---

### 5. Padronização SocietiesPage

A SocietiesPage já tem loading state e empty state corretos. A única mudança é no estado com itens.

#### Estado com itens (botão padronizado)

Substituir o `FilledButton.icon('Novo grupo')` atual por `IconButton(Icons.add_rounded)`, usando a mesma estrutura de Row que PlanningSection terá:

```
Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    if (isAdmin)
      IconButton(
        icon: Icon(Icons.add_rounded),
        onPressed: () => _showCreateSheet(context),
      ),
  ],
),
```

O `SizedBox(height: 16)` entre o botão e a lista permanece.

---

### 6. Remoção do sistema de tiers

#### HomeShell._buildDestinations

Remover as variáveis `isPro` e `isMax`. Remover os guards `if (isPro)` e `if (isMax)`. Todas as seções passam a ser incluídas condicionadas apenas por `isAdmin` onde faz sentido por controle de acesso (Planning e People continuam sendo admin-only por lógica de negócio, não por tier).

Após a mudança, `_buildDestinations` fica:
```dart
List<_Destination> _buildDestinations(UserModel user, AppState appState) {
  final isAdmin = user.isAdmin;
  return [
    _Destination(section: HomeSection.agenda, ...),
    if (isAdmin) _Destination(section: HomeSection.planning, ...),
    _Destination(section: HomeSection.societies, ...),  // sempre visível
    _Destination(section: HomeSection.settings, ...),
    _Destination(section: HomeSection.calendar, ...),
    _Destination(section: HomeSection.musics, ...),
    if (isAdmin) _Destination(section: HomeSection.people, ...),
    _Destination(section: HomeSection.evaluations, ...),  // sempre visível
  ];
}
```

#### SettingsSection

Remover a variável `isMax` e o guard `if (isMax)` que escondia o tile de Avaliações. Como a seção inteira vai ser reescrita (feature 1), isso ocorre naturalmente.

#### AppState

Remover os getters `isProTier` e `isMaxTier` (atualmente hardcoded como `true` — dead code seguro de remover).

Remover o campo `_churchSubscription`, o getter `churchSubscription` e o método `setChurchSubscription`. O import de `ChurchSubscriptionModel` também pode ser removido se não houver outras referências.

Verificar se `ChurchSubscriptionModel` e o arquivo `church_subscription_model.dart` são referenciados em outros lugares antes de deletar.

---

## Modelo de dados / mudanças necessárias

### Firestore — sem mudanças de schema

Nenhuma coleção nova precisa ser criada para este spec. Os badges do QuickAccessGrid fazem queries de leitura em coleções existentes. Se os campos `status` em `users` ou `music_evaluations` não existirem, os respectivos badges simplesmente nunca aparecem (o FutureBuilder retorna count 0 → badge invisível).

### AppState

- Remover: `_churchSubscription`, getter `churchSubscription`, método `setChurchSubscription`, getters `isProTier`, `isMaxTier`.
- Remover: import de `church_subscription_model.dart` (verificar ausência de outras referências).
- Manter: todos os outros campos, métodos e lógica de `signOut` (que já limpa `_churchSubscription` — remover essa linha junto).

### UserModel

Adicionar dois campos opcionais:
- `phone: String?` — mapeado para Firestore como campo `phone` (string).
- `birthday: DateTime?` — mapeado para Firestore como campo `birthday` (Timestamp).

Ambos com valor padrão `null`. Retrocompatível — documentos existentes sem esses campos continuam funcionando.

### AppState

Além das remoções de tier, adicionar método `updateUserProfile(String name, String? phone, DateTime? birthday)` que atualiza o documento do usuário no Firestore e reflete as mudanças em `_currentUser`.

---

## Arquivos a criar / modificar

### Criar

| Arquivo | Descrição |
|---|---|
| `lib/src/modules/auth/presentation/edit_profile_page.dart` | Nova tela de edição de perfil (nome, telefone, aniversário, placeholder de foto) |
| `lib/src/modules/billing/presentation/donation_page.dart` | Substituição simplificada da DonationPage (se não existir ainda) |

### Modificar

| Arquivo | O que muda |
|---|---|
| `lib/src/modules/auth/presentation/settings_page.dart` | Reescrita completa da `SettingsSection`; adição dos widgets `_ProfileCard`, `_QuickAccessGrid`, `_QuickAccessTile`, `_BadgePill`, `_DonationBanner`; remoção da seção "Seções" com ListTiles; remoção do import de `BillingPage` |
| `lib/src/modules/events/presentation/planning_section.dart` | Adição de loading state; melhoria do empty state; substituição do header Row por IconButton no topo direito |
| `lib/src/modules/societies/presentation/societies_page.dart` | Substituição do FilledButton.icon por IconButton no estado com itens |
| `lib/src/modules/home/presentation/home_shell.dart` | Remoção de `isPro`, `isMax` e guards correspondentes em `_buildDestinations` |
| `lib/src/shared/state/app_state.dart` | Remoção de `isProTier`, `isMaxTier`, `_churchSubscription`, `churchSubscription`, `setChurchSubscription`; adição de `updateUserProfile` |
| `lib/src/modules/auth/models/user_model.dart` | Adição de campos `phone: String?` e `birthday: DateTime?` |

### Verificar / possivelmente deletar

| Arquivo | Ação |
|---|---|
| `lib/src/modules/church/models/church_subscription_model.dart` | Verificar referências; deletar se não usado em outro lugar |
| `lib/src/modules/billing/presentation/billing_page.dart` | Deixar no codebase (sem referências ativas); pode ser deletado numa limpeza futura |

---

## Considerações de implementação

### Ordem de trabalho recomendada

1. **Limpeza de tiers (AppState + HomeShell)** — sem risco visual, puramente estrutural. Fazer primeiro para limpar o código antes das mudanças visuais. Testar que todas as seções aparecem corretamente no nav após a remoção dos guards.

2. **Padronização PlanningSection** — mudança isolada, fácil de testar: verificar loading state (simular delay de rede), empty state (conta sem eventos), estado com itens (conta com eventos e botão de adicionar funcional).

3. **Padronização SocietiesPage** — análoga ao passo anterior, ainda mais simples.

4. **EditProfilePage** — nova tela independente, sem dependências de UI do passo 5.

5. **DonationPage simplificada** — nova tela estática, sem dependências.

6. **Redesign SettingsSection** — a mais complexa. Fazer por último, quando as telas de destino já estão prontas. Implementar na ordem: ProfileCard → QuickAccessGrid (sem badges primeiro) → DonationBanner → lista de configurações → badges com FutureBuilder.

### Riscos e mitigações

**Risk:** Os FutureBuilders dos badges podem causar flickering visual ao entrar na tela "Você".
**Mitigação:** O badge começa invisível (`SizedBox` do mesmo tamanho) e aparece apenas quando o Future resolve — sem layout shift perceptível. Não usar `CircularProgressIndicator` nos tiles.

**Risk:** `_buildDestinations` é chamado em `didChangeDependencies`, que pode ser chamado mais de uma vez. Remover os guards de tier não muda este comportamento.
**Mitigação:** Nenhuma — o comportamento existente é mantido.

**Risk:** Remoção de `setChurchSubscription` pode quebrar chamada em outro ponto do app (ex: ChurchSettingsPage ou um bootstrap listener).
**Mitigação:** Buscar todas as referências a `setChurchSubscription` e `churchSubscription` no codebase antes de remover. Se encontradas, avaliar caso a caso — provavelmente o bootstrap listener precisará ter a chamada removida também.

**Risk:** `url_launcher` pode não estar no `pubspec.yaml` (necessário para o botão de doação).
**Mitigação:** Verificar `pubspec.yaml` antes de implementar `DonationPage`. Se ausente, o botão pode exibir um SnackBar temporário com a URL de doação até o pacote ser adicionado.

### Decisões tomadas autonomamente

**D1 — Upload de foto de perfil fora do escopo:** O briefing mencionou `onTap` do ProfileCard abrindo `EditProfilePage` que "permite editar nome e foto". A implementação de upload de foto envolve Firebase Storage, seleção de imagem (`image_picker`), crop, e persistência de URL no Firestore — complexidade desproporcional para este spec. A decisão é incluir apenas edição de nome agora, com um placeholder interativo que comunica "em breve" para o usuário.

**D2 — DonationPage como tela estática com link externo:** O briefing não especificou o destino final da doação (PIX? Link externo? Stripe?). A decisão é criar uma tela estática com botão que abre URL externa, que pode ser configurada depois com o método/plataforma de pagamento escolhido.

**D3 — Badges de "aguardando aprovação" e "avaliações pendentes" dependem de campos existentes:** Se o campo `status` em `users` ou `music_evaluations` não existir, a query retorna 0 resultados e o badge simplesmente não aparece. Nenhuma migração de dados é necessária para o spec — os badges são additive.

**D4 — `url_launcher` como dependência condicional:** Se o pacote não estiver no `pubspec.yaml`, o botão de doação usa SnackBar como fallback temporário. A adição do pacote é responsabilidade do implementador verificar.

**D5 — Botão de "Novo evento" no empty state visível para todos:** O briefing não especificou se o botão de criar no empty state da PlanningSection deve ser restrito a admins. Como a PlanningSection já é acessível apenas por admins (guard `if (isAdmin)` no HomeShell permanece), qualquer usuário que chegue à tela já é admin — o guard no botão seria redundante. Decisão: sem guard no botão do empty state.

**D6 — IconButton vs FilledButton.icon no estado com itens:** O briefing mencionou "IconButton(Icons.add_rounded) ou FilledButton.icon pequeno alinhado ao canto superior direito". A decisão é usar `IconButton` para ambas as telas (Planejar e Grupos) por ser mais compacto e consistente entre si. O FilledButton.icon permanece apenas no estado vazio, onde precisa de mais destaque.
