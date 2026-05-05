import 'package:flutter/material.dart';

import '../../models/event_model.dart';
import '../../../musics/models/music_model.dart';
import 'music_selector_sheet.dart';

class StepEditorSheet extends StatefulWidget {
  const StepEditorSheet({
    super.key,
    required this.musics,
    this.initialStep,
  });

  final List<MusicModel> musics;
  final EventStepModel? initialStep;

  @override
  State<StepEditorSheet> createState() => _StepEditorSheetState();
}

class _StepEditorSheetState extends State<StepEditorSheet> {
  static const _tones = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
  ];

  final _formKey = GlobalKey<FormState>();
  late String _type;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  String? _selectedMusicId;
  String? _musicTone;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialStep;
    _type = initial?.type == EventStepType.music ? 'music' : 'step';
    _titleController = TextEditingController(text: initial?.title ?? '');
    _descriptionController =
        TextEditingController(text: initial?.description ?? '');
    _selectedMusicId = initial?.musicId;
    _musicTone = initial?.musicTone ?? _tones.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(
        bottom: bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                widget.initialStep == null ? 'Adicionar item' : 'Editar item',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _type,
                items: const [
                  DropdownMenuItem(value: 'step', child: Text('Etapa')),
                  DropdownMenuItem(value: 'music', child: Text('Música')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _type = value);
                },
                decoration: const InputDecoration(labelText: 'Tipo'),
              ),
              if (_type == 'music') ...[
                const SizedBox(height: 16),
                MusicSelectorField(
                  musics: widget.musics,
                  selectedId: _selectedMusicId,
                  onSelect: (music) {
                    setState(() {
                      _selectedMusicId = music.id;
                      _titleController.text = music.title;
                      _musicTone = music.tone;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _tones.contains(_musicTone) ? _musicTone : _tones.first,
                  items: _tones
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _musicTone = value);
                  },
                  decoration: const InputDecoration(labelText: 'Tom'),
                ),
              ] else ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    hintText: 'Título da etapa',
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Informe o título'
                          : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    hintText: 'Detalhes adicionais (opcional)',
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: const Text('Salvar'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    EventStepModel step;
    if (_type == 'music') {
      final musicId = _selectedMusicId;
      if (musicId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione uma música.')),
        );
        return;
      }
      step = EventStepModel(
        title: _titleController.text.trim(),
        type: EventStepType.music,
        musicId: musicId,
        musicTone: _musicTone ?? _tones.first,
      );
    } else {
      step = EventStepModel(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        type: EventStepType.step,
      );
    }
    Navigator.of(context).pop(step);
  }
}
