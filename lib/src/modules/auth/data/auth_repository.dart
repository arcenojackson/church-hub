import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/config/firebase_config.dart';
import '../../../core/utils/app_exception.dart';
import '../models/user_model.dart';
import '../../../shared/services/session_storage.dart';
import '../../notifications/services/notification_service.dart';

class AuthRepository {
  AuthRepository({required SessionStorage sessionStorage})
      : _sessionStorage = sessionStorage;

  final SessionStorage _sessionStorage;
  final FirebaseAuth _auth = FirebaseConfig.auth;
  final FirebaseFirestore _db = FirebaseConfig.firestore;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '50041359262-jpoeaej8g281psd7hph5gidbibuliq9m.apps.googleusercontent.com',
  );

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentFirebaseUser => _auth.currentUser;

  Future<UserModel> signIn({required String email, required String password}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = await _getOrCreateUser(credential.user!);
      await _sessionStorage.saveUser(user);
      await _saveFcmToken(credential.user!.uid);
      return user;
    } on FirebaseAuthException catch (e) {
      throw AppException(message: _handleAuthError(e));
    } catch (e) {
      throw AppException(message: 'Erro ao fazer login: ${e.toString()}');
    }
  }

  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user!.updateDisplayName(name);

      final user = UserModel(
        id: credential.user!.uid,
        name: name,
        email: email,
        role: UserRole.member,
        status: UserStatus.pending,
      );
      await _createUserInFirestore(user);
      await _sessionStorage.saveUser(user);
      await _saveFcmToken(credential.user!.uid);
      return user;
    } on FirebaseAuthException catch (e) {
      throw AppException(message: _handleAuthError(e));
    } catch (e) {
      throw AppException(message: 'Erro ao criar conta: ${e.toString()}');
    }
  }

  Future<UserModel> signInWithGoogle() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        userCredential = await _auth.signInWithPopup(provider);
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          throw AppException(message: 'Login com Google cancelado');
        }

        final googleAuth = await googleUser.authentication;
        if (googleAuth.accessToken == null && googleAuth.idToken == null) {
          throw AppException(message: 'Falha ao obter tokens do Google.');
        }
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await _auth.signInWithCredential(credential);
      }

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw AppException(message: 'Falha ao autenticar com Google.');
      }

      final user = await _getOrCreateUser(firebaseUser);
      await _sessionStorage.saveUser(user);
      await _saveFcmToken(firebaseUser.uid);
      return user;
    } on FirebaseAuthException catch (e) {
      throw AppException(message: _handleAuthError(e));
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(message: 'Erro no login com Google: ${e.toString()}');
    }
  }

  Future<UserModel> signInWithApple() async {
    try {
      if (!kIsWeb && !Platform.isIOS && !Platform.isMacOS) {
        throw AppException(message: 'Sign In with Apple disponível apenas em iOS/macOS');
      }

      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        throw AppException(message: 'Sign In with Apple não está disponível neste dispositivo');
      }

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);
      var user = await _getUserFromFirestore(userCredential.user!.uid);

      if (user == null) {
        String? name;
        if (appleCredential.givenName != null || appleCredential.familyName != null) {
          name = [appleCredential.givenName, appleCredential.familyName]
              .where((p) => p != null)
              .join(' ');
        }
        user = UserModel(
          id: userCredential.user!.uid,
          name: name ?? userCredential.user!.displayName ?? 'Usuário Apple',
          email: userCredential.user!.email ?? appleCredential.email ?? '',
          role: UserRole.member,
          status: UserStatus.pending,
        );
        await _createUserInFirestore(user);
      }

      await _sessionStorage.saveUser(user);
      await _saveFcmToken(userCredential.user!.uid);
      return user;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw AppException(message: 'Login com Apple cancelado');
      }
      throw AppException(message: 'Erro Apple: ${e.message}');
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(message: 'Erro no login com Apple: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    await _sessionStorage.clear();
  }

  Future<UserModel?> restoreSession() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return _sessionStorage.loadUser();

    try {
      await firebaseUser.getIdToken(true);
    } catch (_) {
      await signOut();
      return null;
    }

    final user = await _getUserFromFirestore(firebaseUser.uid);
    if (user != null) {
      await _sessionStorage.saveUser(user);
      return user;
    }
    return _sessionStorage.loadUser();
  }

  Future<UserModel> updateUserName(String newName) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) throw AppException(message: 'Nenhum usuário logado');

    await firebaseUser.updateDisplayName(newName);
    await _db.collection('users').doc(firebaseUser.uid).update({'name': newName});

    final updated = await _getUserFromFirestore(firebaseUser.uid);
    if (updated == null) throw AppException(message: 'Erro ao buscar usuário atualizado');
    await _sessionStorage.saveUser(updated);
    return updated;
  }

  Future<UserModel> updateUserProfile({
    required String name,
    String? phone,
    DateTime? birthday,
  }) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) throw AppException(message: 'Nenhum usuário logado');

    await firebaseUser.updateDisplayName(name);

    final data = <String, dynamic>{'name': name};
    if (phone != null) data['phone'] = phone;
    if (birthday != null) {
      data['birthday'] = Timestamp.fromDate(birthday);
    }
    await _db.collection('users').doc(firebaseUser.uid).update(data);

    final updated = await _getUserFromFirestore(firebaseUser.uid);
    if (updated == null) throw AppException(message: 'Erro ao buscar usuário atualizado');
    await _sessionStorage.saveUser(updated);
    return updated;
  }

  Future<UserModel> assignChurch(String userId, String churchId, UserRole role) async {
    await _db.collection('users').doc(userId).update({
      'churchId': churchId,
      'role': role.name,
      'status': 'active',
    });
    final updated = await _getUserFromFirestore(userId);
    if (updated == null) throw AppException(message: 'Erro ao atualizar usuário');
    await _sessionStorage.saveUser(updated);
    return updated;
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw AppException(message: 'Nenhum usuário logado');

    try {
      await _db.collection('users').doc(user.uid).delete();
    } catch (_) {}

    await user.delete();
    await _sessionStorage.clear();
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<UserModel?> _getUserFromFirestore(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      final data = doc.data()!;
      data['id'] = doc.id;
      return UserModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<UserModel> _getOrCreateUser(User firebaseUser) async {
    var user = await _getUserFromFirestore(firebaseUser.uid);
    if (user == null) {
      user = UserModel(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ??
            firebaseUser.email?.split('@').first ??
            'Usuário',
        email: firebaseUser.email ?? '',
        role: UserRole.member,
        status: UserStatus.pending,
      );
      await _createUserInFirestore(user);
    }
    return user;
  }

  Future<void> _createUserInFirestore(UserModel user) async {
    final data = user.toJson();
    data['id'] = user.id;
    await _db.collection('users').doc(user.id).set(data);
  }

  Future<void> _saveFcmToken(String userId) async {
    try {
      final fcmToken = NotificationService().fcmToken;
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await _db.collection('users').doc(userId).update({'fcmToken': fcmToken});
      }
    } catch (_) {}
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email ou senha incorretos';
      case 'email-already-in-use':
        return 'Este email já está em uso';
      case 'weak-password':
        return 'A senha deve ter pelo menos 6 caracteres';
      case 'invalid-email':
        return 'Email inválido';
      case 'user-disabled':
        return 'Usuário desabilitado';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde';
      default:
        return 'Erro de autenticação: ${e.message ?? 'Erro desconhecido'}';
    }
  }
}
