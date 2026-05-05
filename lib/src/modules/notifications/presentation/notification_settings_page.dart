import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/state/app_state.dart';
import '../../../shared/widgets/glass_container.dart';
import '../models/notification_type.dart';
import '../repositories/notification_repository.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final _repository = NotificationRepository();
  bool _isLoading = true;
  List<String> _disabledNotifications = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = context.read<AppState>().currentUser;
    if (user == null) return;

    try {
      final disabled = await _repository.getDisabledNotifications(user.id);
      if (mounted) {
        setState(() {
          _disabledNotifications = disabled;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao carregar configurações')),
        );
      }
    }
  }

  Future<void> _toggle(NotificationType type, bool enabled) async {
    final appState = context.read<AppState>();
    final user = appState.currentUser;
    if (user == null) return;

    try {
      if (enabled) {
        await _repository.enableNotification(user.id, type);
      } else {
        await _repository.disableNotification(user.id, type);
      }

      final updated = enabled
          ? _disabledNotifications.where((id) => id != type.id).toList()
          : [..._disabledNotifications, if (!_disabledNotifications.contains(type.id)) type.id];

      setState(() => _disabledNotifications = updated);
      appState.updateDisabledNotifications(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(enabled ? 'Notificação ativada' : 'Notificação desativada'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao atualizar configuração')),
        );
      }
    }
  }

  bool _isEnabled(NotificationType type) =>
      !_disabledNotifications.contains(type.id);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D1220), Color(0xFF05070D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Notificações',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          GlassContainer(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.notifications_active_rounded,
                                    color: theme.colorScheme.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Text(
                                    'Escolha quais notificações você deseja receber',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Tipos de notificação',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GlassContainer(
                            padding: EdgeInsets.zero,
                            child: Column(
                              children: [
                                for (int i = 0;
                                    i < NotificationType.values.length;
                                    i++) ...[
                                  _NotificationTile(
                                    type: NotificationType.values[i],
                                    enabled: _isEnabled(NotificationType.values[i]),
                                    onChanged: (v) =>
                                        _toggle(NotificationType.values[i], v),
                                  ),
                                  if (i < NotificationType.values.length - 1)
                                    const Divider(height: 1, color: Colors.white12),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.type,
    required this.enabled,
    required this.onChanged,
  });

  final NotificationType type;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: enabled,
      onChanged: onChanged,
      activeThumbColor: Theme.of(context).colorScheme.primary,
      title: Text(
        type.title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        type.description,
        style: const TextStyle(color: Colors.white60, fontSize: 12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }
}
