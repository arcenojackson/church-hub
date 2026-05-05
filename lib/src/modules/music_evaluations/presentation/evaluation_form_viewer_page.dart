import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/music_evaluations_repository.dart';
import '../models/evaluation_models.dart';
import '../../../shared/state/app_state.dart';

class EvaluationFormViewerPage extends StatefulWidget {
  const EvaluationFormViewerPage({
    super.key,
    required this.form,
    required this.repo,
  });

  final EvaluationFormModel form;
  final MusicEvaluationsRepository repo;

  @override
  State<EvaluationFormViewerPage> createState() =>
      _EvaluationFormViewerPageState();
}

class _EvaluationFormViewerPageState extends State<EvaluationFormViewerPage> {
  final Map<String, int> _ratings = {};
  final _commentCtrl = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;

  static const _criteria = [
    {'id': 'theological', 'label': 'Coerência Teológica'},
    {'id': 'congregational', 'label': 'Coerência Congregacional'},
    {'id': 'musical', 'label': 'Qualidade Musical'},
  ];

  @override
  void initState() {
    super.initState();
    for (final c in _criteria) {
      _ratings[c['id']!] = 3;
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = context.read<AppState>().currentUser!;
    setState(() => _submitting = true);
    try {
      await widget.repo.submitResponse(
        formId: widget.form.id,
        userId: user.id,
        userName: user.name,
        ratings: _ratings,
        comment: _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
      );
      if (mounted) setState(() => _submitted = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.form.musicTitle)),
      body: _submitted
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text('Avaliação enviada!'),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  widget.form.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.form.musicTitle,
                  style: const TextStyle(color: Colors.white60),
                ),
                const SizedBox(height: 32),
                ..._criteria.map((c) => _RatingRow(
                  label: c['label']!,
                  value: _ratings[c['id']!] ?? 3,
                  onChanged: (v) => setState(() => _ratings[c['id']!] = v),
                )),
                const SizedBox(height: 24),
                TextField(
                  controller: _commentCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Comentário (opcional)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 32),
                if (widget.form.isOpen)
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Enviar Avaliação'),
                  )
                else
                  const Center(
                    child: Text(
                      'Esta avaliação está fechada',
                      style: TextStyle(color: Colors.white38),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(5, (i) {
              final starValue = i + 1;
              return GestureDetector(
                onTap: () => onChanged(starValue),
                child: Icon(
                  starValue <= value ? Icons.star_rounded : Icons.star_border_rounded,
                  color: starValue <= value ? primary : Colors.white24,
                  size: 36,
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Fraco', style: TextStyle(color: Colors.white38, fontSize: 11)),
              Text('Excelente', style: TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
