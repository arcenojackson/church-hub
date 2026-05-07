import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/state/app_state.dart';
import '../../../shared/utils/app_toast.dart';
import '../models/user_model.dart';
import 'edit_profile_page.dart';
import '../../church/presentation/church_settings_page.dart';
import '../../profiles/presentation/profiles_page.dart';
import '../../events/data/events_repository.dart';
import '../../events/data/calendar_batch_repository.dart';
import '../../events/presentation/calendar_batch_settings_page.dart';
import '../../events/presentation/calendar_page.dart';
import '../../musics/presentation/musics_section.dart';
import '../../music_evaluations/presentation/evaluations_list_page.dart';
import '../../people/data/people_repository.dart';
import '../../people/presentation/people_section.dart';
import '../../notifications/presentation/notification_settings_page.dart';
import '../../../web/delete_account_page.dart';

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
        const SizedBox(height: 12),
        _DonationBanner(),
        const SizedBox(height: 8),
        _QuickAccessGrid(isAdmin: isAdmin, churchId: church?.id),
        const Divider(height: 32),
        ListTile(
          leading: const Icon(Icons.notifications_outlined),
          title: const Text('Notificações'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const NotificationSettingsPage(),
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.chat_bubble_outline_rounded),
          title: const Text('Enviar dicas ou sugestões'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () async {
            final uri = Uri(
              scheme: 'mailto',
              path: 'me@arcenojackson.dev',
              queryParameters: {
                'subject': 'Elogios/Sugestões de Church Hub',
              },
            );
            try {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } catch (_) {
              if (context.mounted) {
                showErrorToast(context, 'Não foi possível abrir o app de email.');
              }
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
          title: const Text('Excluir conta', style: TextStyle(color: Colors.redAccent)),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DeleteAccountPage(
                onSuccess: () async {
                  await appState.signOut();
                  if (context.mounted) {
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  }
                },
              ),
            ),
          ),
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
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
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
      padding: const EdgeInsets.symmetric(horizontal: 12),
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
      // Linha 1: Sua igreja | Calendário
      _QuickAccessTile(
        icon: Icons.church_rounded,
        label: 'Sua igreja',
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
          MaterialPageRoute(builder: (_) => const CalendarPage()),
        ),
      ),
      // Linha 2: Pessoas | Perfis
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
      if (isAdmin)
        _QuickAccessTile(
          icon: Icons.badge_outlined,
          label: 'Perfis',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProfilesPage()),
          ),
        ),
      // Linha 3: Compromissos fixos | Músicas
      if (isAdmin)
        _QuickAccessTile(
          icon: Icons.event_note_outlined,
          label: 'Compromissos fixos',
          badgeFuture: churchId != null
              ? _templateCount(churchId)
              : Future.value(null),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CalendarBatchSettingsPage()),
          ),
        ),
      _QuickAccessTile(
        icon: Icons.music_note_rounded,
        label: 'Músicas',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => _SectionShell(
                  title: 'Músicas',
                  child: MusicsSection(canEdit: isAdmin))),
        ),
      ),
      // Linha 4: Avaliações musicais
      _QuickAccessTile(
        icon: Icons.rate_review_rounded,
        label: 'Avaliações musicais',
        badgeFuture: Future.value('Em contrução...'),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => const _SectionShell(
                  title: 'Avaliações musicais', child: EvaluationsListPage())),
        ),
      ),
    ];
  }

  Future<String?> _eventsThisWeek(String churchId) async {
    final count = await EventsRepository(churchId: churchId).countEventsThisWeek();
    return count > 0 ? '$count esta semana' : null;
  }

  Future<String?> _pendingMembers(String churchId) async {
    final count = await PeopleRepository(churchId: churchId).countPendingMembers();
    return count > 0 ? '$count aguardando' : null;
  }

  Future<String?> _templateCount(String churchId) async {
    final count = await CalendarBatchRepository(churchId: churchId).countTemplates();
    return count > 0 ? '$count ${count == 1 ? 'template' : 'templates'}' : null;
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
  static const _donationUrl =
      'https://donate.stripe.com/5kQeVddXg5ZpfOdezO87K00';

  Future<void> _openDonation(BuildContext context) async {
    final uri = Uri.parse(_donationUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        showErrorToast(context, 'Não foi possível abrir o link.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tileHeight = (constraints.maxWidth - 12) / 2;
          final bannerHeight = tileHeight * 0.5;
          return SizedBox(
            height: bannerHeight,
            child: Card(
              child: InkWell(
                onTap: () => _openDonation(context),
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.favorite_rounded,
                          color: Colors.pinkAccent, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
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
        },
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
                  padding: const EdgeInsets.symmetric(horizontal: 12),
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
