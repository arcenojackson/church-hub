import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../modules/auth/models/user_model.dart';
import '../../../../shared/state/app_state.dart';
import '../../../../core/utils/app_exception.dart';
import '../../data/church_repository.dart';
import '../../models/church_settings_model.dart';
import '../../../../modules/profiles/data/profiles_repository.dart';
import '../../../../modules/musics/data/musics_repository.dart';
import 'wizard_steps/step1_identity.dart';
import 'wizard_steps/step2_elo_config.dart';
import 'wizard_steps/step3_templates.dart';
import 'wizard_steps/step4_structure.dart';
import 'wizard_steps/step5_reminders.dart';

class OnboardingWizardData {
  String churchName = '';
  String? logo;
  String? city;
  String? state;
  String? description;
  int accentColor = 0xFF3E6C3E;
  List<EloRoleConfig> eloRoles = [];
  List<String> selectedTemplates = ['culto_dominical'];
  List<Map<String, dynamic>> defaultSteps = [];
  List<ReminderRule> reminderRules = [];
}

class OnboardingWizardPage extends StatefulWidget {
  const OnboardingWizardPage({super.key});

  @override
  State<OnboardingWizardPage> createState() => _OnboardingWizardPageState();
}

class _OnboardingWizardPageState extends State<OnboardingWizardPage> {
  final _data = OnboardingWizardData();
  int _currentStep = 0;
  bool _saving = false;

  final _steps = const [
    'Identidade',
    'ELO',
    'Templates',
    'Estrutura',
    'Lembretes',
  ];

  Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      final repo = context.read<ChurchRepository>();
      final appState = context.read<AppState>();

      // 1. Criar a igreja
      final church = await repo.createChurch(
        name: _data.churchName,
        accentColor: _data.accentColor,
        logo: _data.logo,
        city: _data.city,
        state: _data.state,
        description: _data.description,
      );

      // 2. Associar usuário à igreja como admin antes de escrever sub-coleções
      // (as regras do Firestore exigem churchAdmin para settings/inviteCode/setup)
      await appState.assignUserToChurch(
        church.id,
        UserRole.churchAdmin,
      );

      // 3. Salvar configurações
      final settings = ChurchSettingsModel(
        churchId: church.id,
        eloRoles: _data.eloRoles,
        reminderRules: _data.reminderRules,
        defaultSteps: _data.defaultSteps,
      );
      await repo.saveSettings(church.id, settings);

      // 4. Gerar código de convite
      await repo.generateInviteCode(church.id);

      // 5. Marcar setup como completo
      await repo.completeSetup(church.id);

      // 6. Criar perfis padrão da nova igreja
      final profileRepo = ProfilesRepository(churchId: church.id);
      await profileRepo.seedDefaultProfiles();

      // 7. Criar música de exemplo
      final musicsRepo = MusicsRepository(churchId: church.id);
      await musicsRepo.create(
        title: 'Redenção',
        artist: 'Projeto Sola',
        tone: 'D',
        minorTone: false,
        category: '',
        cipher: 'https://www.cifraclub.com.br/projeto-sola/redencao/',
        lyrics: 'https://www.cifraclub.com.br/projeto-sola/redencao/letra/',
        youtube: 'https://www.youtube.com/watch?v=sX0KVSex6lI',
        bpm: '0',
        obs: 'Música de exemplo',
      );

      // 9. Atualizar estado local
      final completedChurch = church.copyWith(setupCompleted: true);
      appState.setChurch(completedChurch);
      appState.setChurchSettings(settings);

      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro inesperado. Tente novamente.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_currentStep + 1}/${_steps.length} — ${_steps[_currentStep]}'),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => setState(() => _currentStep--),
              )
            : const CloseButton(),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentStep + 1) / _steps.length,
            backgroundColor: Colors.white12,
          ),
          Expanded(
            child: _buildStep(),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 0:
        return WizardStep1Identity(
          data: _data,
          onNext: () => setState(() => _currentStep++),
        );
      case 1:
        return WizardStep2EloConfig(
          data: _data,
          onNext: () => setState(() => _currentStep++),
        );
      case 2:
        return WizardStep3Templates(
          data: _data,
          onNext: () => setState(() => _currentStep++),
        );
      case 3:
        return WizardStep4Structure(
          data: _data,
          onNext: () => setState(() => _currentStep++),
        );
      case 4:
        return WizardStep5Reminders(
          data: _data,
          isSaving: _saving,
          onFinish: _finish,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
