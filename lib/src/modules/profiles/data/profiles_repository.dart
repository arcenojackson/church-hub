// lib/src/modules/profiles/data/profiles_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/config/firebase_config.dart';
import '../../../shared/permissions/app_permission.dart';
import '../models/profile_model.dart';

class ProfilesRepository {
  ProfilesRepository({required this.churchId});

  final String churchId;
  final FirebaseFirestore _db = FirebaseConfig.firestore;

  Stream<List<ProfileModel>> watchProfiles() {
    return _db
        .collection('churches')
        .doc(churchId)
        .collection('profiles')
        .snapshots()
        .asyncMap((snap) async {
      if (snap.docs.isEmpty && churchId.isNotEmpty) {
        // Primeira vez: seed automático
        await seedDefaultProfiles();
        return _defaultProfiles();
      }
      return snap.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return ProfileModel.fromJson(data);
      }).toList();
    });
  }

  Future<ProfileModel?> fetchProfile(String profileId) async {
    final doc = await _db
        .collection('churches')
        .doc(churchId)
        .collection('profiles')
        .doc(profileId)
        .get();
    if (!doc.exists) return null;
    final data = Map<String, dynamic>.from(doc.data()!);
    data['id'] = doc.id;
    return ProfileModel.fromJson(data);
  }

  Future<void> saveProfile(ProfileModel profile) async {
    final ref = profile.id.isEmpty
        ? _db.collection('churches').doc(churchId).collection('profiles').doc()
        : _db
            .collection('churches')
            .doc(churchId)
            .collection('profiles')
            .doc(profile.id);
    await ref.set(profile.toJson());
  }

  Future<void> deleteProfile(String profileId) async {
    await _db
        .collection('churches')
        .doc(churchId)
        .collection('profiles')
        .doc(profileId)
        .delete();
  }

  Future<void> seedDefaultProfiles() async {
    final batch = _db.batch();
    final base = _db
        .collection('churches')
        .doc(churchId)
        .collection('profiles');

    batch.set(base.doc('admin'), {
      'name': 'Admin',
      'isAdminRole': true,
      'isDefault': false,
      'permissions': <String, bool>{},
    });

    batch.set(base.doc('member'), {
      'name': 'Membro',
      'isAdminRole': false,
      'isDefault': true,
      'permissions': AppPermission.memberDefaults,
    });

    await batch.commit();
  }

  List<ProfileModel> _defaultProfiles() => [
    ProfileModel(
      id: 'admin',
      name: 'Admin',
      permissions: {},
      isAdminRole: true,
    ),
    ProfileModel(
      id: 'member',
      name: 'Membro',
      permissions: AppPermission.memberDefaults,
      isDefault: true,
    ),
  ];
}
