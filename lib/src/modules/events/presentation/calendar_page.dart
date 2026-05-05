import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../shared/state/app_state.dart';
import '../../../shared/utils/app_toast.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../societies/data/societies_repository.dart';
import '../../societies/models/society_model.dart';
import '../data/calendar_batch_repository.dart';
import '../data/events_repository.dart';
import '../models/calendar_batch_template_model.dart';
import '../models/calendar_event_model.dart';
import 'calendar_art_page.dart';
import 'calendar_batch_settings_page.dart';
import 'event_editor_page.dart';
import 'widgets/calendar_event_form_sheet.dart';

enum CalendarViewMode { day, month }

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key, this.hideHeader = false});

  final bool hideHeader;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarViewMode _viewMode = CalendarViewMode.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<String> _selectedCategories = [];
  List<CalendarEventModel> _events = [];
  List<SocietyModel> _societies = [];
  Map<String, Color> _categoryColors = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSocieties();
    _loadEvents();
  }

  Future<void> _loadSocieties() async {
    try {
      final societies = await context.read<SocietiesRepository>().fetchAll();
      final categoryColors = <String, Color>{};
      for (final s in societies) {
        categoryColors[s.name] = Color(s.color);
      }
      if (mounted) {
        setState(() {
          _societies = societies;
          _categoryColors = categoryColors;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadEvents() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final repo = context.read<EventsRepository>();
      final events = _selectedCategories.isEmpty
          ? await repo.fetchAllEventsForCalendar()
          : await repo.fetchCalendarEventsByCategories(_selectedCategories);
      if (mounted) setState(() => _events = events);
    } catch (e) {
      if (mounted) setState(() => _error = 'Erro ao carregar eventos: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<CalendarEventModel> _getEventsForDay(DateTime day) {
    final list = _events.where((e) => isSameDay(e.date, day)).toList();
    list.sort(CalendarEventModel.compareByDateAndTime);
    return list;
  }

  Widget _buildEventMarkers(List<CalendarEventModel> events) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: events.map((e) {
        final color = _categoryColors[e.category] ?? Theme.of(context).colorScheme.primary;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          width: 6,
          height: 6,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        );
      }).toList(),
    );
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() { _selectedDay = selectedDay; _focusedDay = focusedDay; });
  }

  void _onPageChanged(DateTime focusedDay) {
    final day = _selectedDay.day;
    final lastDay = DateTime(focusedDay.year, focusedDay.month + 1, 0).day;
    setState(() {
      _focusedDay = focusedDay;
      _selectedDay = DateTime(focusedDay.year, focusedDay.month, day <= lastDay ? day : lastDay);
    });
  }

  Future<void> _showAddEventDialog() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CalendarEventFormSheet(
        initialDate: _selectedDay,
        selectedCategory: _selectedCategories.isEmpty ? 'Geral' : _selectedCategories.first,
        eventsForDate: _getEventsForDay(_selectedDay),
      ),
    );
    if (result == true) await _loadEvents();
  }

  Future<void> _editEvent(CalendarEventModel event) async {
    if (event.sourceCollection == 'services') {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => EventEditorPage(eventId: event.id)),
      );
      await _loadEvents();
      return;
    }
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CalendarEventFormSheet(
        initialDate: event.date,
        selectedCategory: event.category,
        eventsForDate: _getEventsForDay(event.date),
        event: event,
      ),
    );
    if (result == true) await _loadEvents();
  }

  Future<void> _deleteEvent(CalendarEventModel event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir evento'),
        content: Text('Deseja realmente excluir "${event.name}"? Esta ação não poderá ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final repo = context.read<EventsRepository>();
      if (event.sourceCollection == 'services') {
        await repo.deleteEvent(event.id);
      } else {
        await repo.deleteCalendarEvent(event.id);
      }
      if (mounted) {
        showSuccessToast(context, 'Evento "${event.name}" excluído.');
        await _loadEvents();
      }
    } catch (_) {
      if (mounted) showErrorToast(context, 'Erro ao excluir evento. Tente novamente.');
    }
  }

  // ── Batch event creation ────────────────────────────────────────────────────

  /// Returns all dates in [month] that match the given [dayOfWeek] (1=Mon..7=Sun).
  List<DateTime> _getDatesForDayOfWeek(DateTime month, int dayOfWeek) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0);
    final dates = <DateTime>[];
    // dart weekday: 1=Mon…7=Sun — same as CalendarBatchTemplateModel.dayOfWeek
    int offset = dayOfWeek - start.weekday;
    if (offset < 0) offset += 7;
    var current = start.add(Duration(days: offset));
    while (!current.isAfter(end)) {
      dates.add(DateTime(current.year, current.month, current.day));
      current = current.add(const Duration(days: 7));
    }
    return dates;
  }

  /// Returns week number (1-based) of [date] among all occurrences of its weekday in [month].
  int _weekNumberInMonth(DateTime date, DateTime month) {
    final dates = _getDatesForDayOfWeek(month, date.weekday);
    final idx = dates.indexWhere((d) => d.day == date.day);
    return idx + 1; // 1-based
  }

  Future<void> _createAllMonthlyEvents(DateTime month) async {
    final batchRepo = context.read<CalendarBatchRepository>();
    final eventsRepo = context.read<EventsRepository>();

    final templates = await batchRepo.fetchAll();
    final activeTemplates = templates.where((t) => t.active).toList();

    if (activeTemplates.isEmpty) {
      if (mounted) showErrorToast(context, 'Nenhum template ativo configurado.');
      return;
    }

    int totalCreated = 0;
    int totalSkipped = 0;

    for (final template in activeTemplates) {
      final dates = _getDatesForDayOfWeek(month, template.dayOfWeek);
      for (final date in dates) {
        try {
          final weekNum = _weekNumberInMonth(date, month);
          // For week 5+, pick randomly from weeks 1-4
          final effectiveWeek = weekNum <= 4 ? weekNum : (Random().nextInt(4) + 1);
          final societyId = template.weekGroups[effectiveWeek];

          final event = await eventsRepo.createEvent(
            name: template.name,
            date: date,
            start: template.time,
            templateId: template.eventTemplateId,
          );
          if (societyId != null && societyId.isNotEmpty) {
            await eventsRepo.updateEvent(event.id, teams: {'group': societyId});
          }
          totalCreated++;
        } catch (_) {
          totalSkipped++;
        }
      }
    }

    if (mounted) {
      if (totalCreated > 0) {
        showSuccessToast(
          context,
          '$totalCreated evento(s) criado(s)${totalSkipped > 0 ? ' ($totalSkipped ignorado(s))' : ''}.',
        );
      } else {
        showErrorToast(context, 'Nenhum evento foi criado.');
      }
    }
  }

  Future<void> _showBatchEventCreator() async {
    // Validate templates exist before showing confirmation
    final batchRepo = context.read<CalendarBatchRepository>();
    List<CalendarBatchTemplateModel> templates;
    try {
      templates = await batchRepo.fetchAll();
    } catch (e) {
      if (mounted) showErrorToast(context, 'Erro ao verificar templates.');
      return;
    }

    final activeTemplates = templates.where((t) => t.active).toList();
    if (activeTemplates.isEmpty) {
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A1F2E),
            title: const Text('Nenhum template configurado'),
            content: const Text(
              'Para criar compromissos fixos para o mês, primeiro configure os templates de liturgia. '
              'Eles definem quais eventos repetem semanalmente e em qual grupo cada semana pertence.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Fechar'),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.settings_rounded, size: 18),
                label: const Text('Configurar templates'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CalendarBatchSettingsPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      }
      return;
    }

    final monthName = DateFormat('MMMM', 'pt_BR').format(_focusedDay);
    final capitalizedMonthName = monthName[0].toUpperCase() + monthName.substring(1);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        title: const Text('Criar compromissos fixos', style: TextStyle(color: Colors.white)),
        content: Text(
          'Criar ${activeTemplates.length} tipo(s) de evento para todos os dias correspondentes de $capitalizedMonthName?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Confirmar')),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          color: Color(0xFF1A1F2E),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Criando eventos...', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await Future.delayed(const Duration(milliseconds: 300));
      await _createAllMonthlyEvents(_focusedDay);
      await Future.delayed(const Duration(milliseconds: 1500));
    } catch (e) {
      if (mounted) showErrorToast(context, 'Erro ao criar eventos: ${e.toString()}');
    } finally {
      if (mounted) {
        Navigator.of(context).pop();
        await _loadEvents();
      }
    }
  }

  void _showAddEventMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1F2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.event, color: Colors.white70),
                  title: const Text('Novo Evento'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showAddEventDialog();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.event_note, color: Colors.white70),
                  title: const Text('Criar compromissos fixos para o mês'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showBatchEventCreator();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.image, color: Colors.white70),
                  title: const Text('Gerar arte do mês'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => CalendarArtPage(
                          initialMonth: _focusedDay,
                          initialCategories: _selectedCategories,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCategoryFilter() {
    final temp = List<String>.from(_selectedCategories);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
          decoration: const BoxDecoration(
            color: Color(0xFF1A1F2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Filtrar por Categoria',
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(color: Colors.white)),
              ),
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.4),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: 2 + _societies.length,
                    itemBuilder: (ctx, index) {
                      String category;
                      Color? color;
                      if (index == 0) {
                        category = 'Todos';
                      } else if (index == 1) {
                        category = 'Geral';
                        color = Theme.of(ctx).colorScheme.primary;
                      } else {
                        final s = _societies[index - 2];
                        category = s.name;
                        color = Color(s.color);
                      }

                      final isSelected = category == 'Todos'
                          ? temp.isEmpty
                          : temp.contains(category);
                      final hasAnySelection = temp.isNotEmpty;
                      final showColor = category != 'Todos' && (!hasAnySelection || isSelected);

                      return ListTile(
                        leading: category == 'Todos'
                            ? null
                            : Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: showColor ? color : Colors.transparent,
                                  border: Border.all(
                                    color: showColor ? (color ?? Colors.grey) : Colors.white38,
                                    width: 2,
                                  ),
                                ),
                              ),
                        title: Text(
                          category,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        trailing: category == 'Todos'
                            ? null
                            : Checkbox(
                                value: isSelected,
                                activeColor: Theme.of(ctx).colorScheme.primary,
                                onChanged: (v) {
                                  setModalState(() {
                                    if (v == true) {
                                      if (!temp.contains(category)) temp.add(category);
                                    } else {
                                      temp.remove(category);
                                    }
                                  });
                                },
                              ),
                        onTap: category == 'Todos'
                            ? null
                            : () {
                                setModalState(() {
                                  if (isSelected) {
                                    temp.remove(category);
                                  } else {
                                    if (!temp.contains(category)) temp.add(category);
                                  }
                                });
                              },
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  left: 16, right: 16, top: 16,
                  bottom: MediaQuery.of(ctx).padding.bottom + 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => setModalState(() => temp.clear()),
                      child: const Text('Limpar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        setState(() => _selectedCategories = List<String>.from(temp));
                        Navigator.of(ctx).pop();
                        _loadEvents();
                      },
                      child: const Text('Aplicar'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAdmin = context.watch<AppState>().currentUser?.isAdmin ?? false;

    final content = Column(
      children: [
        if (!widget.hideHeader)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: Colors.white,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Calendário',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Center(
            child: SegmentedButton<CalendarViewMode>(
              segments: const [
                ButtonSegment(value: CalendarViewMode.day, label: Text('Dia'), icon: SizedBox.shrink()),
                ButtonSegment(value: CalendarViewMode.month, label: Text('Mês'), icon: SizedBox.shrink()),
              ],
              selected: {_viewMode},
              onSelectionChanged: (s) => setState(() => _viewMode = s.first),
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                          const SizedBox(height: 16),
                          Text(_error!, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
                          const SizedBox(height: 16),
                          ElevatedButton(onPressed: _loadEvents, child: const Text('Tentar novamente')),
                        ],
                      ),
                    )
                  : LayoutBuilder(
                      builder: (ctx, constraints) {
                        if (_viewMode == CalendarViewMode.month) {
                          return Column(
                            children: [
                              Flexible(
                                fit: FlexFit.loose,
                                child: _buildMonthView(),
                              ),
                              Expanded(child: _buildEventList()),
                            ],
                          );
                        }
                        return _buildDayViewWithConstraints(constraints);
                      },
                    ),
        ),
      ],
    );

    if (widget.hideHeader) {
      return Stack(
        children: [
          content,
          Positioned(
            bottom: 200,
            right: 0,
            child: FloatingActionButton(
              heroTag: 'filter',
              onPressed: _showCategoryFilter,
              child: const Icon(Icons.filter_list),
            ),
          ),
          if (isAdmin)
            Positioned(
              bottom: 130,
              right: 0,
              child: FloatingActionButton(
                heroTag: 'add',
                onPressed: _viewMode == CalendarViewMode.month ? _showAddEventMenu : _showAddEventDialog,
                child: const Icon(Icons.add),
              ),
            ),
        ],
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D1220), Color(0xFF05070D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(child: content),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'filter',
            onPressed: _showCategoryFilter,
            child: const Icon(Icons.filter_list),
          ),
          if (isAdmin) ...[
            const SizedBox(height: 12),
            FloatingActionButton(
              heroTag: 'add',
              onPressed: _viewMode == CalendarViewMode.month ? _showAddEventMenu : _showAddEventDialog,
              child: const Icon(Icons.add),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthView() {
    return TableCalendar<CalendarEventModel>(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
      eventLoader: _getEventsForDay,
      startingDayOfWeek: StartingDayOfWeek.sunday,
      locale: 'pt_BR',
      rowHeight: 36,
      calendarBuilders: CalendarBuilders(
        markerBuilder: (_, date, events) {
          if (events.isEmpty) return null;
          return Positioned(bottom: 1, child: _buildEventMarkers(events));
        },
      ),
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        weekendTextStyle: const TextStyle(color: Colors.white70, fontSize: 12),
        defaultTextStyle: const TextStyle(color: Colors.white, fontSize: 12),
        cellMargin: EdgeInsets.zero,
        selectedDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
      ),
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
        rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
      ),
      daysOfWeekStyle: const DaysOfWeekStyle(
        weekdayStyle: TextStyle(color: Colors.white70),
        weekendStyle: TextStyle(color: Colors.white70),
      ),
      onDaySelected: _onDaySelected,
      onPageChanged: _onPageChanged,
    );
  }

  Widget _buildDayViewWithConstraints(BoxConstraints constraints) {
    final events = _getEventsForDay(_selectedDay);
    final dateFormat = DateFormat("EEEE, d 'de' MMMM 'de' y", 'pt_BR');
    const navigationHeight = 80.0;
    final availableHeight = constraints.maxHeight > 0 ? constraints.maxHeight - navigationHeight : null;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                onPressed: () => setState(() {
                  _selectedDay = _selectedDay.subtract(const Duration(days: 1));
                  _focusedDay = _selectedDay;
                }),
              ),
              Expanded(
                child: Text(
                  dateFormat.format(_selectedDay),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white),
                onPressed: () => setState(() {
                  _selectedDay = _selectedDay.add(const Duration(days: 1));
                  _focusedDay = _selectedDay;
                }),
              ),
            ],
          ),
        ),
        if (availableHeight != null && availableHeight > 0)
          SizedBox(height: availableHeight, child: _buildDayEventList(events))
        else
          Expanded(child: _buildDayEventList(events)),
      ],
    );
  }

  Widget _buildDayEventList(List<CalendarEventModel> events) {
    if (events.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadEvents,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            Padding(
              padding: EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_busy, size: 64, color: Colors.white38),
                  SizedBox(height: 16),
                  Text('Nenhum evento neste dia', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final isAdmin = context.read<AppState>().currentUser?.isAdmin ?? false;

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (ctx, index) {
        final event = events[index];
        final categoryColor = _categoryColors[event.category] ?? Theme.of(ctx).colorScheme.primary;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: categoryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.name,
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(event.category, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(event.start, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (isAdmin)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          color: Colors.white70,
                          onPressed: () => _editEvent(event),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          color: Colors.red,
                          onPressed: () => _deleteEvent(event),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
      ),
    );
  }

  Widget _buildEventList() {
    final events = _getEventsForDay(_selectedDay);
    if (events.isEmpty) return const SizedBox.shrink();

    final isAdmin = context.read<AppState>().currentUser?.isAdmin ?? false;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Eventos do dia ${DateFormat('dd/MM').format(_selectedDay)}',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: events.length,
              itemBuilder: (ctx, index) {
                final event = events[index];
                final categoryColor = _categoryColors[event.category] ?? Theme.of(ctx).colorScheme.primary;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(12),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            width: 4,
                            decoration: BoxDecoration(
                              color: categoryColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(event.name,
                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                Text(event.category,
                                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                const SizedBox(height: 2),
                                Text(event.start,
                                    style: const TextStyle(color: Colors.white70, fontSize: 11)),
                              ],
                            ),
                          ),
                          if (isAdmin)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18),
                                  color: Colors.white70,
                                  padding: EdgeInsets.zero,
                                  onPressed: () => _editEvent(event),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 18),
                                  color: Colors.red,
                                  padding: EdgeInsets.zero,
                                  onPressed: () => _deleteEvent(event),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
