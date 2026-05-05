import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/musics_repository.dart';
import '../../models/music_model.dart';
import '../../models/youtube_search_result.dart';
import '../../../../core/utils/app_exception.dart';

class MusicFormSheet extends StatefulWidget {
  const MusicFormSheet({super.key, this.music});
  final MusicModel? music;

  @override
  State<MusicFormSheet> createState() => _MusicFormSheetState();
}

class _MusicFormSheetState extends State<MusicFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final _titleCtrl = TextEditingController(text: widget.music?.title ?? '');
  late final _artistCtrl = TextEditingController(text: widget.music?.artist ?? '');
  late final _obsCtrl = TextEditingController(text: widget.music?.obs ?? '');
  late final _youtubeCtrl = TextEditingController(text: widget.music?.youtube ?? '');
  late final _cipherCtrl = TextEditingController(text: widget.music?.cipher ?? '');
  late final _lyricsCtrl = TextEditingController(text: widget.music?.lyrics ?? '');
  late final _bpmCtrl = TextEditingController(text: widget.music?.bpm ?? '');
  late final _searchCtrl = TextEditingController(
    text: widget.music == null ? '' : '${widget.music!.title} - ${widget.music!.artist}',
  );

  late String _tone = widget.music?.tone ?? 'C';
  late bool _minorTone = widget.music?.minorTone ?? false;

  bool _saving = false;
  bool _searchingYoutube = false;
  List<YoutubeSearchResult> _youtubeResults = const [];

  static const _tones = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _artistCtrl.dispose();
    _obsCtrl.dispose();
    _youtubeCtrl.dispose();
    _cipherCtrl.dispose();
    _lyricsCtrl.dispose();
    _bpmCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _paste(TextEditingController ctrl) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      ctrl.text = data.text!;
    }
  }

  Future<void> _searchYoutube() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _searchingYoutube = true;
      _youtubeResults = const [];
    });
    try {
      final results = await context.read<MusicsRepository>().searchYoutube(query);
      if (mounted) setState(() => _youtubeResults = results);
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _searchingYoutube = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = context.read<MusicsRepository>();
      final data = {
        'title': _titleCtrl.text.trim(),
        'artist': _artistCtrl.text.trim(),
        'obs': _obsCtrl.text.trim(),
        'youtube': _youtubeCtrl.text.trim(),
        'cipher': _cipherCtrl.text.trim(),
        'lyrics': _lyricsCtrl.text.trim(),
        'bpm': _bpmCtrl.text.trim(),
        'tone': _tone,
        'minorTone': _minorTone,
      };

      if (widget.music != null) {
        await repo.update(widget.music!.id, data);
      } else {
        await repo.create(
          title: data['title'] as String,
          artist: data['artist'] as String,
          tone: _tone,
          minorTone: _minorTone,
          category: widget.music?.category ?? '',
          cipher: data['cipher'] as String,
          obs: (data['obs'] as String).isEmpty ? null : data['obs'] as String,
          youtube: (data['youtube'] as String).isEmpty ? null : data['youtube'] as String,
          lyrics: (data['lyrics'] as String).isEmpty ? null : data['lyrics'] as String,
          bpm: (data['bpm'] as String).isEmpty ? null : data['bpm'] as String,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.8),
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboardHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.music != null ? 'Editar Música' : 'Nova Música',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Título
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Título *'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),

              // Artista
              TextFormField(
                controller: _artistCtrl,
                decoration: const InputDecoration(labelText: 'Artista *'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),

              // Tom + Menor
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _tone,
                      decoration: const InputDecoration(labelText: 'Tom'),
                      items: _tones
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) => setState(() => _tone = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      const Text('Menor'),
                      Switch(
                        value: _minorTone,
                        onChanged: (v) => setState(() => _minorTone = v),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // BPM
              TextFormField(
                controller: _bpmCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'BPM'),
              ),
              const SizedBox(height: 12),

              // Observação
              TextFormField(
                controller: _obsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Observações',
                  hintText: 'Notas adicionais sobre a música',
                ),
              ),
              const SizedBox(height: 20),

              // Seção YouTube
              Text('YouTube',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: Theme.of(context).colorScheme.primary)),
              const SizedBox(height: 8),
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  labelText: 'Buscar no YouTube',
                  suffixIcon: IconButton(
                    icon: _searchingYoutube
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                    onPressed: _searchingYoutube ? null : _searchYoutube,
                  ),
                ),
                onSubmitted: (_) => _searchYoutube(),
              ),
              if (_youtubeResults.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: ListView.separated(
                    itemCount: _youtubeResults.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final r = _youtubeResults[i];
                      return ListTile(
                        leading: const Icon(Icons.play_circle_outline_rounded),
                        title: Text(r.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                        onTap: () {
                          setState(() {
                            _youtubeCtrl.text =
                                'https://www.youtube.com/watch?v=${r.id}';
                            _youtubeResults = const [];
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 8),
              TextFormField(
                controller: _youtubeCtrl,
                decoration: InputDecoration(
                  labelText: 'URL do vídeo (YouTube)',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.paste_rounded),
                    tooltip: 'Colar do clipboard',
                    onPressed: () => _paste(_youtubeCtrl),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Cifra (URL)
              Text('Cifra',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: Theme.of(context).colorScheme.primary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _cipherCtrl,
                decoration: InputDecoration(
                  labelText: 'URL da cifra (Cifra Club)',
                  hintText: 'https://www.cifraclub.com.br/...',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.paste_rounded),
                    tooltip: 'Colar do clipboard',
                    onPressed: () => _paste(_cipherCtrl),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Letra (URL)
              Text('Letra',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: Theme.of(context).colorScheme.primary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _lyricsCtrl,
                decoration: InputDecoration(
                  labelText: 'URL da letra',
                  hintText: 'https://...',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.paste_rounded),
                    tooltip: 'Colar do clipboard',
                    onPressed: () => _paste(_lyricsCtrl),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Salvar'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    ),
  );
  }
}

