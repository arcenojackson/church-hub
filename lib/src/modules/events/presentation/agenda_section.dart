import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/models/user_model.dart';
import '../../societies/data/societies_repository.dart';
import '../../societies/models/society_model.dart';
import '../data/events_repository.dart';
import '../models/event_model.dart';
import 'event_viewer_page.dart';

class AgendaSection extends StatelessWidget {
  const AgendaSection({super.key, required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final eventsRepo = context.read<EventsRepository>();
    final societiesRepo = context.read<SocietiesRepository>();

    return StreamBuilder<List<SocietyModel>>(
      stream: societiesRepo.watchAll(),
      builder: (context, societiesSnap) {
        final colorMap = _buildColorMap(societiesSnap.data ?? []);

        final nameMap = _buildNameMap(societiesSnap.data ?? []);

        return StreamBuilder<List<EventModel>>(
          stream: eventsRepo.watchUpcoming(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final events = snapshot.data ?? [];
            final allEvents = events.where((e) => e.isUserAssigned(user.id)).toList();

            if (allEvents.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 56, color: Colors.white24),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhum evento próximo',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => Future.delayed(const Duration(milliseconds: 500)),
              child: ListView.separated(
              padding: const EdgeInsets.only(top: 48),
              itemCount: allEvents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final event = allEvents[i];
                final color = _resolveColor(event, colorMap, Theme.of(context).colorScheme.primary);
                final sid = event.societyId;
                final societyName = (sid != null && sid != 'Geral') ? nameMap[sid] : null;
                return _EventCard(
                  event: event,
                  color: color,
                  societyName: societyName,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EventViewerPage(eventId: event.id),
                    ),
                  ),
                );
              },
            ),
            );
          },
        );
      },
    );
  }

  static Map<String, Color> _buildColorMap(List<SocietyModel> societies) {
    return {for (final s in societies) s.id: Color(s.color)};
  }

  static Map<String, String> _buildNameMap(List<SocietyModel> societies) {
    return {for (final s in societies) s.id: s.name};
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
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.onTap,
    required this.color,
    this.societyName,
  });
  final EventModel event;
  final VoidCallback onTap;
  final Color color;
  final String? societyName;

  @override
  Widget build(BuildContext context) {
    final date = event.date;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${date.day}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      _monthAbbr(date.month),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (societyName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        societyName!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      event.start.isNotEmpty ? event.start : '—',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white24),
            ],
          ),
        ),
      ),
    );
  }

  static const _months = [
    'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
    'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
  ];

  String _monthAbbr(int m) => m >= 1 && m <= 12 ? _months[m - 1] : '';
}
