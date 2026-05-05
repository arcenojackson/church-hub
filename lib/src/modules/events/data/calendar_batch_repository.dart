import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/config/firebase_config.dart';
import '../../../core/utils/app_exception.dart';
import '../models/calendar_batch_template_model.dart';

class CalendarBatchRepository {
  CalendarBatchRepository({required this.churchId});

  final String churchId;
  final FirebaseFirestore _db = FirebaseConfig.firestore;

  CollectionReference get _col =>
      _db.collection('churches').doc(churchId).collection('calendar_batch_templates');

  Future<List<CalendarBatchTemplateModel>> fetchAll() async {
    try {
      final snap = await _col.get();
      return snap.docs
          .map((doc) => CalendarBatchTemplateModel.fromFirestore(doc, churchId))
          .toList();
    } catch (e) {
      throw AppException(message: 'Erro ao buscar templates: ${e.toString()}');
    }
  }

  Future<CalendarBatchTemplateModel> create({
    required String name,
    required int dayOfWeek,
    required String time,
    String? eventTemplateId,
    bool active = true,
    Map<int, String> weekGroups = const {},
  }) async {
    try {
      final ref = _col.doc();
      final model = CalendarBatchTemplateModel(
        id: ref.id,
        churchId: churchId,
        name: name,
        dayOfWeek: dayOfWeek,
        time: time,
        eventTemplateId: eventTemplateId,
        active: active,
        weekGroups: weekGroups,
      );
      await ref.set(model.toJson());
      return model;
    } catch (e) {
      throw AppException(message: 'Erro ao criar template: ${e.toString()}');
    }
  }

  Future<void> update(CalendarBatchTemplateModel model) async {
    try {
      await _col.doc(model.id).update(model.toJson());
    } catch (e) {
      throw AppException(message: 'Erro ao atualizar template: ${e.toString()}');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _col.doc(id).delete();
    } catch (e) {
      throw AppException(message: 'Erro ao excluir template: ${e.toString()}');
    }
  }
}
