import 'package:flutter/material.dart';

import '../../../../../modules/church/models/church_settings_model.dart';
import '../onboarding_wizard_page.dart';

class WizardStep5Reminders extends StatefulWidget {
  const WizardStep5Reminders({
    super.key,
    required this.data,
    required this.isSaving,
    required this.onFinish,
  });

  final OnboardingWizardData data;
  final bool isSaving;
  final VoidCallback onFinish;

  @override
  State<WizardStep5Reminders> createState() => _WizardStep5RemindersState();
}

class _WizardStep5RemindersState extends State<WizardStep5Reminders> {
  bool _eloReminder = true;
  bool _liturgyReminder = true;
  int _eloReminderDays = 7;
  int _liturgyReminderDays = 2;

  List<ReminderRule> _buildRules() {
    final rules = <ReminderRule>[];
    if (_eloReminder) {
      rules.add(ReminderRule(
        id: 'elo_availability',
        type: 'elo_availability',
        daysBeforeEvent: _eloReminderDays,
        message: 'Confirme sua disponibilidade para o próximo mês',
      ));
    }
    if (_liturgyReminder) {
      rules.add(ReminderRule(
        id: 'liturgy_reminder',
        type: 'liturgy_reminder',
        daysBeforeEvent: _liturgyReminderDays,
        message: 'Prepare a liturgia do culto',
      ));
    }
    return rules;
  }

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
                  'Lembretes Automáticos',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Configure quando o app envia lembretes automáticos',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white60,
                  ),
                ),
                const SizedBox(height: 32),
                _ReminderCard(
                  title: 'Disponibilidade ELO',
                  description: 'Lembrar membros de confirmar disponibilidade',
                  enabled: _eloReminder,
                  onChanged: (v) => setState(() => _eloReminder = v),
                  daysValue: _eloReminderDays,
                  onDaysChanged: (v) => setState(() => _eloReminderDays = v),
                  daysOptions: const [3, 5, 7, 10, 14],
                ),
                const SizedBox(height: 16),
                _ReminderCard(
                  title: 'Preparação de Liturgia',
                  description: 'Lembrar responsável de preparar a liturgia',
                  enabled: _liturgyReminder,
                  onChanged: (v) => setState(() => _liturgyReminder = v),
                  daysValue: _liturgyReminderDays,
                  onDaysChanged: (v) => setState(() => _liturgyReminderDays = v),
                  daysOptions: const [1, 2, 3, 5],
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.white38),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Você pode ajustar os lembretes depois nas configurações da igreja.',
                          style: TextStyle(color: Colors.white38, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: FilledButton(
            onPressed: widget.isSaving
                ? null
                : () {
                    widget.data.reminderRules = _buildRules();
                    widget.onFinish();
                  },
            child: widget.isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Criar Igreja'),
          ),
        ),
      ],
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.title,
    required this.description,
    required this.enabled,
    required this.onChanged,
    required this.daysValue,
    required this.onDaysChanged,
    required this.daysOptions,
  });

  final String title;
  final String description;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final int daysValue;
  final ValueChanged<int> onDaysChanged;
  final List<int> daysOptions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        )),
                    Text(description,
                        style: const TextStyle(color: Colors.white38, fontSize: 13)),
                  ],
                ),
              ),
              Switch(value: enabled, onChanged: onChanged),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 12),
            Text('Lembrar quantos dias antes?',
                style: const TextStyle(color: Colors.white60, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: daysOptions.map((d) {
                final selected = daysValue == d;
                return ChoiceChip(
                  label: Text('$d dias'),
                  selected: selected,
                  onSelected: (_) => onDaysChanged(d),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
