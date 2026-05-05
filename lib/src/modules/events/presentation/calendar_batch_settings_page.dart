import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/utils/app_toast.dart';
import '../../../shared/widgets/swipe_hint_wrapper.dart';
import '../../societies/data/societies_repository.dart';
import '../../societies/models/society_model.dart';
import '../data/calendar_batch_repository.dart';
import '../models/calendar_batch_template_model.dart';
import 'template_steps_page.dart';

class CalendarBatchSettingsPage extends StatefulWidget {
  const CalendarBatchSettingsPage({super.key});

  @override
  State<CalendarBatchSettingsPage> createState() => _CalendarBatchSettingsPageState();
}

class _CalendarBatchSettingsPageState extends State<CalendarBatchSettingsPage> {
  List<CalendarBatchTemplateModel> _templates = [];
  List<SocietyModel> _societies = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        context.read<CalendarBatchRepository>().fetchAll(),
        context.read<SocietiesRepository>().fetchAll(),
      ]);
      if (mounted) {
        setState(() {
          _templates = results[0] as List<CalendarBatchTemplateModel>;
          _societies = results[1] as List<SocietyModel>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _addTemplate() async {
    final result = await showModalBottomSheet<CalendarBatchTemplateModel>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _TemplateFormSheet(societies: _societies),
    );
    if (result == null || !mounted) return;
    try {
      final repo = context.read<CalendarBatchRepository>();
      await repo.create(
        name: result.name,
        dayOfWeek: result.dayOfWeek,
        time: result.time,
        active: result.active,
        weekGroups: result.weekGroups,
      );
      await _load();
      if (mounted) showSuccessToast(context, 'Template criado.');
    } catch (e) {
      if (mounted) showErrorToast(context, 'Erro ao criar template.');
    }
  }

  void _editTemplate(CalendarBatchTemplateModel template) async {
    final result = await showModalBottomSheet<CalendarBatchTemplateModel>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _TemplateFormSheet(template: template, societies: _societies),
    );
    if (result == null || !mounted) return;
    try {
      final repo = context.read<CalendarBatchRepository>();
      await repo.update(result.copyWith(
        name: result.name,
        dayOfWeek: result.dayOfWeek,
        time: result.time,
        active: result.active,
        weekGroups: result.weekGroups,
      ));
      await _load();
      if (mounted) showSuccessToast(context, 'Template atualizado.');
    } catch (e) {
      if (mounted) showErrorToast(context, 'Erro ao atualizar template.');
    }
  }

  void _openSteps(CalendarBatchTemplateModel template) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TemplateStepsPage(template: template)),
    ).then((_) => _load());
  }

  Future<void> _deleteTemplate(CalendarBatchTemplateModel template) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir template'),
        content: Text('Deseja excluir "${template.name}"?'),
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
    if (confirm != true || !mounted) return;
    try {
      await context.read<CalendarBatchRepository>().delete(template.id);
      await _load();
      if (mounted) showSuccessToast(context, 'Template excluído.');
    } catch (e) {
      if (mounted) showErrorToast(context, 'Erro ao excluir template.');
    }
  }

  Widget _buildTemplateCard(
      BuildContext context, CalendarBatchTemplateModel t) {
    final groupCount =
        t.weekGroups.values.where((v) => v.isNotEmpty).length;
    final stepsCount = t.steps.length;
    final color =
        t.active ? Theme.of(context).colorScheme.primary : Colors.grey;
    final subtitle =
        '${CalendarBatchTemplateModel.dayOfWeekLabel(t.dayOfWeek)} às ${t.time}'
        '${groupCount > 0 ? ' · $groupCount semana(s) com grupo' : ''}'
        '${stepsCount > 0 ? ' · $stepsCount etapa(s)' : ''}'
        '${!t.active ? ' · Inativo' : ''}';

    return Card(
      child: InkWell(
        onTap: () => _openSteps(t),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    CalendarBatchTemplateModel.dayOfWeekLabel(t.dayOfWeek)
                        .substring(0, 3),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.name,
                        style:
                            const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 13)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: Colors.white38,
                visualDensity: VisualDensity.compact,
                onPressed: () => _editTemplate(t),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: Colors.white24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compromissos fixos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Novo template',
            onPressed: _addTemplate,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: _load, child: const Text('Tentar novamente')),
                    ],
                  ),
                )
              : _templates.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.event_note_outlined, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text(
                              'Nenhum template configurado.\nTemplates definem quais eventos recorrentes são criados em lote para o mês.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: _addTemplate,
                              icon: const Icon(Icons.add),
                              label: const Text('Criar template'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                      itemCount: _templates.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final t = _templates[index];
                        final card = _buildTemplateCard(context, t);
                        final child = index == 0
                            ? SwipeHintWrapper(
                                screenKey: 'calendar_batch', child: card)
                            : card;
                        return Dismissible(
                          key: ValueKey(t.id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) async {
                            await _deleteTemplate(t);
                            return false;
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.red.shade700,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(Icons.delete_outline_rounded,
                                color: Colors.white),
                          ),
                          child: child,
                        );
                      },
                      ),
                    ),
    );
  }
}

