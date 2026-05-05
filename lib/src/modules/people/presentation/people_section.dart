import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../auth/models/user_model.dart';
import '../data/people_repository.dart';
import '../../../shared/state/app_state.dart';
import '../../../modules/profiles/models/profile_model.dart';
import '../../../shared/utils/app_toast.dart';

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
              child: RefreshIndicator(
                onRefresh: () => Future.delayed(const Duration(milliseconds: 500)),
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
            initialValue: profiles.any((p) => p.id == _selectedProfileId)
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
                      if (context.mounted) {
                        showSuccessToast(context, 'Perfil atualizado!');
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
            initialValue: profiles.any((p) => p.id == _selectedProfileId)
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
                      if (context.mounted) {
                        showSuccessToast(context, '${widget.member.name} aprovado!');
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

  static const _iosUrl = 'https://apps.apple.com/app/church-hub';
  static const _androidUrl =
      'https://play.google.com/store/apps/details?id=com.churchhub.app';

  Future<void> _shareViaWhatsApp(BuildContext context, String code) async {
    final message = 'Baixe o Church Hub e entre na nossa igreja '
        'usando o código *$code*!\n\n'
        '📱 iOS: $_iosUrl\n'
        '🤖 Android: $_androidUrl';
    final uri = Uri.parse(
        'https://wa.me/?text=${Uri.encodeComponent(message)}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        showErrorToast(context, 'Não foi possível abrir o WhatsApp.');
      }
    }
  }

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
            tooltip: 'Copiar código',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              showSuccessToast(context, 'Código copiado!');
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Compartilhar via WhatsApp',
            onPressed: () => _shareViaWhatsApp(context, code),
          ),
        ],
      ),
    );
  }
}
