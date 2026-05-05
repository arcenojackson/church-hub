import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/firebase_config.dart';
import '../../../shared/state/app_state.dart';
import '../../auth/models/user_model.dart';
import '../../musics/data/musics_repository.dart';
import '../../musics/models/music_model.dart';
import '../../musics/presentation/music_detail_page.dart';
import '../../people/data/people_repository.dart';
import '../../../shared/utils/tone_utils.dart';
import '../data/events_repository.dart';
import '../models/event_model.dart';
import 'event_chat_page.dart';
import 'widgets/step_editor_sheet.dart';
import 'widgets/people_selector_sheet.dart';

class EventViewerPage extends StatefulWidget {
  const EventViewerPage({
    super.key,
    required this.eventId,
    this.initialTabIndex = 0,
    this.canEdit = false,
  });

  final String eventId;
  final int initialTabIndex;
  final bool canEdit;

  @override
  State<EventViewerPage> createState() => _EventViewerPageState();
}

class _EventViewerPageState extends State<EventViewerPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  bool _isLoading = false;
  EventModel? _event;
  List<EventStepModel> _steps = const [];
  Map<String, List<String>> _people = const {};
  List<MusicModel> _musics = const [];
  List<UserModel> _members = const [];
  int _currentTabIndex = 0;

  bool _hasUnread = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _chatSub;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _tabCtrl.addListener(_onTabChanged);
    _loadData();
    _initChatUnread();
  }

  @override
  void dispose() {
    _tabCtrl.removeListener(_onTabChanged);
    _tabCtrl.dispose();
    _chatSub?.cancel();
    super.dispose();
  }

  void _onTabChanged() {
    if (_currentTabIndex != _tabCtrl.index) {
      setState(() => _currentTabIndex = _tabCtrl.index);
    }
  }

  Future<void> _loadData() async {
    final musicsRepo = context.read<MusicsRepository>();
    final peopleRepo = context.read<PeopleRepository>();

    if (widget.canEdit) {
      setState(() => _isLoading = true);
      final repo = context.read<EventsRepository>();
      try {
        final event = await repo.fetchById(widget.eventId);
        if (event == null) {
          if (mounted) setState(() => _isLoading = false);
          return;
        }
        List<MusicModel> musics = const [];
        List<UserModel> members = const [];
        try {
          musics = await musicsRepo.fetchAll();
        } catch (_) {}
        try {
          members = await peopleRepo.fetchMembers();
        } catch (_) {}
        if (mounted) {
          setState(() {
            _event = event;
            _steps = List.of(event.steps);
            _people = Map.of(event.people);
            _musics = musics;
            _members = members;
            _isLoading = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      // Read mode: carregar músicas e membros em background (sem bloquear a UI)
      try {
        final musics = await musicsRepo.fetchAll();
        if (mounted) setState(() => _musics = musics);
      } catch (_) {}
      try {
        final members = await peopleRepo.fetchMembers();
        if (mounted) setState(() => _members = members);
      } catch (_) {}
    }
  }

  Future<void> _autoSave() async {
    final event = _event;
    if (event == null) return;
    try {
      await context.read<EventsRepository>().updateEvent(
            event.id,
            steps: _steps,
            people: _people,
          );
    } catch (_) {}
  }

  // --- Steps (edit) ---

  Future<void> _addStep() async {
    final result = await showModalBottomSheet<EventStepModel>(
      context: context,
      isScrollControlled: true,
      builder: (_) => StepEditorSheet(musics: _musics),
    );
    if (result != null) {
      setState(() => _steps = [..._steps, result]);
      _autoSave();
    }
  }

  Future<void> _editStep(int index) async {
    final result = await showModalBottomSheet<EventStepModel>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          StepEditorSheet(musics: _musics, initialStep: _steps[index]),
    );
    if (result != null) {
      final updated = List<EventStepModel>.of(_steps);
      updated[index] = result;
      setState(() => _steps = updated);
      _autoSave();
    }
  }

  void _removeStep(int index) {
    setState(() => _steps = List.of(_steps)..removeAt(index));
    _autoSave();
  }

  // --- People (edit) ---

  Future<void> _addPerson() async {
    final roles =
        context.read<AppState>().churchSettings?.eloRoles ?? const [];
    final result = await showModalBottomSheet<Map<String, List<String>>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PeopleSelectorSheet(
        members: _members,
        currentPeople: _people,
        roles: roles,
      ),
    );
    if (result != null) {
      setState(() {
        final updated = Map<String, List<String>>.of(_people);
        result.forEach((roleId, userIds) => updated[roleId] = userIds);
        _people = updated;
      });
      _autoSave();
    }
  }

  void _removePerson(String roleId, String userId) {
    setState(() {
      final updated = Map<String, List<String>>.of(_people);
      final list = List<String>.of(updated[roleId] ?? [])..remove(userId);
      if (list.isEmpty) {
        updated.remove(roleId);
      } else {
        updated[roleId] = list;
      }
      _people = updated;
    });
    _autoSave();
  }

  // --- Chat (read) ---

  Future<void> _initChatUnread() async {
    final churchId = context.read<EventsRepository>().churchId;
    final myId = context.read<AppState>().currentUser?.id ?? '';
    final prefs = await SharedPreferences.getInstance();
    final lastReadMs = prefs.getInt('chat_last_read_${widget.eventId}') ?? 0;
    final lastRead = DateTime.fromMillisecondsSinceEpoch(lastReadMs);

    _chatSub = FirebaseConfig.firestore
        .collection('churches')
        .doc(churchId)
        .collection('events')
        .doc(widget.eventId)
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
        // Show badge for messages from others that are newer than lastRead
        if (ts is Timestamp && senderId != myId) {
          setState(() => _hasUnread = ts.toDate().isAfter(lastRead));
        }
      },
      onError: (_) {/* fail silently — badge simply won't show */},
    );
  }

  Future<void> _markChatAsRead() async {
    if (!mounted) return;
    setState(() => _hasUnread = false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'chat_last_read_${widget.eventId}',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  void _openChat(EventModel event) {
    _markChatAsRead();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.85,
        child: EventChatPage(
          event: event,
          onOpened: _markChatAsRead,
        ),
      ),
    );
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    return widget.canEdit ? _buildEditMode() : _buildReadMode();
  }

  // ── Edit mode ──────────────────────────────────────────────────────────────

  Widget _buildEditMode() {
    final event = _event;
    final title = event == null
        ? 'Carregando...'
        : '${event.name} (${DateFormat('dd/MM').format(event.date)})';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(icon: Icon(Icons.list_rounded), text: 'Etapas'),
            Tab(icon: Icon(Icons.people_outline), text: 'Pessoas'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : event == null
              ? const Center(child: Text('Evento não encontrado'))
              : TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _StepsEditTab(
                      steps: _steps,
                      onReorder: (oldIndex, newIndex) {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final updated = List<EventStepModel>.of(_steps);
                        final item = updated.removeAt(oldIndex);
                        updated.insert(newIndex, item);
                        setState(() => _steps = updated);
                        _autoSave();
                      },
                      onEdit: _editStep,
                      onRemove: _removeStep,
                    ),
                    _PeopleEditTab(
                      people: _people,
                      members: _members,
                      onRemove: _removePerson,
                    ),
                  ],
                ),
      floatingActionButton: _isLoading || event == null
          ? null
          : _currentTabIndex == 0
              ? FloatingActionButton(
                  onPressed: _addStep,
                  child: const Icon(Icons.add),
                )
              : FloatingActionButton(
                  onPressed: _addPerson,
                  child: const Icon(Icons.group_add),
                ),
    );
  }

  // ── Read-only mode ─────────────────────────────────────────────────────────

  Widget _buildReadMode() {
    final repo = context.read<EventsRepository>();

    return StreamBuilder<EventModel?>(
      stream: repo._watchById(widget.eventId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final event = snapshot.data;
        if (event == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Evento não encontrado')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(event.name),
            actions: [
              IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded),
                    if (_hasUnread)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                tooltip: 'Chat do evento',
                onPressed: () => _openChat(event),
              ),
            ],
            bottom: TabBar(
              controller: _tabCtrl,
              tabs: const [
                Tab(icon: Icon(Icons.list_rounded), text: 'Etapas'),
                Tab(icon: Icon(Icons.people_outline), text: 'Pessoas'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabCtrl,
            children: [
              _StepsReadTab(event: event, musics: _musics),
              _PeopleReadTab(event: event, members: _members),
            ],
          ),
        );
      },
    );
  }
}

