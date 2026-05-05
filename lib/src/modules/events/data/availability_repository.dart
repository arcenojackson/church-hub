import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/config/firebase_config.dart';
import '../../../core/utils/app_exception.dart';

class AvailabilityRepository {
  AvailabilityRepository({required this.churchId});

  final String churchId;
  final FirebaseFirestore _db = FirebaseConfig.firestore;

  Future<List<DateTime>> fetchForUser(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (!doc.exists) return [];
      final raw = doc.data()?['availability'] as List<dynamic>? ?? [];
      return raw.map((t) {
        if (t is Timestamp) return t.toDate();
        return DateTime.now();
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveForUser(String userId, List<DateTime> dates) async {
    try {
      final timestamps = dates.map((d) => Timestamp.fromDate(d)).toList();
      await _db.collection('users').doc(userId).update({
        'availability': timestamps,
      });
    } catch (e) {
      throw AppException(message: 'Erro ao salvar disponibilidade: ${e.toString()}');
    }
  }

  // Busca disponibilidade de todos os membros da igreja para um dado mês
  Future<Map<String, List<DateTime>>> fetchAllForMonth(int year, int month) async {
    try {
      final start = DateTime(year, month, 1);
      final end = DateTime(year, month + 1, 0, 23, 59, 59);

      final usersSnap = await _db
          .collection('users')
          .where('churchId', isEqualTo: churchId)
          .where('status', isEqualTo: 'active')
          .get();

      final result = <String, List<DateTime>>{};
      for (final userDoc in usersSnap.docs) {
        final raw = userDoc.data()['availability'] as List<dynamic>? ?? [];
        final dates = raw
            .map((t) => t is Timestamp ? t.toDate() : null)
            .where((d) => d != null && d.isAfter(start) && d.isBefore(end))
            .cast<DateTime>()
            .toList();
        if (dates.isNotEmpty) result[userDoc.id] = dates;
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  // Conta quantos membros estão disponíveis para cada domingo de um mês
  Future<Map<DateTime, int>> countAvailabilityByDay(int year, int month) async {
    final allAvailability = await fetchAllForMonth(year, month);
    final counts = <DateTime, int>{};

    for (final dates in allAvailability.values) {
      for (final date in dates) {
        if (date.weekday == DateTime.sunday) {
          final key = DateTime(date.year, date.month, date.day);
          counts[key] = (counts[key] ?? 0) + 1;
        }
      }
    }

    return counts;
  }
}
