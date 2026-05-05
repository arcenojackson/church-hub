import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../../firebase_options.dart';

class FirebaseConfig {
  static FirebaseAuth? _auth;
  static FirebaseFirestore? _firestore;
  static FirebaseAnalytics? _analytics;
  static FirebaseCrashlytics? _crashlytics;
  static FirebaseStorage? _storage;

  static FirebaseAuth get auth => _auth!;
  static FirebaseFirestore get firestore => _firestore!;
  static FirebaseAnalytics get analytics => _analytics!;
  static FirebaseCrashlytics get crashlytics => _crashlytics!;
  static FirebaseStorage get storage => _storage!;

  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    _auth = FirebaseAuth.instance;
    _firestore = FirebaseFirestore.instance;
    _analytics = FirebaseAnalytics.instance;
    _crashlytics = FirebaseCrashlytics.instance;
    _storage = FirebaseStorage.instance;

    if (!kIsWeb) {
      await _crashlytics!.setCrashlyticsCollectionEnabled(!kDebugMode);
    }
    await _analytics!.setAnalyticsCollectionEnabled(!kDebugMode);

    _auth!.authStateChanges().listen((User? user) {
      if (kDebugMode) {
        if (user != null) {
          debugPrint('✅ Auth: ${user.email}');
        } else {
          debugPrint('🔒 Auth: signed out');
        }
      }
    });
  }

  static bool get isInitialized => _auth != null;
}
