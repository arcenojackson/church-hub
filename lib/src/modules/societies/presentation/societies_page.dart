import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/societies_repository.dart';
import '../models/society_model.dart';
import '../../../shared/state/app_state.dart';
import 'society_details_page.dart';
import '../../../shared/widgets/swipe_hint_wrapper.dart';

class SocietiesPage extends StatelessWidget {
  const SocietiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<SocietiesRepository>();
    final isAdmin = context.read<AppState>().currentUser?.isAdmin ?? false;

    return StreamBuilder<List<SocietyModel>>(
      stream: repo.watchAll(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final societies = snapshot.data ?? [];

        if (societies.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.groups_outlined, size: 56, color: Colors.white24),
                const SizedBox(height: 16),
                const Text('Nenhum grupo cadastrado'),
                if (isAdmin) ...[
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _showCreateSheet(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Criar grupo'),
                  ),
                ],
              ],
            ),
          );
        }

        return Column(
          children: [
            if (isAdmin)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () => _showCreateSheet(context),
                  ),
                ],
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => Future.delayed(const Duration(milliseconds: 500)),
                child: ListView.separated(
                itemCount: societies.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final s = societies[i];
                  return _SocietyCard(
                    society: s,
                    isAdmin: isAdmin,
                    showHint: i == 0,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => SocietyDetailsPage(society: s)),
                    ),
                    onEdit: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => _CreateSocietySheet(society: s),
                    ),
                    onDelete: () => context.read<SocietiesRepository>().delete(s.id),
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

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CreateSocietySheet(),
    );
  }

}

class _SocietyCard extends StatelessWidget {
  const _SocietyCard({
    required this.society,
    required this.onTap,
    this.isAdmin = false,
    this.showHint = false,
    this.onEdit,
    this.onDelete,
  });
  final SocietyModel society;
  final VoidCallback onTap;
  final bool isAdmin;
  final bool showHint;
  final VoidCallback? onEdit;
  final Future<void> Function()? onDelete;

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Excluir grupo'),
            content: Text(
                'Tem certeza que deseja excluir "${society.name}"? Esta ação não pode ser desfeita.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Excluir'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final card = Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Color(society.color).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.groups_rounded, color: Color(society.color)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(society.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      '${society.membersIds.length} membros',
                      style: const TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (isAdmin) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  color: Colors.white38,
                  visualDensity: VisualDensity.compact,
                  onPressed: onEdit,
                ),
              ],
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: Colors.white24),
            ],
          ),
        ),
      ),
    );

    if (!isAdmin) return card;

    return Dismissible(
      key: ValueKey(society.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.red[700],
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        final confirmed = await _confirmDelete(context);
        if (confirmed) await onDelete?.call();
        return false;
      },
      child: showHint
          ? SwipeHintWrapper(screenKey: 'societies', child: card)
          : card,
    );
  }
}

class _CreateSocietySheet extends StatefulWidget {
  const _CreateSocietySheet({this.society});
  final SocietyModel? society;

  @override
  State<_CreateSocietySheet> createState() => _CreateSocietySheetState();
}

class _CreateSocietySheetState extends State<_CreateSocietySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late int _color;
  bool _saving = false;

  bool get _isEditing => widget.society != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.society?.name ?? '');
    _descCtrl = TextEditingController(text: widget.society?.description ?? '');
    _color = widget.society?.color ?? 0xFF3E6C3E;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = context.read<SocietiesRepository>();
      if (_isEditing) {
        await repo.update(widget.society!.id, {
          'name': _nameCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'color': _color,
        });
      } else {
        final user = context.read<AppState>().currentUser!;
        await repo.create(
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          color: _color,
          userId: user.id,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing ? 'Editar Grupo' : 'Novo Grupo',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nome do grupo *'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Descrição'),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              Text('Cor do grupo',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _kGroupColors.map((c) {
                  final selected = _color == c;
                  return GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: selected
                            ? [BoxShadow(color: Color(c).withValues(alpha: 0.6), blurRadius: 6)]
                            : null,
                      ),
                      child: selected
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_isEditing ? 'Salvar' : 'Criar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const List<int> _kGroupColors = [
  0xFF4CAF50, 0xFF2196F3, 0xFF9C27B0, 0xFFF44336, 0xFFFF9800,
  0xFF00BCD4, 0xFFE91E63, 0xFF3F51B5, 0xFF009688, 0xFFFF5722,
  0xFFCDDC39, 0xFF795548, 0xFF607D8B, 0xFFFFEB3B, 0xFF8BC34A,
];
