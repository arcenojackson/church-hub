import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/music_model.dart';
import '../../../shared/state/app_state.dart';
import '../../../shared/utils/tone_utils.dart';
import 'widgets/music_form_sheet.dart';

class MusicDetailPage extends StatefulWidget {
  const MusicDetailPage({
    super.key,
    required this.music,
    this.overrideTone,
    this.showEdit = true,
  });
  final MusicModel music;
  final String? overrideTone;
  final bool showEdit;

  @override
  State<MusicDetailPage> createState() => _MusicDetailPageState();
}

class _MusicDetailPageState extends State<MusicDetailPage> {
  WebViewController? _webViewController;
  String? _embedUrl;

  // Ordenação usada pelo site de cifras: A=0, A#=1, B=2, C=3, C#=4, D=5, D#=6, E=7, F=8, F#=9, G=10, G#=11
  static const _tones = ['A', 'A#', 'B', 'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#'];

  @override
  void initState() {
    super.initState();
    _initYoutubePlayer();
  }

  void _initYoutubePlayer() {
    final youtubeUrl = widget.music.youtube;
    if (youtubeUrl == null || youtubeUrl.isEmpty) return;

    final videoId = _extractVideoId(youtubeUrl);
    if (videoId == null || videoId.isEmpty) return;

    final embedUrl = Uri.parse(
      'https://www.youtube-nocookie.com/embed/$videoId',
    ).replace(queryParameters: {
      'rel': '0',
      'origin': 'https://www.youtube-nocookie.com',
    }).toString();

    final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="Content-Security-Policy" content="frame-src https://www.youtube-nocookie.com https://www.youtube.com https://youtube.com;">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { width: 100%; height: 100%; background-color: #000; overflow: hidden; }
    iframe { position: absolute; top: 0; left: 0; width: 100%; height: 100%; border: none; }
  </style>
</head>
<body>
  <iframe
    src="$embedUrl"
    frameborder="0"
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
    allowfullscreen
    loading="lazy"
  ></iframe>
</body>
</html>''';

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..enableZoom(false)
      ..setNavigationDelegate(NavigationDelegate())
      ..loadHtmlString(html, baseUrl: 'https://www.youtube-nocookie.com');

    _embedUrl = embedUrl;
  }

  String? _extractVideoId(String url) {
    url = url.trim();
    final patterns = [
      RegExp(r'(?:youtube\.com|youtu\.be)/embed/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com/watch\?v=([a-zA-Z0-9_-]{11})'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(url);
      if (m != null) return m.group(1);
    }
    return Uri.tryParse(url)?.queryParameters['v'];
  }

  String? _computeCipherUrl() {
    final cipher = widget.music.cipher;
    if (cipher.isEmpty) return null;
    final tone = widget.overrideTone ?? widget.music.tone;
    final index = _tones.indexOf(tone);
    final key = index >= 0 ? index : 0;
    return '$cipher#key=$key&tabs=false';
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.read<AppState>().currentUser?.isAdmin ?? false;
    final music = widget.music;
    final cipherUrl = _computeCipherUrl();
    final primary = Theme.of(context).colorScheme.primary;

    final displayTone = widget.overrideTone != null
        ? toneLabel(widget.overrideTone!)
        : music.displayTone;

    return Scaffold(
      appBar: AppBar(
        title: Text(music.title),
        actions: [
          if (isAdmin && widget.showEdit)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => MusicFormSheet(music: music),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Info rows
          _InfoRow(label: 'Artista', value: music.artist),
          _InfoRow(label: 'Tom', value: displayTone),
          if (music.bpm != null && music.bpm!.isNotEmpty)
            _InfoRow(label: 'BPM', value: music.bpm!),
          if (music.tempo != null && music.tempo!.isNotEmpty)
            _InfoRow(label: 'Andamento', value: music.tempo!),
          if (music.category.isNotEmpty)
            _InfoRow(label: 'Categoria', value: music.category),
          if (music.obs != null && music.obs!.isNotEmpty)
            _InfoRow(label: 'Observações', value: music.obs!),

          const SizedBox(height: 24),

          // YouTube player
          if (_webViewController != null && _embedUrl != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: WebViewWidget(controller: _webViewController!),
              ),
            )
          else if (music.youtube != null && music.youtube!.isNotEmpty)
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 40, color: Colors.grey[600]),
                  const SizedBox(height: 8),
                  Text('Erro ao carregar vídeo',
                      style: TextStyle(color: Colors.grey[400])),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _launchUrl(music.youtube!),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Abrir no YouTube'),
                  ),
                ],
              ),
            )
          else
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.videocam_off_outlined, size: 40, color: Colors.grey[600]),
                  const SizedBox(height: 8),
                  Text('Nenhum vídeo disponível',
                      style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // Botões de ação
          FilledButton.icon(
            onPressed: cipherUrl == null ? null : () => _launchUrl(cipherUrl),
            icon: const Icon(Icons.library_music_outlined),
            label: const Text('Ver cifra'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: (music.lyrics == null || music.lyrics!.isEmpty)
                ? null
                : () => _launchUrl(music.lyrics!),
            icon: const Icon(Icons.article_outlined),
            label: const Text('Ver letra'),
            style: FilledButton.styleFrom(
              backgroundColor: primary.withValues(alpha: 0.15),
              foregroundColor: primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(color: Colors.white38, fontSize: 13)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
