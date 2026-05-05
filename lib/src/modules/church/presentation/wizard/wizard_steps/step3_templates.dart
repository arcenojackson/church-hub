import 'package:flutter/material.dart';

import '../onboarding_wizard_page.dart';

class _TemplateOption {
  const _TemplateOption({required this.id, required this.label, required this.icon, required this.description});
  final String id;
  final String label;
  final IconData icon;
  final String description;
}

class WizardStep3Templates extends StatefulWidget {
  const WizardStep3Templates({super.key, required this.data, required this.onNext});

  final OnboardingWizardData data;
  final VoidCallback onNext;

  @override
  State<WizardStep3Templates> createState() => _WizardStep3TemplatesState();
}

class _WizardStep3TemplatesState extends State<WizardStep3Templates> {
  late Set<String> _selected = Set.from(widget.data.selectedTemplates);

  static const _options = [
    _TemplateOption(
      id: 'culto_dominical',
      label: 'Culto Dominical',
      icon: Icons.wb_sunny_outlined,
      description: 'Culto principal do domingo',
    ),
    _TemplateOption(
      id: 'ebd',
      label: 'EBD',
      icon: Icons.menu_book_outlined,
      description: 'Escola Bíblica Dominical',
    ),
    _TemplateOption(
      id: 'reuniao_oracao',
      label: 'Reunião de Oração',
      icon: Icons.volunteer_activism_outlined,
      description: 'Reunião de oração semanal',
    ),
    _TemplateOption(
      id: 'ensaio_louvor',
      label: 'Ensaio de Louvor',
      icon: Icons.music_note_rounded,
      description: 'Ensaio da equipe de louvor',
    ),
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
                  'Templates de Evento',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Selecione os tipos de evento que sua igreja realiza',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white60,
                  ),
                ),
                const SizedBox(height: 32),
                ..._options.map((opt) {
                  final isSelected = _selected.contains(opt.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selected.remove(opt.id);
                          } else {
                            _selected.add(opt.id);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.05),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.white.withValues(alpha: 0.1),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(opt.icon, size: 32,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.white60),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(opt.label,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: isSelected ? Colors.white : Colors.white70,
                                      )),
                                  Text(opt.description,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.white38,
                                      )),
                                ],
                              ),
                            ),
                            Icon(
                              isSelected
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.white24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: FilledButton(
            onPressed: () {
              widget.data.selectedTemplates = _selected.toList();
              widget.onNext();
            },
            child: const Text('Próximo'),
          ),
        ),
      ],
    );
  }
}
