// lib/src/modules/profiles/presentation/profile_editor_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/firebase_config.dart';
import '../../../shared/permissions/app_permission.dart';
import '../data/profiles_repository.dart';
import '../../../shared/utils/app_toast.dart';
import '../models/profile_model.dart';

class ProfileEditorPage extends StatefulWidget {
  const ProfileEditorPage({super.key, this.profile});
  final ProfileModel? profile;

  @override
  State<ProfileEditorPage> createState() => _ProfileEditorPageState();
}

class _ProfileEditorPageState extends State<ProfileEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late Map<String, bool> _permissions;
  bool _saving = false;
  bool _deleting = false;

  bool get _isEditing => widget.profile != null;
  bool get _canDelete =>
      _isEditing &&
      !(widget.profile!.isAdminRole) &&
      !(widget.profile!.isDefault);

  static const _categories = [
    ('Agenda e Eventos', [
      (AppPermission.viewAgenda, 'Ver agenda'),
      (AppPermission.planEvents, 'Planejar eventos'),
      (AppPermission.viewServiceOrder, 'Ver roteiro do culto'),
    ]),
    ('Calendário', [
      (AppPermission.viewCalendar, 'Ver calendário'),
    ]),
    ('Músicas', [
      (AppPermission.viewMusics, 'Ver músicas'),
      (AppPermission.editMusics, 'Editar músicas'),
    ]),
    ('Membros', [
      (AppPermission.viewPeople, 'Ver membros'),
      (AppPermission.managePeople, 'Gerenciar membros'),
    ]),
    ('Chat', [
      (AppPermission.viewEventChat, 'Ver chat do evento'),
      (AppPermission.sendEventChat, 'Enviar mensagens no chat'),
    ]),
    ('Grupos', [
      (AppPermission.viewSocieties, 'Ver grupos'),
      (AppPermission.manageSocieties, 'Gerenciar grupos'),
    ]),
    ('Avaliações', [
      (AppPermission.viewEvaluations, 'Ver avaliações'),
      (AppPermission.submitEvaluations, 'Responder avaliações'),
      (AppPermission.manageEvaluations, 'Gerenciar avaliações'),
    ]),
    ('Holyrics', [
      (AppPermission.configHolyrics, 'Configurar Holyrics'),
    ]),
    ('Configurações', [
      (AppPermission.manageChurchSettings, 'Configurações da Igreja'),
    ]),
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile?.name ?? '');
    _permissions = Map<String, bool>.from(
      widget.profile?.permissions ?? AppPermission.memberDefaults,
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = context.read<ProfilesRepository>();
      final profile = ProfileModel(
        id: widget.profile?.id ?? '',
        name: _nameCtrl.text.trim(),
        permissions: _permissions,
        isAdminRole: widget.profile?.isAdminRole ?? false,
        isDefault: widget.profile?.isDefault ?? false,
      );
      await repo.saveProfile(profile);
      if (mounted) {
        showSuccessToast(context, 'Perfil salvo!');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        showErrorToast(context, 'Erro: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final repo = context.read<ProfilesRepository>();
    final churchId = repo.churchId;

    // Contar usuários com este perfil
    final snap = await FirebaseConfig.firestore
        .collection('users')
        .where('churchId', isEqualTo: churchId)
        .where('profileId', isEqualTo: widget.profile!.id)
        .count()
        .get();
    final count = snap.count ?? 0;

    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir perfil?'),
        content: Text(count > 0
            ? '$count ${count == 1 ? 'membro tem' : 'membros têm'} este perfil. '
                'Eles serão migrados para o perfil Membro padrão.'
            : 'Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      // Migrar usuários afetados para perfil 'member'
      if (count > 0) {
        final users = await FirebaseConfig.firestore
            .collection('users')
            .where('churchId', isEqualTo: churchId)
            .where('profileId', isEqualTo: widget.profile!.id)
            .get();
        final batch = FirebaseConfig.firestore.batch();
        for (final doc in users.docs) {
          batch.update(doc.reference, {'profileId': 'member'});
        }
        await batch.commit();
      }

      await repo.deleteProfile(widget.profile!.id);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        showErrorToast(context, 'Erro ao excluir: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFixed = widget.profile?.isAdminRole == true ||
        widget.profile?.isDefault == true;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? widget.profile!.name : 'Novo Perfil'),
        actions: [
          if (_canDelete)
            IconButton(
              icon: _deleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline_rounded,
                      color: Colors.redAccent),
              onPressed: _deleting ? null : _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _nameCtrl,
              enabled: !isFixed,
              decoration: const InputDecoration(
                labelText: 'Nome do perfil *',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              maxLength: 40,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Nome obrigatório' : null,
            ),
            if (isFixed) ...[
              const SizedBox(height: 8),
              const Text(
                'Este é um perfil fixo do sistema e não pode ser editado.',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            ..._categories.map((cat) {
              final (categoryName, perms) = cat;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      categoryName.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  ...perms.map((perm) {
                    final (permKey, permLabel) = perm;
                    return SwitchListTile(
                      title: Text(permLabel),
                      value: widget.profile?.isAdminRole == true
                          ? true
                          : _permissions[permKey] ?? false,
                      onChanged: isFixed
                          ? null
                          : (v) => setState(
                              () => _permissions[permKey] = v),
                      contentPadding: EdgeInsets.zero,
                    );
                  }),
                ],
              );
            }),
            const SizedBox(height: 24),
            if (!isFixed)
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Salvar perfil'),
              ),
          ],
        ),
      ),
    );
  }
}
