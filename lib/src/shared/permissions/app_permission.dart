// lib/src/shared/permissions/app_permission.dart

class AppPermission {
  AppPermission._();

  // Agenda e Eventos
  static const viewAgenda        = 'view_agenda';
  static const planEvents        = 'plan_events';
  static const viewServiceOrder  = 'view_service_order';

  // Calendário
  static const viewCalendar      = 'view_calendar';

  // Músicas
  static const viewMusics        = 'view_musics';
  static const editMusics        = 'edit_musics';

  // Membros
  static const viewPeople        = 'view_people';
  static const managePeople      = 'manage_people';

  // Chat de Evento
  static const viewEventChat     = 'view_event_chat';
  static const sendEventChat     = 'send_event_chat';

  // Grupos / Sociedades
  static const viewSocieties     = 'view_societies';
  static const manageSocieties   = 'manage_societies';

  // Avaliações Musicais
  static const viewEvaluations   = 'view_evaluations';
  static const submitEvaluations = 'submit_evaluations';
  static const manageEvaluations = 'manage_evaluations';

  // Holyrics
  static const configHolyrics    = 'config_holyrics';

  // Configurações da Igreja
  static const manageChurchSettings = 'manage_church_settings';

  /// Permissões padrão do perfil "Membro"
  static const Map<String, bool> memberDefaults = {
    viewAgenda:           true,
    planEvents:           false,
    viewServiceOrder:     true,
    viewCalendar:         true,
    viewMusics:           true,
    editMusics:           false,
    viewPeople:           false,
    managePeople:         false,
    viewEventChat:        true,
    sendEventChat:        true,
    viewSocieties:        true,
    manageSocieties:      false,
    viewEvaluations:      true,
    submitEvaluations:    true,
    manageEvaluations:    false,
    configHolyrics:       false,
    manageChurchSettings: false,
  };
}
