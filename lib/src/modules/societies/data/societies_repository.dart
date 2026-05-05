import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/config/firebase_config.dart';
import '../../../core/utils/app_exception.dart';
import '../models/society_model.dart';

class SocietiesRepository {
  SocietiesRepository({required this.churchId});

  final String churchId;
  final FirebaseFirestore _db = FirebaseConfig.firestore;

  CollectionReference get _societies =>
      _db.collection('churches').doc(churchId).collection('societies');

  Stream<List<SocietyModel>> watchAll() {
    return _societies
        .orderBy('name')
        .snapshots()
        .map((q) => q.docs
            .map((d) => SocietyModel.fromFirestore(d, churchId))
            .toList());
  }

  Future<List<SocietyModel>> fetchAll() async {
    final q = await _societies.orderBy('name').get();
    return q.docs.map((d) => SocietyModel.fromFirestore(d, churchId)).toList();
  }

  Future<SocietyModel?> fetchById(String societyId) async {
    final doc = await _societies.doc(societyId).get();
    if (!doc.exists) return null;
    return SocietyModel.fromFirestore(doc, churchId);
  }

  Stream<SocietyModel?> watchById(String societyId) {
    return _societies.doc(societyId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return SocietyModel.fromFirestore(doc, churchId);
    });
  }

  Future<SocietyModel> create({
    required String name,
    required String description,
    required int color,
    required String userId,
    List<String> membersIds = const [],
  }) async {
    try {
      final ref = _societies.doc();
      final society = SocietyModel(
        id: ref.id,
        churchId: churchId,
        name: name,
        description: description,
        color: color,
        userId: userId,
        membersIds: membersIds,
      );
      await ref.set(society.toJson());
      return society;
    } catch (e) {
      throw AppException(message: 'Erro ao criar sociedade: ${e.toString()}');
    }
  }

  Future<void> update(String societyId, Map<String, dynamic> data) async {
    try {
      await _societies.doc(societyId).update(data);
    } catch (e) {
      throw AppException(message: 'Erro ao atualizar sociedade: ${e.toString()}');
    }
  }

  Future<void> delete(String societyId) async {
    try {
      await _societies.doc(societyId).delete();
    } catch (e) {
      throw AppException(message: 'Erro ao deletar sociedade: ${e.toString()}');
    }
  }

  Future<void> addMember(String societyId, String userId) async {
    await _societies.doc(societyId).update({
      'membersIds': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> removeMember(String societyId, String userId) async {
    await _societies.doc(societyId).update({
      'membersIds': FieldValue.arrayRemove([userId]),
    });
  }

  Future<void> addLeader(String societyId, String userId) async {
    try {
      await _societies.doc(societyId).update({
        'leadersIds': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      throw AppException(message: 'Erro ao adicionar líder: ${e.toString()}');
    }
  }

  Future<void> removeLeader(String societyId, String userId) async {
    try {
      await _societies.doc(societyId).update({
        'leadersIds': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      throw AppException(message: 'Erro ao remover líder: ${e.toString()}');
    }
  }

  Future<void> setBoardMember(
      String societyId, String positionId, List<String> userIds) async {
    await _societies.doc(societyId).update({
      'boardWithPositions.$positionId': userIds,
    });
  }
}
