import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/firebase_config.dart';
import '../models/event_model.dart';
import '../models/chat_message_model.dart';
import '../../../shared/state/app_state.dart';

class EventChatPage extends StatefulWidget {
  const EventChatPage({super.key, required this.event});
  final EventModel event;

  @override
  State<EventChatPage> createState() => _EventChatPageState();
}

class _EventChatPageState extends State<EventChatPage> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  Stream<List<ChatMessageModel>> get _messages =>
      FirebaseConfig.firestore
          .collection('churches')
          .doc(widget.event.churchId)
          .collection('events')
          .doc(widget.event.id)
          .collection('messages')
          .orderBy('createdAt')
          .snapshots()
          .map((q) => q.docs.map(ChatMessageModel.fromFirestore).toList());

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    final user = context.read<AppState>().currentUser!;
    _msgCtrl.clear();

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
        ).toJson());
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<ChatMessageModel>>(
            stream: _messages,
            builder: (context, snapshot) {
              final msgs = snapshot.data ?? [];
              if (msgs.isEmpty) {
                return const Center(
                  child: Text('Nenhuma mensagem ainda'),
                );
              }
              return ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(16),
                itemCount: msgs.length,
                itemBuilder: (_, i) {
                  final msg = msgs[i];
                  final isMe =
                      msg.userId == context.read<AppState>().currentUser?.id;
                  return _MessageBubble(msg: msg, isMe: isMe);
                },
              );
            },
          ),
        ),
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
                  decoration: const InputDecoration(
                    hintText: 'Mensagem...',
                  ),
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
  const _MessageBubble({required this.msg, required this.isMe});
  final ChatMessageModel msg;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? Theme.of(context).colorScheme.primary
              : const Color(0xFF1B2435),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
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
            Text(msg.text),
          ],
        ),
      ),
    );
  }
}
