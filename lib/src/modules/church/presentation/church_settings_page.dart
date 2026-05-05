import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/church_repository.dart';
import '../models/church_model.dart';
import '../../../modules/profiles/presentation/profiles_page.dart';
import '../../../shared/state/app_state.dart';

class ChurchSettingsPage extends StatefulWidget {
  const ChurchSettingsPage({super.key});

  @override
  State<ChurchSettingsPage> createState() => _ChurchSettingsPageState();
}

class _ChurchSettingsPageState extends State<ChurchSettingsPage> {
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int _accentColor = 0xFF3E6C3E;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final church = context.read<AppState>().currentChurch;
    if (church != null) {
      _nameCtrl.text = church.name;
      _cityCtrl.text = church.city ?? '';
      _stateCtrl.text = church.state ?? '';
      _descCtrl.text = church.description ?? '';
      _accentColor = church.accentColor;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);

    try {
      final appState = context.read<AppState>();
      final repo = context.read<ChurchRepository>();
      final churchId = appState.currentChurch!.id;

      await repo.updateChurch(churchId, {
        'name': _nameCtrl.text.trim(),
        'city': _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
        'state': _stateCtrl.text.trim().isEmpty ? null : _stateCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'accentColor': _accentColor,
      });

      // Atualizar estado local
      final updatedChurch = appState.currentChurch!.copyWith(
        name: _nameCtrl.text.trim(),
        city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
        state: _stateCtrl.text.trim().isEmpty ? null : _stateCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        accentColor: _accentColor,
      );
      appState.setChurch(updatedChurch);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configurações salvas!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final church = context.watch<AppState>().currentChurch;
    final inviteCode = church?.id.substring(0, 8).toUpperCase() ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações da Igreja')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Código de convite
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.link_rounded,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Código de convite',
                          style: TextStyle(color: Colors.white54, fontSize: 12)),
                      Text(
                        inviteCode,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 4,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_outlined),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: inviteCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Código copiado!')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nome da Igreja *',
              prefixIcon: Icon(Icons.church_rounded),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cityCtrl,
                  decoration: const InputDecoration(labelText: 'Cidade'),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _stateCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'UF'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Descrição',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Cor da Igreja',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: ChurchModel.accentColorOptions.map((color) {
              final selected = _accentColor == color;
              return GestureDetector(
                onTap: () => setState(() => _accentColor = color),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(color),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                      : null,
                ),
              );
            }).toList(),
          ),
          const Divider(height: 40),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.badge_outlined),
            title: const Text('Perfis e Permissões'),
            subtitle: const Text('Gerencie os perfis de acesso dos membros',
                style: TextStyle(fontSize: 12, color: Colors.white38)),
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfilesPage()),
            ),
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
                : const Text('Salvar configurações'),
          ),
        ],
      ),
    );
  }
}
