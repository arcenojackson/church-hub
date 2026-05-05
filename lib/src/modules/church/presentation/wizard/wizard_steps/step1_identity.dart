import 'package:flutter/material.dart';

import '../../../../../modules/church/models/church_model.dart';
import '../onboarding_wizard_page.dart';

class WizardStep1Identity extends StatefulWidget {
  const WizardStep1Identity({super.key, required this.data, required this.onNext});

  final OnboardingWizardData data;
  final VoidCallback onNext;

  @override
  State<WizardStep1Identity> createState() => _WizardStep1IdentityState();
}

class _WizardStep1IdentityState extends State<WizardStep1Identity> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(text: widget.data.churchName);
  late final _cityCtrl = TextEditingController(text: widget.data.city ?? '');
  late final _stateCtrl = TextEditingController(text: widget.data.state ?? '');
  late final _descCtrl = TextEditingController(text: widget.data.description ?? '');
  late int _selectedColor = widget.data.accentColor;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    widget.data.churchName = _nameCtrl.text.trim();
    widget.data.city = _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim();
    widget.data.state = _stateCtrl.text.trim().isEmpty ? null : _stateCtrl.text.trim();
    widget.data.description = _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim();
    widget.data.accentColor = _selectedColor;
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Identidade da Igreja',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Como sua igreja vai aparecer no aplicativo',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white60),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nome da Igreja *',
                prefixIcon: Icon(Icons.church_rounded),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Cidade',
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    controller: _stateCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(labelText: 'UF'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                prefixIcon: Icon(Icons.notes_rounded),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Cor principal',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: ChurchModel.accentColorOptions.map((color) {
                final selected = _selectedColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Color(color),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),
            FilledButton(
              onPressed: _next,
              child: const Text('Próximo'),
            ),
          ],
        ),
      ),
    );
  }
}
