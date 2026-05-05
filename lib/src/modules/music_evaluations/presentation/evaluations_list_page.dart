import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/music_evaluations_repository.dart';
import '../models/evaluation_models.dart';
import '../../../shared/state/app_state.dart';
import 'evaluation_form_viewer_page.dart';

class EvaluationsListPage extends StatelessWidget {
  const EvaluationsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final churchId = appState.currentUser!.churchId!;
    final repo = MusicEvaluationsRepository(churchId: churchId);
    final isAdmin = appState.currentUser!.isAdmin;

    return StreamBuilder<List<EvaluationFormModel>>(
        stream: repo.watchForms(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final forms = snapshot.data ?? [];

          if (forms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_border_rounded, size: 56, color: Colors.white24),
                  const SizedBox(height: 16),
                  const Text('Nenhuma avaliação criada'),
                  if (isAdmin) ...[
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => _showCreateForm(context, repo),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Nova avaliação'),
                    ),
                  ],
                ],
              ),
            );
          }

          return Column(
            children: [
              if (isAdmin)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FilledButton.icon(
                        onPressed: () => _showCreateForm(context, repo),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Nova'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => Future.delayed(const Duration(milliseconds: 500)),
                  child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: forms.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final form = forms[i];
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          Icons.star_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(form.title),
                        subtitle: Text(form.musicTitle),
                        trailing: Chip(
                          label: Text(form.isOpen ? 'Aberta' : 'Fechada'),
                          backgroundColor: form.isOpen
                              ? Colors.green.withValues(alpha: 0.2)
                              : Colors.red.withValues(alpha: 0.2),
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EvaluationFormViewerPage(
                              form: form,
                              repo: repo,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  ),
                ),
              ),
            ],
          );
        },
    );
  }

  void _showCreateForm(BuildContext context, MusicEvaluationsRepository repo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CreateFormSheet(repo: repo),
    );
  }
}

class _CreateFormSheet extends StatefulWidget {
  const _CreateFormSheet({required this.repo});
  final MusicEvaluationsRepository repo;

  @override
  State<_CreateFormSheet> createState() => _CreateFormSheetState();
}

class _CreateFormSheetState extends State<_CreateFormSheet> {
  final _titleCtrl = TextEditingController();
  final _musicTitleCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _musicTitleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty || _musicTitleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.repo.createForm(
        title: _titleCtrl.text.trim(),
        musicId: '',
        musicTitle: _musicTitleCtrl.text.trim(),
        categoryId: 'default',
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24,
        top: 24,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Nova Avaliação',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 24),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Título da avaliação'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _musicTitleCtrl,
            decoration: const InputDecoration(labelText: 'Música'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Criar'),
          ),
        ],
      ),
    );
  }
}