class _TemplateFormSheet extends StatefulWidget {
  const _TemplateFormSheet({this.template, required this.societies});

  final CalendarBatchTemplateModel? template;
  final List<SocietyModel> societies;

  @override
  State<_TemplateFormSheet> createState() => _TemplateFormSheetState();
}

class _TemplateFormSheetState extends State<_TemplateFormSheet> {
  final _nameController = TextEditingController();
  final _timeController = TextEditingController();
  int _dayOfWeek = 7; // Sunday
  bool _active = true;
  Map<int, String> _weekGroups = {};

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    if (t != null) {
      _nameController.text = t.name;
      _timeController.text = t.time;
      _dayOfWeek = t.dayOfWeek;
      _active = t.active;
      _weekGroups = Map.from(t.weekGroups);
    } else {
      _timeController.text = '19:30';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  CalendarBatchTemplateModel _buildResult() {
    final t = widget.template;
    return CalendarBatchTemplateModel(
      id: t?.id ?? '',
      churchId: t?.churchId ?? '',
      name: _nameController.text.trim(),
      dayOfWeek: _dayOfWeek,
      time: _timeController.text.trim(),
      active: _active,
      weekGroups: Map.from(_weekGroups),
    );
  }

  bool get _valid => _nameController.text.trim().isNotEmpty && _timeController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1F2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                widget.template == null ? 'Novo template' : 'Editar template',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do evento *',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<int>(
                initialValue: _dayOfWeek,
                decoration: const InputDecoration(
                  labelText: 'Dia da semana',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(7, (i) => i + 1).map((d) => DropdownMenuItem(
                  value: d,
                  child: Text(CalendarBatchTemplateModel.dayOfWeekLabel(d)),
                )).toList(),
                onChanged: (v) { if (v != null) setState(() => _dayOfWeek = v); },
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _timeController,
                decoration: const InputDecoration(
                  labelText: 'Horário (HH:mm) *',
                  hintText: '19:30',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.datetime,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Ativo', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Templates inativos são ignorados na criação em lote',
                  style: TextStyle(color: Colors.white54)),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
            if (widget.societies.isNotEmpty) ...[
              const Divider(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('Grupo responsável por semana (opcional)',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
              ),
              const SizedBox(height: 8),
              for (int week = 1; week <= 4; week++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: DropdownButtonFormField<String>(
                    initialValue: _weekGroups[week]?.isNotEmpty == true ? _weekGroups[week] : null,
                    decoration: InputDecoration(
                      labelText: 'Semana $week',
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Nenhum')),
                      ...widget.societies.map((s) => DropdownMenuItem(
                        value: s.id,
                        child: Row(
                          children: [
                            Container(
                              width: 12, height: 12,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(shape: BoxShape.circle, color: Color(s.color)),
                            ),
                            Text(s.name),
                          ],
                        ),
                      )),
                    ],
                    onChanged: (v) {
                      setState(() {
                        if (v == null) {
                          _weekGroups.remove(week);
                        } else {
                          _weekGroups[week] = v;
                        }
                      });
                    },
                  ),
                ),
            ],
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton(
                onPressed: _valid ? () => Navigator.of(context).pop(_buildResult()) : null,
                child: const Text('Salvar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
