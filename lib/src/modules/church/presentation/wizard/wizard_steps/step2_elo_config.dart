import 'package:flutter/material.dart';

import '../../../../../modules/church/models/church_settings_model.dart';
import '../onboarding_wizard_page.dart';

class WizardStep2EloConfig extends StatefulWidget {
  const WizardStep2EloConfig({super.key, required this.data, required this.onNext});

  final OnboardingWizardData data;
  final VoidCallback onNext;

  @override
  State<WizardStep2EloConfig> createState() => _WizardStep2EloConfigState();
}

class _WizardStep2EloConfigState extends State<WizardStep2EloConfig> {
  late List<EloRoleConfig> _roles = List.from(widget.data.eloRoles);
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _addRole() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _roles.add(EloRoleConfig(
        id: 'role_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      ));
      _nameCtrl.clear();
      _descCtrl.clear();
    });
  }

  void _removeRole(int index) {
    setState(() => _roles.removeAt(index));
  }

  void _next() {
    widget.data.eloRoles = _roles;
    widget.onNext();
  }

  static const _suggestions = [
    'Canto', 'Guitarra', 'Teclado', 'Bateria', 'Baixo',
    'Violão', 'Vocal', 'Pregação', 'Liturgia', 'Sonoplastia',
  ];

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
                  'Equipe de Louvor (ELO)',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Defina as funções/papéis dentro da equipe de louvor da sua igreja',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white60,
                  ),
                ),
                const SizedBox(height: 24),
                // Sugestões rápidas
                Text(
                  'Sugestões:',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white60,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _suggestions.where((s) {
                    return !_roles.any((r) => r.name.toLowerCase() == s.toLowerCase());
                  }).map((s) {
                    return ActionChip(
                      label: Text(s),
                      onPressed: () {
                        setState(() {
                          _roles.add(EloRoleConfig(
                            id: 'role_${DateTime.now().millisecondsSinceEpoch}_$s',
                            name: s,
                          ));
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                // Adicionar role customizada
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nome da função',
                          hintText: 'Ex: Percussão',
                        ),
                        onSubmitted: (_) => _addRole(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filled(
                      onPressed: _addRole,
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_roles.isNotEmpty) ...[
                  Text(
                    'Funções adicionadas:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._roles.asMap().entries.map((e) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.music_note_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(e.value.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                      onPressed: () => _removeRole(e.key),
                    ),
                  )),
                ] else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Nenhuma função adicionada.\nVocê pode adicionar depois nas configurações.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white38),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: FilledButton(
            onPressed: _next,
            child: const Text('Próximo'),
          ),
        ),
      ],
    );
  }
}
