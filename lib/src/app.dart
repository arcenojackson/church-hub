import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/config/firebase_config.dart';
import 'modules/auth/presentation/login_page.dart';
import 'modules/church/data/church_repository.dart';
import 'modules/church/presentation/church_selection_page.dart';
import 'modules/home/presentation/home_shell.dart';
import 'shared/state/app_state.dart';
import 'shared/theme/app_theme.dart';
import 'shared/widgets/splash_page.dart';
import 'web/landing_page.dart';

class ChurchHubApp extends StatelessWidget {
  const ChurchHubApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final accentColor = context.select<AppState, int?>(
      (s) => s.currentChurch?.accentColor ?? s.cachedAccentColor,
    );

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(accentColor: accentColor),
      home: const _AppHome(),
    );
  }
}

class _AppHome extends StatefulWidget {
  const _AppHome();

  @override
  State<_AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends State<_AppHome> with WidgetsBindingObserver {
  String? _lastLoadedUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<AppState>().addListener(_onAuthStateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadChurch());
  }

  @override
  void dispose() {
    context.read<AppState>().removeListener(_onAuthStateChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      FirebaseConfig.auth.currentUser?.getIdToken(true);
    }
  }

  void _onAuthStateChanged() {
    final appState = context.read<AppState>();
    final user = appState.currentUser;
    if (user == null) {
      _lastLoadedUserId = null;
      return;
    }
    if (user.hasChurch && user.id != _lastLoadedUserId) {
      _loadChurch();
    }
  }

  Future<void> _loadChurch() async {
    final appState = context.read<AppState>();
    final user = appState.currentUser;
    if (user == null || !user.hasChurch) return;

    _lastLoadedUserId = user.id;

    try {
      final repo = context.read<ChurchRepository>();
      final church = await repo.fetchChurch(user.churchId!);
      if (church != null && mounted) {
        appState.setChurch(church);

        final settings = await repo.fetchSettings(user.churchId!);
        if (mounted && settings != null) appState.setChurchSettings(settings);

      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final authKey =
            '${appState.isBootstrapping}-${appState.isAuthenticated}-'
            '${appState.currentUser?.churchId}';

        if (appState.isBootstrapping) {
          return SplashPage(key: ValueKey('splash-$authKey'));
        }

        // Web não autenticado → landing page
        if (!appState.isAuthenticated && kIsWeb) {
          return LandingPage(key: ValueKey('landing-$authKey'));
        }

        if (!appState.isAuthenticated) {
          return LoginPage(key: ValueKey('login-$authKey'));
        }

        if (appState.needsChurchSetup) {
          return ChurchSelectionPage(key: ValueKey('church-sel-$authKey'));
        }

        return HomeShell(key: ValueKey('home-$authKey'));
      },
    );
  }
}
