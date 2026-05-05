import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../auth/models/user_model.dart';
import '../../societies/data/societies_repository.dart';
import '../../societies/models/society_model.dart';
import '../../../shared/state/app_state.dart';
import '../../../shared/permissions/app_permission.dart';
import '../data/events_repository.dart';
import '../models/event_model.dart';
import 'event_editor_page.dart';
import 'event_viewer_page.dart';
import '../../../shared/widgets/swipe_hint_wrapper.dart';

class PlanningSection extends StatelessWidget {
  const PlanningSection({super.key, required this.user});
  final UserModel user;

  static Map<String, Color> _buildColorMap(List<SocietyModel> societies) {
    return {for (final s in societies) s.id: Color(s.color)};
  }

  static Color _resolveColor(EventModel event, Map<String, Color> colorMap, Color fallback) {
    if (event.societyId != null) {
      final c = colorMap[event.societyId!];
      if (c != null) return c;
    }
    for (final societyId in event.teams.values) {
      final c = colorMap[societyId];
      if (c != null) return c;
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<EventsRepository>();
    final canPlan = context.read<AppState>().can(AppPermission.planEvents);
    final societiesRepo = context.read<SocietiesRepository>();

    return StreamBuilder<List<SocietyModel>>(
      stream: societiesRepo.watchAll(),
      builder: (context, societiesSnap) {
        final colorMap = _buildColorMap(societiesSnap.data ?? []);
        final fallback = Theme.of(context).colorScheme.primary;

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
                    if (canPlan)
                      FilledButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const EventEditorPage()),
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
                    if (canPlan)
                      IconButton(
                        icon: const Icon(Icons.add_rounded),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const EventEditorPage()),
                        ),
                      ),
                  ],
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => Future.delayed(const Duration(milliseconds: 500)),
                    child: ListView.separated(
                    itemCount: events.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final e = events[i];
                      final color = _resolveColor(e, colorMap, fallback);
                      return _PlanningCard(
                        event: e,
                        color: color,
                        canPlan: canPlan,
                        showHint: i == 0,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => EventViewerPage(eventId: e.id, canEdit: canPlan)),
                        ),
                        onEdit: canPlan
                            ? () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => EventEditorPage(eventId: e.id)),
                                )
                            : null,
                        onDelete: canPlan ? () => repo.deleteEvent(e.id) : null,
                      );
                    },
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _PlanningCard extends StatelessWidget {
  const _PlanningCard({
    required this.event,
    required this.onTap,
    required this.color,
    this.canPlan = false,
    this.showHint = false,
    this.onEdit,
    this.onDelete,
  });

  final EventModel event;
  final VoidCallback onTap;
  final Color color;
  final bool canPlan;
  final bool showHint;
  final VoidCallback? onEdit;
  final Future<void> Function()? onDelete;

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Excluir evento'),
            content: Text(
                'Tem certeza que deseja excluir "${event.name}"? Esta ação não pode ser desfeita.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Excluir'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final card = Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: color),
              Expanded(
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
                                  (event.start.isNotEmpty ? ' · ${event.start}' : ''),
                              style: const TextStyle(color: Colors.white54, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      if (canPlan) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          color: Colors.white38,
                          visualDensity: VisualDensity.compact,
                          onPressed: onEdit,
                        ),
                      ],
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded, color: Colors.white24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!canPlan) return card;

    return Dismissible(
      key: ValueKey(event.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.red[700],
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        final confirmed = await _confirmDelete(context);
        if (confirmed) await onDelete?.call();
        return false;
      },
      child: showHint
          ? SwipeHintWrapper(screenKey: 'planning', child: card)
          : card,
    );
  }
}
