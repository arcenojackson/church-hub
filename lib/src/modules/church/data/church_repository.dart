import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/config/firebase_config.dart';
import '../../../core/utils/app_exception.dart';
import '../models/church_model.dart';
import '../models/church_settings_model.dart';
import '../models/church_subscription_model.dart';

class ChurchRepository {
  final FirebaseFirestore _db = FirebaseConfig.firestore;

  CollectionReference get _churches => _db.collection('churches');

  Future<ChurchModel> createChurch({
    required String name,
    required int accentColor,
    String? logo,
    String? city,
    String? state,
    String? description,
  }) async {
    try {
      final ref = _churches.doc();
      final church = ChurchModel(
        id: ref.id,
        name: name,
        accentColor: accentColor,
        tier: 'free',
        createdAt: DateTime.now(),
        setupCompleted: false,
        logo: logo,
        city: city,
        state: state,
        description: description,
      );
      await ref.set({...church.toJson(), 'inviteCode': church.inviteCode});
      await _inviteCodes.doc(church.inviteCode).set({'churchId': church.id});
      return church;
    } catch (e) {
      throw AppException(message: 'Erro ao criar igreja: ${e.toString()}');
    }
  }

  Future<ChurchModel?> fetchChurch(String churchId) async {
    try {
      final doc = await _churches.doc(churchId).get();
      if (!doc.exists || doc.data() == null) return null;
      return ChurchModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      throw AppException(message: 'Erro ao buscar igreja: ${e.toString()}');
    }
  }

  Stream<ChurchModel?> watchChurch(String churchId) {
    return _churches.doc(churchId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return ChurchModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  Future<void> updateChurch(String churchId, Map<String, dynamic> data) async {
    try {
      await _churches.doc(churchId).update(data);
    } catch (e) {
      throw AppException(message: 'Erro ao atualizar igreja: ${e.toString()}');
    }
  }

  Future<void> completeSetup(String churchId) async {
    await updateChurch(churchId, {'setupCompleted': true});
  }

  Future<ChurchSettingsModel?> fetchSettings(String churchId) async {
    try {
      final doc = await _churches.doc(churchId).collection('settings').doc('config').get();
      if (!doc.exists || doc.data() == null) {
        return ChurchSettingsModel(churchId: churchId);
      }
      return ChurchSettingsModel.fromJson(doc.data()!, churchId);
    } catch (e) {
      return ChurchSettingsModel(churchId: churchId);
    }
  }

  Stream<ChurchSettingsModel> watchSettings(String churchId) {
    return _churches
        .doc(churchId)
        .collection('settings')
        .doc('config')
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) {
        return ChurchSettingsModel(churchId: churchId);
      }
      return ChurchSettingsModel.fromJson(doc.data()!, churchId);
    });
  }

  Future<void> saveSettings(String churchId, ChurchSettingsModel settings) async {
    try {
      await _churches
          .doc(churchId)
          .collection('settings')
          .doc('config')
          .set(settings.toJson(), SetOptions(merge: true));
    } catch (e) {
      throw AppException(message: 'Erro ao salvar configurações: ${e.toString()}');
    }
  }

  Future<ChurchSubscriptionModel?> fetchSubscription(String churchId) async {
    try {
      final doc = await _churches.doc(churchId).collection('subscription').doc('current').get();
      if (!doc.exists || doc.data() == null) {
        return ChurchSubscriptionModel.defaultFree(churchId);
      }
      return ChurchSubscriptionModel.fromJson(doc.data()!, churchId);
    } catch (e) {
      return ChurchSubscriptionModel.defaultFree(churchId);
    }
  }

  CollectionReference get _inviteCodes => _db.collection('invite_codes');

  Future<void> generateInviteCode(String churchId) async {
    final code = churchId.substring(0, 8).toUpperCase();
    await updateChurch(churchId, {'inviteCode': code});
    await _inviteCodes.doc(code).set({'churchId': churchId});
  }

  /// Returns the churchId for the given invite code, or null if not found.
  /// Reads from the top-level `invite_codes` collection which allows any
  /// authenticated user to read, bypassing the church membership restriction.
  Future<String?> findChurchIdByInviteCode(String code) async {
    try {
      final doc = await _inviteCodes.doc(code.toUpperCase()).get();
      if (!doc.exists || doc.data() == null) return null;
      return (doc.data() as Map<String, dynamic>)['churchId'] as String?;
    } catch (e) {
      return null;
    }
  }
}
