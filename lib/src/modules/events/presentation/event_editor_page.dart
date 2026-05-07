import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/app_exception.dart';
import '../../../shared/utils/app_toast.dart';
import '../../societies/data/societies_repository.dart';
import '../../societies/models/society_model.dart';
import '../data/calendar_batch_repository.dart';
import '../data/events_repository.dart';
import '../models/calendar_batch_template_model.dart';
import '../models/event_model.dart';

class EventEditorPage extends StatefulWidget {
  const EventEditorPage({super.key, this.eventId});
  final String? eventId;

  @override
  State<EventEditorPage> createState() => _EventEditorPageState();
}

class _EventEditorPageState extends State<EventEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;
  String? _selectedSocietyId = 'Geral';
  List<SocietyModel> _societies = const [];
  List<CalendarBatchTemplateModel> _templates = const [];
  CalendarBatchTemplateModel? _selectedTemplate;
  bool _loading = false;
  bool _loadingSocieties = true;
  EventModel? _event;

  bool get _isEditing => widget.eventId != null;

  @override
  void initState() {
    super.initState();
    _loadSocieties();
    if (_isEditing) {
      _loadEvent();
    } else {
      _loadTemplates();
    }
  }

  Future<void> _loadSocieties() async {
    try {
      final societies =
          await context.read<SocietiesRepository>().fetchAll();
      if (mounted) {
        setState(() {
          _societies = societies;
          _loadingSocieties = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSocieties = false);
    }
  }

  Future<void> _loadTemplates() async {
    try {
      final templates = await context.read<CalendarBatchRepository>().fetchAll();
      if (mounted) setState(() => _templates = templates.where((t) => t.active).toList());
    } catch (_) {}
  }

  Future<void> _loadEvent() async {
    setState(() => _loading = true);
    try {
      final repo = context.read<EventsRepository>();
      _event = await repo.fetchById(widget.eventId!);
      if (_event != null) {
        _nameCtrl.text = _event!.name;
        _selectedDate = _event!.date;
        _selectedSocietyId = _event!.societyId ?? 'Geral';
        final start = _event!.start;
        if (start.isNotEmpty) {
          final parts = start.split(':');
          if (parts.length == 2) {
            final h = int.tryParse(parts[0]);
            final m = int.tryParse(parts[1]);
            if (h != null && m != null) {
              _selectedTime = TimeOfDay(hour: h, minute: m);
            }
          }
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  String get _startString {
    final t = _selectedTime;
    if (t == null) return '';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final repo = context.read<EventsRepository>();
      if (_isEditing) {
        await repo.updateEvent(
          widget.eventId!,
          name: _nameCtrl.text.trim(),
          date: _selectedDate,
          start: _startString,
          societyId: _selectedSocietyId,
        );
      } else {
        final steps = _selectedTemplate?.steps
            .map((s) => EventStepModel.fromJson(s))
            .toList();
        await repo.createEvent(
          name: _nameCtrl.text.trim(),
          date: _selectedDate,
          start: _startString,
          societyId: _selectedSocietyId,
          templateId: _selectedTemplate?.id,
          steps: steps,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } on AppException catch (e) {
      if (mounted) {
        showErrorToast(context, e.message);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDataLoading = _loading && _isEditing;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Evento' : 'Novo Evento'),
      ),
      body: isDataLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nome do evento',
                      prefixIcon: Icon(Icons.event_rounded),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Data',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(
                        DateFormat('dd/MM/yyyy', 'pt_BR').format(_selectedDate),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _pickTime,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Horário',
                        prefixIcon: Icon(Icons.access_time_outlined),
                      ),
                      child: Text(
                        _selectedTime == null
                            ? 'Selecionar horário'
                            : _startString,
                        style: _selectedTime == null
                            ? const TextStyle(color: Colors.white38)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSocietyDropdown(),
                  if (!_isEditing && _templates.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildTemplateSelector(),
                  ],
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _loading ? null : _save,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_isEditing ? 'Salvar' : 'Criar evento'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTemplateSelector() {
    final items = <DropdownMenuItem<CalendarBatchTemplateModel?>>[
      const DropdownMenuItem(
        value: null,
        child: Text('Sem template', style: TextStyle(color: Colors.white54)),
      ),
      ..._templates.map((t) {
        final stepsLabel = t.steps.isEmpty ? '' : ' · ${t.steps.length} etapas';
        return DropdownMenuItem(
          value: t,
          child: Text('${t.name}$stepsLabel'),
        );
      }),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<CalendarBatchTemplateModel?>(
          // ignore: deprecated_member_use
          value: _selectedTemplate,
          menuMaxHeight: 300,
          items: items,
          onChanged: (v) => setState(() => _selectedTemplate = v),
          decoration: const InputDecoration(
            labelText: 'Template de liturgia',
            prefixIcon: Icon(Icons.format_list_bulleted_rounded),
          ),
        ),
        if (_selectedTemplate != null && _selectedTemplate!.steps.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              '${_selectedTemplate!.steps.length} etapas serão adicionadas ao evento',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSocietyDropdown() {
    if (_loadingSocieties) {
      return const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_societies.isEmpty) {
      return const SizedBox.shrink();
    }

    final items = <DropdownMenuItem<String?>>[
      DropdownMenuItem(
        value: 'Geral',
        child: Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Geral'),
          ],
        ),
      ),
      ..._societies.map(
        (s) => DropdownMenuItem(
          value: s.id,
          child: Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Color(s.color),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(s.name),
            ],
          ),
        ),
      ),
    ];

    return DropdownButtonFormField<String?>(
      initialValue: _selectedSocietyId,
      menuMaxHeight: 300,
      items: items,
      onChanged: (v) => setState(() => _selectedSocietyId = v),
      decoration: const InputDecoration(
        labelText: 'Grupo',
        prefixIcon: Icon(Icons.groups_outlined),
      ),
    );
  }
}
