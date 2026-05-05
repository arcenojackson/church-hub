import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'src/app.dart';
import 'src/core/config/firebase_config.dart';
import 'src/modules/auth/data/auth_repository.dart';
import 'src/modules/church/data/church_repository.dart';
import 'src/modules/events/data/calendar_batch_repository.dart';
import 'src/modules/events/data/events_repository.dart';
import 'src/modules/musics/data/musics_repository.dart';
import 'src/modules/people/data/people_repository.dart';
import 'src/modules/societies/data/societies_repository.dart';
import 'src/modules/profiles/data/profiles_repository.dart';
import 'src/modules/notifications/services/notification_service.dart';
import 'src/shared/services/session_storage.dart';
import 'src/shared/state/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await initializeDateFormatting('pt_BR', null);

  await FirebaseConfig.initialize();

  final storage = SessionStorage();
  final authRepository = AuthRepository(sessionStorage: storage);
  final appState = AppState(authRepository: authRepository);

  await appState.bootstrap();

  await NotificationService().initialize();

  runApp(
    MultiProvider(
      providers: [
        Provider<SessionStorage>.value(value: storage),
        Provider<AuthRepository>.value(value: authRepository),
        Provider<ChurchRepository>.value(value: ChurchRepository()),
        ChangeNotifierProvider<AppState>.value(value: appState),

        // Repositories com churchId — recriam automaticamente quando AppState muda
        // Os widgets que usam estes repos só são exibidos quando churchId não é null
        ProxyProvider<AppState, EventsRepository>(
          update: (_, state, __) =>
              EventsRepository(churchId: state.currentUser?.churchId ?? ''),
        ),
        ProxyProvider<AppState, MusicsRepository>(
          update: (_, state, __) =>
              MusicsRepository(churchId: state.currentUser?.churchId ?? ''),
        ),
        ProxyProvider<AppState, PeopleRepository>(
          update: (_, state, __) =>
              PeopleRepository(churchId: state.currentUser?.churchId ?? ''),
        ),
        ProxyProvider<AppState, SocietiesRepository>(
          update: (_, state, __) =>
              SocietiesRepository(churchId: state.currentUser?.churchId ?? ''),
        ),
        ProxyProvider<AppState, ProfilesRepository>(
          update: (_, state, __) =>
              ProfilesRepository(churchId: state.currentUser?.churchId ?? ''),
        ),
        ProxyProvider<AppState, CalendarBatchRepository>(
          update: (_, state, __) =>
              CalendarBatchRepository(churchId: state.currentUser?.churchId ?? ''),
        ),
      ],
      child: const ChurchHubApp(),
    ),
  );
}
