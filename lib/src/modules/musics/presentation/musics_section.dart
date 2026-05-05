import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/musics_repository.dart';
import '../models/music_model.dart';
import '../../../shared/widgets/swipe_hint_wrapper.dart';
import 'music_detail_page.dart';
import 'widgets/music_form_sheet.dart';

class MusicsSection extends StatefulWidget {
  const MusicsSection({super.key, required this.canEdit});
  final bool canEdit;

  @override
  State<MusicsSection> createState() => _MusicsSectionState();
}

class _MusicsSectionState extends State<MusicsSection> {
  String _search = '';

  Future<void> _confirmDelete(
      BuildContext context, MusicsRepository repo, String id, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir música'),
        content: Text('Deseja excluir "$title"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('Excluir',
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error))),
        ],
      ),
    );
    if (confirmed == true) await repo.delete(id);
  }

  Widget _buildCard(
      BuildContext context, MusicModel music, MusicsRepository repo) {
    final color = Theme.of(context).colorScheme.primary;
    return Card(
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => MusicDetailPage(music: music)),
        ),
        borderRadius: BorderRadius.circular(18),
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
                child: Center(
                  child: Text(
                    music.displayTone,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(music.title,
                        style:
                            const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(music.artist,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 13)),
                  ],
                ),
              ),
              if (widget.canEdit)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  color: Colors.white38,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => MusicFormSheet(music: music),
                  ),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: Colors.white24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<MusicsRepository>();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Buscar música...',
                  prefixIcon: Icon(Icons.search_rounded),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            if (widget.canEdit) ...[
              const SizedBox(width: 12),
              IconButton.filled(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const MusicFormSheet(),
                ),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<List<MusicModel>>(
            stream: repo.watchAll(),
            builder: (context, snapshot) {
              final all = snapshot.data ?? [];
              final filtered = _search.isEmpty
                  ? all
                  : all
                      .where((m) =>
                          m.title
                              .toLowerCase()
                              .contains(_search.toLowerCase()) ||
                          m.artist
                              .toLowerCase()
                              .contains(_search.toLowerCase()))
                      .toList();

              if (filtered.isEmpty) {
                return const Center(child: Text('Nenhuma música encontrada'));
              }

              return RefreshIndicator(
                onRefresh: () =>
                    Future.delayed(const Duration(milliseconds: 500)),
                child: ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final music = filtered[i];
                    final card = _buildCard(context, music, repo);
                    final child = i == 0 && widget.canEdit
                        ? SwipeHintWrapper(screenKey: 'musics', child: card)
                        : card;
                    return Dismissible(
                      key: ValueKey(music.id),
                      direction: widget.canEdit
                          ? DismissDirection.endToStart
                          : DismissDirection.none,
                      confirmDismiss: (_) =>
                          _confirmDelete(context, repo, music.id, music.title)
                              .then((_) => false),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade700,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.delete_outline_rounded,
                            color: Colors.white),
                      ),
                      child: child,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
