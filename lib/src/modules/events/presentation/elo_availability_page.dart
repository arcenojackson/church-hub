import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../data/availability_repository.dart';
import '../../../shared/state/app_state.dart';
import '../../../shared/utils/app_toast.dart';

class EloAvailabilityPage extends StatefulWidget {
  const EloAvailabilityPage({super.key});

  @override
  State<EloAvailabilityPage> createState() => _EloAvailabilityPageState();
}

class _EloAvailabilityPageState extends State<EloAvailabilityPage> {
  late DateTime _focusedMonth;
  late List<DateTime> _myDates;
  bool _loading = true;
  bool _saving = false;

  late AvailabilityRepository _repo;
  late String _userId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Show next month by default
    _focusedMonth = DateTime(now.year, now.month + 1, 1);
    _myDates = [];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = context.read<AppState>();
    _userId = appState.currentUser!.id;
    final churchId = appState.currentUser!.churchId!;
    _repo = AvailabilityRepository(churchId: churchId);
    _loadMyDates();
  }

  Future<void> _loadMyDates() async {
    setState(() => _loading = true);
    _myDates = await _repo.fetchForUser(_userId);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _repo.saveForUser(_userId, _myDates);
      if (mounted) {
        showSuccessToast(context, 'Disponibilidade salva!');
      }
    } catch (e) {
      if (mounted) {
        showErrorToast(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool _isSelected(DateTime day) {
    return _myDates.any(
      (d) => d.year == day.year && d.month == day.month && d.day == day.day,
    );
  }

  void _toggleDay(DateTime day) {
    if (day.weekday != DateTime.sunday) return;
    setState(() {
      if (_isSelected(day)) {
        _myDates.removeWhere(
          (d) => d.year == day.year && d.month == day.month && d.day == day.day,
        );
      } else {
        _myDates.add(day);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Disponibilidade'),
        actions: [
          if (!_loading)
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar'),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Selecione os domingos que você está disponível em '
                    '${DateFormat('MMMM/yyyy', 'pt_BR').format(_focusedMonth)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white60,
                    ),
                  ),
                ),
                TableCalendar(
                  firstDay: DateTime(
                    _focusedMonth.year,
                    _focusedMonth.month,
                    1,
                  ),
                  lastDay: DateTime(
                    _focusedMonth.year,
                    _focusedMonth.month + 1,
                    0,
                  ),
                  focusedDay: _focusedMonth,
                  onDaySelected: (selected, focused) => _toggleDay(selected),
                  selectedDayPredicate: _isSelected,
                  enabledDayPredicate: (day) => day.weekday == DateTime.sunday,
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                    ),
                    disabledTextStyle: const TextStyle(color: Colors.white12),
                    outsideDaysVisible: false,
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    leftChevronVisible: false,
                    rightChevronVisible: false,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Disponível'),
                      const SizedBox(width: 24),
                      Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Colors.white12,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Indisponível', style: TextStyle(color: Colors.white38)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