// ── Private extension ────────────────────────────────────────────────────────

extension on EventsRepository {
  Stream<EventModel?> _watchById(String id) {
    return FirebaseConfig.firestore
        .collection('churches')
        .doc(churchId)
        .collection('events')
        .doc(id)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      data['churchId'] = churchId;
      return EventModel.fromJson(data);
    });
  }
}

// ── Edit-mode tabs ─────────────────────────────────────────────────────────

class _StepsEditTab extends StatelessWidget {
  const _StepsEditTab({
    required this.steps,
    required this.onReorder,
    required this.onEdit,
    required this.onRemove,
  });

  final List<EventStepModel> steps;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(int index) onEdit;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.list_alt, size: 64, color: Colors.white38),
              SizedBox(height: 16),
              Text(
                'Nenhuma etapa adicionada.\nToque em + para adicionar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: steps.length,
      onReorder: onReorder,
      itemBuilder: (context, index) {
        final step = steps[index];
        final isMusic = step.type == EventStepType.music;

        return Card(
          key: ValueKey('step_${index}_${step.title}'),
          margin: const EdgeInsets.only(bottom: 4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.drag_handle, color: Colors.white38),
                const SizedBox(width: 8),
                Icon(
                  isMusic
                      ? Icons.music_note_rounded
                      : Icons.list_alt_rounded,
                  color: Colors.white54,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(step.title,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                      if (step.description?.isNotEmpty == true) ...[
                        const SizedBox(height: 2),
                        Text(step.description!,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12)),
                      ],
                      if (isMusic && step.musicTone != null) ...[
                        const SizedBox(height: 4),
                        Chip(
                          label: Text('Tom: ${toneLabel(step.musicTone!)}',
                              style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: () => onEdit(index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 18),
                      color: Colors.red[300],
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: () => onRemove(index),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PeopleEditTab extends StatelessWidget {
  const _PeopleEditTab({
    required this.people,
    required this.members,
    required this.onRemove,
  });

  final Map<String, List<String>> people;
  final List<UserModel> members;
  final void Function(String roleId, String userId) onRemove;

  String _resolveName(String userId) {
    try {
      return members.firstWhere((m) => m.id == userId).name;
    } catch (_) {
      return userId;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (people.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_outline, size: 64, color: Colors.white38),
              SizedBox(height: 16),
              Text(
                'Nenhuma pessoa escalada.\nToque em + para adicionar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: people.entries.map((entry) {
          final roleId = entry.key;
          final userIds = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roleId,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: userIds.map((userId) {
                    return InputChip(
                      label: Text(_resolveName(userId)),
                      onDeleted: () => onRemove(roleId, userId),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Read-only tabs ─────────────────────────────────────────────────────────

class _StepsReadTab extends StatelessWidget {
  const _StepsReadTab({required this.event, required this.musics});

  final EventModel event;
  final List<MusicModel> musics;

  MusicModel? _findMusic(String? musicId) {
    if (musicId == null) return null;
    try {
      return musics.firstWhere((m) => m.id == musicId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = event.steps;
    if (steps.isEmpty) {
      return const Center(child: Text('Sem roteiro cadastrado'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: steps.length,
      itemBuilder: (_, i) {
        final step = steps[i];
        final isMusic = step.type == EventStepType.music;

        if (isMusic) {
          final music = _findMusic(step.musicId);
          return _MusicStepCard(
            step: step,
            music: music,
          );
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.list_alt_rounded, color: Colors.white38),
            title: Text(step.title),
            subtitle: step.description?.isNotEmpty == true
                ? Text(step.description!)
                : null,
          ),
        );
      },
    );
  }
}

class _MusicStepCard extends StatelessWidget {
  const _MusicStepCard({
    required this.step,
    this.music,
  });

  final EventStepModel step;
  final MusicModel? music;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final tappable = music != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: tappable
            ? () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MusicDetailPage(
                      music: music!,
                      overrideTone: step.musicTone,
                      showEdit: false,
                    ),
                  ),
                )
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              // Ícone de música
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.music_note_rounded, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              // Título + artista + tom
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (music != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        music!.artist,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
                      ),
                    ],
                    if (step.musicTone != null) ...[
                      const SizedBox(height: 4),
                      Chip(
                        label: Text(
                          'Tom: ${toneLabel(step.musicTone!)}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ],
                ),
              ),
              if (tappable)
                const Icon(Icons.chevron_right_rounded,
                    color: Colors.white24),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeopleReadTab extends StatelessWidget {
  const _PeopleReadTab({required this.event, required this.members});

  final EventModel event;
  final List<UserModel> members;

  String _resolveName(String userId) {
    try {
      return members.firstWhere((m) => m.id == userId).name;
    } catch (_) {
      return userId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final people = event.people;
    if (people.isEmpty) {
      return const Center(child: Text('Nenhum membro escalado'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: people.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                entry.key,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            ...entry.value.map((uid) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    child:
                        Icon(Icons.person_outline_rounded, size: 18),
                  ),
                  title: Text(_resolveName(uid)),
                )),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }
}
