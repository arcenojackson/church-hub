import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/state/app_state.dart';
import '../../../shared/utils/app_toast.dart';
import '../data/calendar_batch_repository.dart';
import '../models/calendar_batch_template_model.dart';

class TemplateStepsPage extends StatefulWidget {
  const TemplateStepsPage({super.key, required this.template});

  final CalendarBatchTemplateModel template;

  @override
  State<TemplateStepsPage> createState() => _TemplateStepsPageState();
}

class _TemplateStepsPageState extends State<TemplateStepsPage> {
  static const _hardcodedDefaults = [
    {'title': 'Oração de abertura', 'type': 'step', 'duration': 5},
    {'title': 'Louvor', 'type': 'music', 'duration': 20},
    {'title': 'Leitura bíblica', 'type': 'step', 'duration': 5},
    {'title': 'Pregação', 'type': 'step', 'duration': 40},
    {'title': 'Avisos', 'type': 'step', 'duration': 5},
    {'title': 'Encerramento', 'type': 'step', 'duration': 5},
  ];

  late List<Map<String, dynamic>> _steps;
  bool _saving = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    if (widget.template.steps.isNotEmpty) {
      _steps = widget.template.steps.map((s) => Map<String, dynamic>.from(s)).toList();
    } else {
      final churchDefaults = context.read<AppState>().churchSettings?.defaultSteps;
      if (churchDefaults != null && churchDefaults.isNotEmpty) {
        _steps = churchDefaults.map((s) => Map<String, dynamic>.from(s)).toList();
      } else {
        _steps = _hardcodedDefaults.map((s) => Map<String, dynamic>.from(s)).toList();
      }
      _dirty = true;
    }
  }

  void _reorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    setState(() {
      final item = _steps.removeAt(oldIndex);
      _steps.insert(newIndex, item);
      _dirty = true;
    });
  }

  void _removeStep(int index) {
    setState(() {
      _steps.removeAt(index);
      _dirty = true;
    });
  }

  Future<void> _addOrEditStep({int? index}) async {
    final existing = index != null ? _steps[index] : null;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _StepFormSheet(step: existing),
    );
    if (result == null) return;
    setState(() {
      if (index != null) {
        _steps[index] = result;
      } else {
        _steps.add(result);
      }
      _dirty = true;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final repo = context.read<CalendarBatchRepository>();
      await repo.update(widget.template.copyWith(steps: _steps));
      if (mounted) {
        setState(() { _dirty = false; _saving = false; });
        showSuccessToast(context, 'Etapas salvas.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showErrorToast(context, 'Erro ao salvar etapas.');
      }
    }
  }

  int get _totalDuration =>
      _steps.fold(0, (sum, s) => sum + ((s['duration'] as int?) ?? 0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template.name),
        actions: [
          if (_dirty)
            _saving
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : TextButton(
                    onPressed: _save,
                    child: const Text('Salvar'),
                  ),
        ],
      ),
      body: Column(
        children: [
          if (_steps.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 16, color: Colors.white38),
                  const SizedBox(width: 6),
                  Text(
                    'Duração total: $_totalDuration min',
                    style: const TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _steps.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.list_alt_rounded, size: 56, color: Colors.white24),
                        const SizedBox(height: 16),
                        const Text(
                          'Nenhuma etapa configurada',
                          style: TextStyle(color: Colors.white54),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () => _addOrEditStep(),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Adicionar etapa'),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _steps.length,
                    onReorder: _reorder,
                    itemBuilder: (context, i) {
                      final step = _steps[i];
                      final isMusic = step['type'] == 'music';
                      return ListTile(
                        key: ValueKey('step_$i'),
                        leading: ReorderableDragStartListener(
                          index: i,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              isMusic
                                  ? Icons.music_note_rounded
                                  : Icons.format_list_bulleted_rounded,
                              color: isMusic
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.white38,
                              size: 22,
                            ),
                          ),
                        ),
                        title: Text(step['title'] as String? ?? ''),
                        subtitle: Text(
                          '${step['duration'] ?? 0} min · ${isMusic ? 'Música' : 'Etapa'}',
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              color: Colors.white38,
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _addOrEditStep(index: i),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline_rounded, size: 18),
                              color: Colors.red[300],
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _removeStep(i),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _steps.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _addOrEditStep(),
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }
}

class _StepFormSheet extends StatefulWidget {
  const _StepFormSheet({this.step});
  final Map<String, dynamic>? step;

  @override
  State<_StepFormSheet> createState() => _StepFormSheetState();
}

class _StepFormSheetState extends State<_StepFormSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _durationCtrl;
  late String _type;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.step?['title']?.toString() ?? '');
    _durationCtrl = TextEditingController(
        text: (widget.step?['duration'] ?? 10).toString());
    _type = widget.step?['type']?.toString() ?? 'step';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  bool get _valid => _titleCtrl.text.trim().isNotEmpty;

  Map<String, dynamic> _buildResult() => {
        'title': _titleCtrl.text.trim(),
        'type': _type,
        'duration': int.tryParse(_durationCtrl.text.trim()) ?? 10,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1F2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                widget.step == null ? 'Nova etapa' : 'Editar etapa',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _titleCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Título *',
                  hintText: 'Ex: Oração de abertura',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _durationCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Duração (min)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'step',
                        icon: Icon(Icons.format_list_bulleted_rounded, size: 18),
                        label: Text('Etapa'),
                      ),
                      ButtonSegment(
                        value: 'music',
                        icon: Icon(Icons.music_note_rounded, size: 18),
                        label: Text('Música'),
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: (s) => setState(() => _type = s.first),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton(
                onPressed: _valid
                    ? () => Navigator.of(context).pop(_buildResult())
                    : null,
                child: Text(widget.step == null ? 'Adicionar' : 'Salvar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
