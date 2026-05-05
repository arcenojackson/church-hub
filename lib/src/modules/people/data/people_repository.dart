import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/config/firebase_config.dart';
import '../../../core/utils/app_exception.dart';
import '../../auth/models/user_model.dart';

class PeopleRepository {
  PeopleRepository({required this.churchId});

  final String churchId;
  final FirebaseFirestore _db = FirebaseConfig.firestore;

  Stream<List<UserModel>> watchMembers() {
    return _db
        .collection('users')
        .where('churchId', isEqualTo: churchId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((q) => q.docs.map(_fromDoc).toList());
  }

  Future<List<UserModel>> fetchMembers() async {
    final q = await _db
        .collection('users')
        .where('churchId', isEqualTo: churchId)
        .where('status', isEqualTo: 'active')
        .get();
    return q.docs.map(_fromDoc).toList();
  }

  Future<UserModel?> fetchById(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return _fromDoc(doc);
  }

  Future<void> updateAvailability(String userId, List<DateTime> availability) async {
    try {
      final timestamps = availability
          .map((d) => Timestamp.fromDate(d))
          .toList();
      await _db.collection('users').doc(userId).update({
        'availability': timestamps,
      });
    } catch (e) {
      throw AppException(message: 'Erro ao atualizar disponibilidade: ${e.toString()}');
    }
  }

  Future<void> updateDisabledNotifications(
    String userId,
    List<String> disabledIds,
  ) async {
    await _db.collection('users').doc(userId).update({
      'disabledNotifications': disabledIds,
    });
  }

  Future<void> disableMember(String userId) async {
    await _db.collection('users').doc(userId).update({'status': 'disabled'});
  }

  Future<void> removeMemberFromChurch(String userId) async {
    await _db.collection('users').doc(userId).update({
      'churchId': null,
      'status': 'pending',
    });
  }

  Stream<List<UserModel>> watchPendingMembers() {
    return _db
        .collection('users')
        .where('churchId', isEqualTo: churchId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((q) => q.docs.map(_fromDoc).toList());
  }

  Future<void> approveUser(String userId, String profileId) async {
    await _db.collection('users').doc(userId).update({
      'status': 'active',
      'profileId': profileId,
    });
  }

  Future<void> updateMemberProfile(String userId, String profileId) async {
    await _db.collection('users').doc(userId).update({
      'profileId': profileId,
    });
  }

  Future<int> countPendingMembers() async {
    try {
      final snap = await _db
          .collection('users')
          .where('churchId', isEqualTo: churchId)
          .where('status', isEqualTo: 'pending')
          .count()
          .get();
      return snap.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  UserModel _fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return UserModel.fromJson(data);
  }
}
