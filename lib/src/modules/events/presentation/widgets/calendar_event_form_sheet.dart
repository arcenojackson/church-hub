import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../shared/utils/app_toast.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../societies/data/societies_repository.dart';
import '../../../societies/models/society_model.dart';
import '../../data/events_repository.dart';
import '../../models/calendar_event_model.dart';

class CalendarEventFormSheet extends StatefulWidget {
  const CalendarEventFormSheet({
    super.key,
    required this.initialDate,
    required this.selectedCategory,
    this.eventsForDate = const [],
    this.event,
  });

  final DateTime initialDate;
  final String selectedCategory;
  final List<CalendarEventModel> eventsForDate;
  final CalendarEventModel? event;

  @override
  State<CalendarEventFormSheet> createState() => _CalendarEventFormSheetState();
}

class _CalendarEventFormSheetState extends State<CalendarEventFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController(text: '00:00');
  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _timeFormat = DateFormat('HH:mm');

  late DateTime _selectedDate;
  String _selectedCategory = 'Geral';
  bool _isSubmitting = false;
  List<CalendarEventModel> _eventsForDate = [];
  List<SocietyModel> _societies = [];
  bool _isLoadingSocieties = true;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    if (event != null) {
      _selectedDate = event.date;
      _selectedCategory = event.category;
      _nameController.text = event.name;
      _timeController.text = event.start;
      _dateController.text = _dateFormat.format(event.date);
    } else {
      _selectedDate = widget.initialDate;
      _selectedCategory =
          widget.selectedCategory.isEmpty ? 'Geral' : widget.selectedCategory;
      _dateController.text = _dateFormat.format(_selectedDate);
      _timeController.text = _timeFormat.format(_selectedDate);
    }
    _eventsForDate = widget.eventsForDate;
    _loadSocieties();
    _loadEventsForDate(_selectedDate);
  }

  Future<void> _loadSocieties() async {
    try {
      final societies = await context.read<SocietiesRepository>().fetchAll();
      if (mounted) {
        setState(() {
          _societies = societies;
          _isLoadingSocieties = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingSocieties = false);
    }
  }

  Future<void> _loadEventsForDate(DateTime date) async {
    try {
      final events =
          await context.read<EventsRepository>().fetchCalendarEventsByDate(date);
      if (mounted) setState(() => _eventsForDate = events);
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1F2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 24,
          right: 24,
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
                  widget.event == null ? 'Novo Evento' : 'Editar Evento',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Nome do evento',
                    labelStyle: TextStyle(color: Colors.white70),
                    hintStyle: TextStyle(color: Colors.white54),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Informe o nome' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Data',
                    labelStyle: TextStyle(color: Colors.white70),
                    suffixIcon:
                        Icon(Icons.calendar_today, color: Colors.white70),
                  ),
                  onTap: _isSubmitting ? null : _selectDate,
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _isSubmitting ? null : _selectTime,
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _timeController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Horário',
                        labelStyle: TextStyle(color: Colors.white70),
                        suffixIcon:
                            Icon(Icons.schedule, color: Colors.white70),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _isLoadingSocieties
                    ? const SizedBox(
                        height: 56,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _societies.isEmpty
                        ? TextFormField(
                            initialValue: _selectedCategory,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Categoria',
                              labelStyle: TextStyle(color: Colors.white70),
                            ),
                            onChanged: (v) => _selectedCategory = v,
                          )
                        : DropdownButtonFormField<String>(
                            // ignore: deprecated_member_use
                            value: _selectedCategory.isEmpty
                                ? 'Geral'
                                : _selectedCategory,
                            menuMaxHeight: 300,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Categoria',
                              labelStyle: TextStyle(color: Colors.white70),
                              suffixIcon:
                                  Icon(Icons.label, color: Colors.white70),
                            ),
                            dropdownColor: const Color(0xFF1A1F2E),
                            items: [
                              DropdownMenuItem<String>(
                                value: 'Geral',
                                child: Row(children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('Geral'),
                                ]),
                              ),
                              ..._societies.map((s) => DropdownMenuItem<String>(
                                    value: s.name,
                                    child: Row(children: [
                                      Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: Color(s.color),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(s.name),
                                    ]),
                                  )),
                            ],
                            onChanged: _isSubmitting
                                ? null
                                : (v) {
                                    if (v != null) {
                                      setState(() => _selectedCategory = v);
                                    }
                                  },
                          ),
                if (_eventsForDate.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Eventos já cadastrados para esta data:',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _eventsForDate.length,
                      itemBuilder: (_, i) {
                        final ev = _eventsForDate[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GlassContainer(
                            padding: const EdgeInsets.all(12),
                            child: Row(children: [
                              Icon(Icons.event,
                                  size: 16,
                                  color: theme.colorScheme.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(ev.name,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500)),
                                    Text(ev.category,
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12)),
                                    Text(ev.start,
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11)),
                                  ],
                                ),
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Salvar'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      final parts = _timeController.text.split(':');
      final h = parts.length == 2 ? int.tryParse(parts[0]) ?? 0 : 0;
      final m = parts.length == 2 ? int.tryParse(parts[1]) ?? 0 : 0;
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day, h, m);
        _dateController.text = _dateFormat.format(picked);
      });
      await _loadEventsForDate(picked);
    }
  }

  Future<void> _selectTime() async {
    final parts = _timeController.text.split(':');
    final h = parts.length == 2 ? int.tryParse(parts[0]) ?? 0 : 0;
    final m = parts.length == 2 ? int.tryParse(parts[1]) ?? 0 : 0;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: h, minute: m),
    );
    if (time != null) {
      final formatted =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      _timeController.text = formatted;
      setState(() {
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final parts = _timeController.text.split(':');
      final h = parts.length == 2 ? int.tryParse(parts[0]) ?? 0 : 0;
      final m = parts.length == 2 ? int.tryParse(parts[1]) ?? 0 : 0;
      final eventDate = DateTime(
          _selectedDate.year, _selectedDate.month, _selectedDate.day, h, m);
      final repo = context.read<EventsRepository>();

      if (widget.event != null) {
        await repo.updateCalendarEvent(
          id: widget.event!.id,
          name: _nameController.text.trim(),
          date: eventDate,
          category: _selectedCategory,
          start: _timeController.text.trim(),
        );
        if (mounted) {
          Navigator.of(context).pop(true);
          showSuccessToast(context, 'Evento atualizado com sucesso!');
        }
      } else {
        await repo.createCalendarEvent(
          name: _nameController.text.trim(),
          date: eventDate,
          category: _selectedCategory,
          start: _timeController.text.trim(),
        );
        if (_selectedCategory != 'Geral') {
          await repo.createEvent(
            name: _nameController.text.trim(),
            date: eventDate,
            start: _timeController.text.trim(),
          );
        }
        if (mounted) {
          Navigator.of(context).pop(true);
          final msg = _selectedCategory != 'Geral'
              ? 'Evento criado! Também adicionado ao Planejar.'
              : 'Evento criado com sucesso!';
          showSuccessToast(context, msg);
        }
      }
    } catch (_) {
      if (mounted) {
        showErrorToast(context, 'Erro ao salvar evento. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
