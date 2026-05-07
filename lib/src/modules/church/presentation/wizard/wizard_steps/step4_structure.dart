import 'package:flutter/material.dart';

import '../onboarding_wizard_page.dart';

class WizardStep4Structure extends StatefulWidget {
  const WizardStep4Structure({super.key, required this.data, required this.onNext});

  final OnboardingWizardData data;
  final VoidCallback onNext;

  @override
  State<WizardStep4Structure> createState() => _WizardStep4StructureState();
}

class _WizardStep4StructureState extends State<WizardStep4Structure> {
  late final List<Map<String, dynamic>> _steps = List.from(
    widget.data.defaultSteps.isNotEmpty
        ? widget.data.defaultSteps
        : _defaultSteps,
  );

  final _titleCtrl = TextEditingController();

  static const _defaultSteps = [
    {'title': 'Oração de abertura', 'type': 'step', 'duration': 5},
    {'title': 'Louvor', 'type': 'music', 'duration': 20},
    {'title': 'Leitura bíblica', 'type': 'step', 'duration': 5},
    {'title': 'Pregação', 'type': 'step', 'duration': 40},
    {'title': 'Avisos', 'type': 'step', 'duration': 5},
    {'title': 'Encerramento', 'type': 'step', 'duration': 5},
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  void _addStep() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    setState(() {
      _steps.add({'title': title, 'type': 'step', 'duration': 10});
      _titleCtrl.clear();
    });
  }

  void _removeStep(int index) {
    setState(() => _steps.removeAt(index));
  }

  void _reorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    setState(() {
      final item = _steps.removeAt(oldIndex);
      _steps.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Estrutura do Culto',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Defina a sequência padrão dos seus cultos. Você pode reordenar arrastando.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white60,
                  ),
                ),
                const SizedBox(height: 24),
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _steps.length,
                  onReorder: _reorder,
                  itemBuilder: (context, i) {
                    final step = _steps[i];
                    return ListTile(
                      key: ValueKey('step_$i'),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                      leading: ReorderableDragStartListener(
                        index: i,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(Icons.drag_handle_rounded, color: Colors.white38),
                        ),
                      ),
                      title: Text(step['title'] as String),
                      subtitle: Text(
                        '${step['duration']} min · ${step['type'] == 'music' ? 'Música' : 'Passo'}',
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                        onPressed: () => _removeStep(i),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Novo passo',
                          hintText: 'Ex: Santa Ceia',
                        ),
                        onSubmitted: (_) => _addStep(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filled(
                      onPressed: _addStep,
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: FilledButton(
            onPressed: () {
              widget.data.defaultSteps = _steps;
              widget.onNext();
            },
            child: const Text('Próximo'),
          ),
        ),
      ],
    );
  }
}
