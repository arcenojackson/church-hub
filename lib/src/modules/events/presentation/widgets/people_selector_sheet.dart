import 'package:flutter/material.dart';

import '../../../auth/models/user_model.dart';
import '../../../church/models/church_settings_model.dart';

class PeopleSelectorSheet extends StatefulWidget {
  const PeopleSelectorSheet({
    super.key,
    required this.members,
    required this.currentPeople,
    this.roles = const [],
  });

  final List<UserModel> members;
  final Map<String, List<String>> currentPeople;
  final List<EloRoleConfig> roles;

  @override
  State<PeopleSelectorSheet> createState() => _PeopleSelectorSheetState();
}

class _PeopleSelectorSheetState extends State<PeopleSelectorSheet> {
  final _roleController = TextEditingController();
  final _searchController = TextEditingController();
  late List<UserModel> _filtered;
  late Set<String> _selectedIds;
  String? _selectedRoleId;

  @override
  void initState() {
    super.initState();
    _filtered = List.of(widget.members)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _selectedIds = {};
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _roleController.dispose();
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filtered = List.of(widget.members)
          ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      } else {
        _filtered = widget.members
            .where((m) => m.name.toLowerCase().contains(query))
            .toList()
          ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      }
    });
  }

  String get _roleName {
    if (_selectedRoleId != null) {
      final role = widget.roles.firstWhere(
        (r) => r.id == _selectedRoleId,
        orElse: () => EloRoleConfig(id: _selectedRoleId!, name: _selectedRoleId!),
      );
      return role.name;
    }
    return _roleController.text.trim();
  }

  void _confirm() {
    final roleName = _roleName;
    if (roleName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe a função/papel das pessoas.')),
      );
      return;
    }
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione ao menos uma pessoa.')),
      );
      return;
    }

    final currentForRole =
        List<String>.of(widget.currentPeople[roleName] ?? []);
    for (final id in _selectedIds) {
      if (!currentForRole.contains(id)) {
        currentForRole.add(id);
      }
    }

    Navigator.of(context).pop({roleName: currentForRole});
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;
    final hasRoles = widget.roles.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        bottom: bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Adicionar pessoas',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          if (hasRoles) ...[
            DropdownButtonFormField<String>(
              initialValue: _selectedRoleId,
              hint: const Text('Selecione uma função'),
              items: [
                ...widget.roles.map(
                  (r) => DropdownMenuItem(value: r.id, child: Text(r.name)),
                ),
                const DropdownMenuItem(value: '__custom__', child: Text('Outra função...')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedRoleId = value == '__custom__' ? null : value;
                  if (value == '__custom__') _roleController.clear();
                });
              },
              decoration: const InputDecoration(labelText: 'Função'),
            ),
            if (_selectedRoleId == null) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _roleController,
                decoration: const InputDecoration(
                  labelText: 'Nome da função',
                  hintText: 'Ex: Diaconia, Pregador...',
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ] else
            TextFormField(
              controller: _roleController,
              decoration: const InputDecoration(
                labelText: 'Função / Papel',
                hintText: 'Ex: Equipe de Louvor, Pregador...',
              ),
              onChanged: (_) => setState(() {}),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Buscar membro',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 300,
            child: _filtered.isEmpty
                ? const Center(child: Text('Nenhum membro encontrado.'))
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final member = _filtered[index];
                      final selected = _selectedIds.contains(member.id);
                      return CheckboxListTile(
                        value: selected,
                        title: Text(member.name),
                        subtitle: Text(
                          member.email,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12),
                        ),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedIds.add(member.id);
                            } else {
                              _selectedIds.remove(member.id);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _confirm,
              child: Text(
                _selectedIds.isEmpty
                    ? 'Selecione pessoas'
                    : 'Adicionar ${_selectedIds.length} pessoa${_selectedIds.length == 1 ? '' : 's'}',
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
