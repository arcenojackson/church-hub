import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/firebase_config.dart';
import '../../auth/models/user_model.dart';
import '../../people/data/people_repository.dart';
import '../models/event_model.dart';
import '../models/chat_message_model.dart';
import '../../../shared/state/app_state.dart';

class EventChatPage extends StatefulWidget {
  const EventChatPage({
    super.key,
    required this.event,
    this.onOpened,
  });

  final EventModel event;

  /// Called when the chat becomes visible so the caller can mark it as read.
  final VoidCallback? onOpened;

  @override
  State<EventChatPage> createState() => _EventChatPageState();
}

class _EventChatPageState extends State<EventChatPage> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();

  List<UserModel> _members = const [];
  String? _mentionQuery;
  final List<String> _pendingMentionIds = [];

  Stream<List<ChatMessageModel>> get _messages => FirebaseConfig.firestore
      .collection('churches')
      .doc(widget.event.churchId)
      .collection('events')
      .doc(widget.event.id)
      .collection('messages')
      .orderBy('createdAt')
      .snapshots()
      .map((q) => q.docs.map(ChatMessageModel.fromFirestore).toList());

  @override
  void initState() {
    super.initState();
    widget.onOpened?.call();
    _loadMembers();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    try {
      final members = await context.read<PeopleRepository>().fetchMembers();
      if (mounted) setState(() => _members = members);
    } catch (_) {}
  }

  // null entry = @todos
  List<UserModel?> get _suggestions {
    final q = (_mentionQuery ?? '').toLowerCase();
    return [
      if ('todos'.contains(q)) null,
      ..._members.where((m) => m.name.toLowerCase().contains(q)),
    ];
  }

  void _onChanged(String text) {
    // Use full text up to the current cursor position
    final cursor = _msgCtrl.selection.baseOffset;
    if (cursor < 0) {
      if (_mentionQuery != null) setState(() => _mentionQuery = null);
      return;
    }
    final before = text.substring(0, cursor.clamp(0, text.length));
    final match = RegExp(r'@([^\s@]*)$').firstMatch(before);
    final query = match?.group(1)?.toLowerCase();
    if (query != _mentionQuery) setState(() => _mentionQuery = query);
  }

  void _insertMention(UserModel? member) {
    final text = _msgCtrl.text;
    final cursor = _msgCtrl.selection.baseOffset.clamp(0, text.length);
    final before = text.substring(0, cursor);
    final after = text.substring(cursor);
    final match = RegExp(r'@([^\s@]*)$').firstMatch(before);
    if (match == null) return;

    final name = member?.name ?? 'todos';
    final newBefore = '${before.substring(0, match.start)}@$name ';
    _msgCtrl.value = TextEditingValue(
      text: newBefore + after,
      selection: TextSelection.collapsed(offset: newBefore.length),
    );

    if (member != null) {
      if (!_pendingMentionIds.contains(member.id)) _pendingMentionIds.add(member.id);
    } else {
      _pendingMentionIds
        ..clear()
        ..addAll(_members.map((m) => m.id));
    }
    setState(() => _mentionQuery = null);
    _focusNode.requestFocus();
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    final user = context.read<AppState>().currentUser!;

    final ids = List<String>.of(_pendingMentionIds);
    if (text.contains('@todos')) {
      ids
        ..clear()
        ..addAll(_members.map((m) => m.id));
    } else {
      for (final m in _members) {
        if (text.contains('@${m.name}') && !ids.contains(m.id)) ids.add(m.id);
      }
    }

    _msgCtrl.clear();
    _pendingMentionIds.clear();
    setState(() => _mentionQuery = null);

    await FirebaseConfig.firestore
        .collection('churches')
        .doc(widget.event.churchId)
        .collection('events')
        .doc(widget.event.id)
        .collection('messages')
        .add(ChatMessageModel(
          id: '',
          text: text,
          userId: user.id,
          userName: user.name,
          createdAt: DateTime.now(),
          mentionedUserIds: ids,
        ).toJson());
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.read<AppState>().currentUser?.id ?? '';
    final suggestions = _mentionQuery != null ? _suggestions : <UserModel?>[];

    return Column(
      children: [
        // Messages list
        Expanded(
          child: StreamBuilder<List<ChatMessageModel>>(
            stream: _messages,
            builder: (context, snapshot) {
              final msgs = snapshot.data ?? [];
              if (msgs.isEmpty) {
                return const Center(child: Text('Nenhuma mensagem ainda'));
              }
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollCtrl.hasClients) {
                  _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
                }
              });
              return ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(16),
                itemCount: msgs.length,
                itemBuilder: (_, i) => _MessageBubble(
                  msg: msgs[i],
                  isMe: msgs[i].userId == myId,
                  members: _members,
                  myId: myId,
                ),
              );
            },
          ),
        ),

        // Mention suggestions panel
        if (suggestions.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: const Color(0xFF1B2435),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: suggestions.length,
              itemBuilder: (_, i) {
                final member = suggestions[i];
                final name = member?.name ?? 'todos';
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor:
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    child: Text(
                      name[0].toUpperCase(),
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                  title: Text('@$name',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: member == null
                      ? const Text('Mencionar todos',
                          style: TextStyle(fontSize: 11))
                      : null,
                  onTap: () => _insertMention(member),
                );
              },
            ),
          ),

        // Input row
        Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
            top: 8,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  focusNode: _focusNode,
                  decoration: const InputDecoration(hintText: 'Mensagem...'),
                  onChanged: _onChanged,
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _send,
                icon: const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.msg,
    required this.isMe,
    required this.members,
    required this.myId,
  });

  final ChatMessageModel msg;
  final bool isMe;
  final List<UserModel> members;
  final String myId;

  bool get _mentionsMe => msg.mentionedUserIds.contains(myId);

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final highlighted = _mentionsMe && !isMe;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? primary : const Color(0xFF1B2435),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          border: highlighted
              ? Border.all(color: primary.withValues(alpha: 0.7), width: 1.5)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                msg.userName,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                ),
              ),
            _buildText(primary),
          ],
        ),
      ),
    );
  }

  Widget _buildText(Color primary) {
    final text = msg.text;
    final validNames = {'todos', ...members.map((m) => m.name)};
    final spans = <TextSpan>[];
    int lastEnd = 0;

    for (final match in RegExp(r'@([^\s]+)').allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      final word = match.group(1)!;
      final isMention =
          validNames.any((n) => n.toLowerCase() == word.toLowerCase());
      spans.add(TextSpan(
        text: match.group(0),
        style: isMention
            ? TextStyle(
                fontWeight: FontWeight.w700,
                color: isMe ? Colors.white : primary,
                backgroundColor: isMe
                    ? Colors.white.withValues(alpha: 0.2)
                    : primary.withValues(alpha: 0.15),
              )
            : null,
      ));
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    if (spans.length == 1 && spans.first.style == null) return Text(text);

    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.white, fontSize: 14),
        children: spans,
      ),
    );
  }
}
