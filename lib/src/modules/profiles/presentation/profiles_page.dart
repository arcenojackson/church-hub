// lib/src/modules/profiles/presentation/profiles_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/profiles_repository.dart';
import '../models/profile_model.dart';
import 'profile_editor_page.dart';

class ProfilesPage extends StatelessWidget {
  const ProfilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ProfilesRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfis e Permissões'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ProfileEditorPage(),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<ProfileModel>>(
        stream: repo.watchProfiles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final profiles = snapshot.data ?? [];

          if (profiles.isEmpty) {
            return const Center(child: Text('Nenhum perfil encontrado'));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: profiles.length,
            itemBuilder: (_, i) {
              final p = profiles[i];
              return ListTile(
                leading: Icon(
                  p.isAdminRole
                      ? Icons.shield_rounded
                      : p.isDefault
                          ? Icons.star_rounded
                          : Icons.badge_outlined,
                  color: p.isAdminRole
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white54,
                ),
                title: Text(p.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (p.isAdminRole)
                      const _Badge('fixo')
                    else if (p.isDefault)
                      const _Badge('padrão'),
                    const Icon(Icons.chevron_right_rounded,
                        color: Colors.white24),
                  ],
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProfileEditorPage(profile: p),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, color: Colors.white54),
      ),
    );
  }
}
