import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/app_exception.dart';
import '../../modules/auth/data/auth_repository.dart';
import '../../modules/auth/models/user_model.dart';
import '../../modules/church/models/church_model.dart';
import '../../modules/church/models/church_settings_model.dart';
import '../../modules/profiles/models/profile_model.dart';
import '../permissions/app_permission.dart';

class AppState extends ChangeNotifier {
  AppState({required AuthRepository authRepository})
      : _authRepository = authRepository;

  final AuthRepository _authRepository;

  static const _accentColorKey = 'church_hub_accent_color';

  UserModel? _currentUser;
  ChurchModel? _currentChurch;
  ChurchSettingsModel? _churchSettings;
  bool _isBootstrapping = true;
  bool _isLoading = false;
  String? _error;
  List<ProfileModel> _churchProfiles = [];
  ProfileModel? _currentUserProfile;
  int? _cachedAccentColor;

  UserModel? get currentUser => _currentUser;
  ChurchModel? get currentChurch => _currentChurch;
  int? get cachedAccentColor => _cachedAccentColor;
  ChurchSettingsModel? get churchSettings => _churchSettings;
  bool get isAuthenticated => _currentUser != null;
  bool get isBootstrapping => _isBootstrapping;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<ProfileModel> get churchProfiles => _churchProfiles;
  ProfileModel? get currentUserProfile => _currentUserProfile;

  /// Verifica se o usuário atual tem uma permissão.
  /// Admins (pelo campo role legado) sempre têm acesso total.
  /// Usuários sem profileId são tratados como perfil 'member'.
  bool can(String permission) {
    if (_currentUser?.isAdmin ?? false) return true;
    if (_currentUserProfile != null) {
      return _currentUserProfile!.can(permission);
    }
    // Fallback: sem perfil carregado, usar defaults do Membro
    return AppPermission.memberDefaults[permission] ?? false;
  }

  void setChurchProfiles(List<ProfileModel> profiles) {
    _churchProfiles = profiles;
    // Resolver o perfil do usuário atual
    final profileId = _currentUser?.profileId ?? 'member';
    _currentUserProfile = profiles.firstWhere(
      (p) => p.id == profileId,
      orElse: () => profiles.firstWhere(
        (p) => p.isDefault,
        orElse: () => ProfileModel(
          id: 'member',
          name: 'Membro',
          permissions: AppPermission.memberDefaults,
          isDefault: true,
        ),
      ),
    );
    notifyListeners();
  }

  bool get needsChurchSetup =>
      isAuthenticated && !(_currentUser?.hasChurch ?? false);

  bool get hasChurchAdminAccess =>
      _currentUser?.isAdmin ?? false;

  Future<void> bootstrap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(_accentColorKey);
      if (saved != null) _cachedAccentColor = saved;
      _currentUser = await _authRepository.restoreSession();
    } finally {
      _isBootstrapping = false;
      notifyListeners();
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    await _exec(() async {
      _currentUser = await _authRepository.signIn(email: email, password: password);
    });
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    await _exec(() async {
      _currentUser = await _authRepository.signUp(name: name, email: email, password: password);
    });
  }

  Future<void> signInWithGoogle() async {
    await _exec(() async {
      _currentUser = await _authRepository.signInWithGoogle();
    });
  }

  Future<void> signInWithApple() async {
    await _exec(() async {
      _currentUser = await _authRepository.signInWithApple();
    });
  }

  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
      _currentUser = null;
      _currentChurch = null;
      _churchSettings = null;
      _churchProfiles = [];
      _currentUserProfile = null;
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao fazer logout: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    try {
      await _authRepository.deleteAccount();
      _currentUser = null;
      _currentChurch = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateUserName(String newName) async {
    await _exec(() async {
      _currentUser = await _authRepository.updateUserName(newName);
    });
  }

  void updateDisabledNotifications(List<String> disabled) {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(disabledNotifications: disabled);
    notifyListeners();
  }

  Future<void> updateUserProfile({
    required String name,
    String? phone,
    DateTime? birthday,
  }) async {
    await _exec(() async {
      _currentUser = await _authRepository.updateUserProfile(
        name: name,
        phone: phone,
        birthday: birthday,
      );
    });
  }

  Future<void> assignUserToChurch(String churchId, UserRole role) async {
    await _exec(() async {
      _currentUser = await _authRepository.assignChurch(
        _currentUser!.id,
        churchId,
        role,
      );
    });
  }

  void setChurch(ChurchModel church) {
    _currentChurch = church;
    _cachedAccentColor = church.accentColor;
    SharedPreferences.getInstance()
        .then((p) => p.setInt(_accentColorKey, church.accentColor));
    notifyListeners();
  }

  void setChurchSettings(ChurchSettingsModel settings) {
    _churchSettings = settings;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> _exec(Future<void> Function() action) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      _isLoading = false;
      notifyListeners();
    } on AppException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _error = 'Erro inesperado. Tente novamente.';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
