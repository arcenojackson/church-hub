import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/firebase_config.dart';
import '../../../core/utils/app_exception.dart';
import '../models/holyrics_model.dart';

class HolyricsRepository {
  HolyricsRepository({required this.churchId});

  final String churchId;
  final FirebaseFirestore _db = FirebaseConfig.firestore;

  CollectionReference get _configs =>
      _db.collection('churches').doc(churchId).collection('holyrics_config');

  Future<HolyricsConfigModel?> fetchConfig() async {
    try {
      final q = await _configs.limit(1).get();
      if (q.docs.isEmpty) return null;
      return HolyricsConfigModel.fromFirestore(q.docs.first, churchId);
    } catch (_) {
      return null;
    }
  }

  Future<HolyricsConfigModel> saveConfig({
    required String ipAddress,
    required int port,
    String? token,
  }) async {
    try {
      final existing = await fetchConfig();
      final ref = existing != null
          ? _configs.doc(existing.id)
          : _configs.doc();

      final config = HolyricsConfigModel(
        id: ref.id,
        churchId: churchId,
        ipAddress: ipAddress,
        port: port,
        token: token,
      );
      await ref.set(config.toJson(), SetOptions(merge: true));
      return config;
    } catch (e) {
      throw AppException(message: 'Erro ao salvar config Holyrics: ${e.toString()}');
    }
  }

  Future<bool> testConnection(HolyricsConfigModel config) async {
    try {
      final response = await http
          .get(Uri.parse('${config.baseUrl}/api/v1/status'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> sendToPresentation(
    HolyricsConfigModel config,
    String text,
  ) async {
    try {
      await http.post(
        Uri.parse('${config.baseUrl}/api/v1/present'),
        body: {'text': text},
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      throw AppException(message: 'Erro ao enviar para Holyrics: ${e.toString()}');
    }
  }
}
