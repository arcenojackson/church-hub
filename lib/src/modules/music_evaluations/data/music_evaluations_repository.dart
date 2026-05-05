import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/config/firebase_config.dart';
import '../../../core/utils/app_exception.dart';
import '../models/evaluation_models.dart';

class MusicEvaluationsRepository {
  MusicEvaluationsRepository({required this.churchId});

  final String churchId;
  final FirebaseFirestore _db = FirebaseConfig.firestore;

  CollectionReference get _base =>
      _db.collection('churches').doc(churchId).collection('evaluations');

  // Categories
  Stream<List<EvaluationCategoryModel>> watchCategories() {
    return _base.doc('categories').collection('list')
        .orderBy('name')
        .snapshots()
        .map((q) => q.docs.map(EvaluationCategoryModel.fromFirestore).toList());
  }

  Future<List<EvaluationCategoryModel>> fetchCategories() async {
    final q = await _base.doc('categories').collection('list').orderBy('name').get();
    return q.docs.map(EvaluationCategoryModel.fromFirestore).toList();
  }

  Future<void> createCategory({
    required String name,
    required String description,
    String? documentPath,
  }) async {
    await _base.doc('categories').collection('list').add({
      'name': name,
      'description': description,
      if (documentPath != null) 'documentPath': documentPath,
    });
  }

  // Forms
  Stream<List<EvaluationFormModel>> watchForms() {
    return _base.doc('forms').collection('list')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((q) => q.docs.map(EvaluationFormModel.fromFirestore).toList());
  }

  Future<EvaluationFormModel> createForm({
    required String title,
    required String musicId,
    required String musicTitle,
    required String categoryId,
    List<String> allowedUserIds = const [],
  }) async {
    try {
      final ref = _base.doc('forms').collection('list').doc();
      final form = EvaluationFormModel(
        id: ref.id,
        title: title,
        musicId: musicId,
        musicTitle: musicTitle,
        categoryId: categoryId,
        createdAt: DateTime.now(),
        allowedUserIds: allowedUserIds,
      );
      await ref.set(form.toJson());
      return form;
    } catch (e) {
      throw AppException(message: 'Erro ao criar formulário: ${e.toString()}');
    }
  }

  Future<void> updateFormPermissions(
    String formId,
    List<String> allowedUserIds,
  ) async {
    await _base.doc('forms').collection('list').doc(formId).update({
      'allowedUserIds': allowedUserIds,
    });
  }

  Future<void> closeForm(String formId) async {
    await _base.doc('forms').collection('list').doc(formId).update({
      'isOpen': false,
    });
  }

  // Responses
  Stream<List<EvaluationResponseModel>> watchResponses(String formId) {
    return _base.doc('responses').collection(formId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((q) => q.docs.map(EvaluationResponseModel.fromFirestore).toList());
  }

  Future<void> submitResponse({
    required String formId,
    required String userId,
    required String userName,
    required Map<String, int> ratings,
    String? comment,
  }) async {
    try {
      // Verificar se já respondeu
      final existing = await _base.doc('responses').collection(formId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        throw AppException(message: 'Você já avaliou esta música');
      }

      await _base.doc('responses').collection(formId).add(
        EvaluationResponseModel(
          id: '',
          formId: formId,
          userId: userId,
          userName: userName,
          ratings: ratings,
          createdAt: DateTime.now(),
          comment: comment,
        ).toJson(),
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Erro ao enviar avaliação: ${e.toString()}');
    }
  }
}
