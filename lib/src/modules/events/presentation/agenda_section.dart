import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/firebase_config.dart';
import '../../../shared/state/app_state.dart';
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
                    const Icon(Icons.calendar_today_outlined,
                        size: 56, color: Colors.white24),
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
                  final color = _resolveColor(
                      event, colorMap, Theme.of(context).colorScheme.primary);
                  final sid = event.societyId;
                  final societyName =
                      (sid != null && sid != 'Geral') ? nameMap[sid] : null;
                  return _EventCard(
                    event: event,
                    color: color,
                    societyName: societyName,
                    currentUserId:
                        context.read<AppState>().currentUser?.id ?? '',
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

  static Color _resolveColor(
      EventModel event, Map<String, Color> colorMap, Color fallback) {
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

// ── Event card ────────────────────────────────────────────────────────────────

class _EventCard extends StatefulWidget {
  const _EventCard({
    required this.event,
    required this.color,
    required this.currentUserId,
    this.societyName,
  });

  final EventModel event;
  final Color color;
  final String currentUserId;
  final String? societyName;

  @override
  State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard> {
  bool _hasUnread = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  @override
  void initState() {
    super.initState();
    _initUnread();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _openEvent() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventViewerPage(eventId: widget.event.id),
      ),
    );
    // User returned — re-check unread with the updated lastRead timestamp.
    if (mounted) {
      await _sub?.cancel();
      _initUnread();
    }
  }

  Future<void> _initUnread() async {
    final prefs = await SharedPreferences.getInstance();
    final lastReadMs =
        prefs.getInt('chat_last_read_${widget.event.id}') ?? 0;
    final lastRead = DateTime.fromMillisecondsSinceEpoch(lastReadMs);

    _sub = FirebaseConfig.firestore
        .collection('churches')
        .doc(widget.event.churchId)
        .collection('events')
        .doc(widget.event.id)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen(
      (snap) {
        if (!mounted) return;
        if (snap.docs.isEmpty) {
          setState(() => _hasUnread = false);
          return;
        }
        final data = snap.docs.first.data();
        final ts = data['createdAt'];
        final senderId = data['userId']?.toString() ?? '';
        if (ts is Timestamp && senderId != widget.currentUserId) {
          setState(() => _hasUnread = ts.toDate().isAfter(lastRead));
        }
      },
      onError: (_) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final date = widget.event.date;

    return Card(
      child: InkWell(
        onTap: _openEvent,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Date block
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: widget.color,
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
              // Event info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.event.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (widget.societyName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.societyName!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: widget.color,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      widget.event.start.isNotEmpty ? widget.event.start : '—',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white54,
                          ),
                    ),
                    if (_hasUnread) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'Novas mensagens',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
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
