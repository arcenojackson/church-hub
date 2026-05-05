import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/notification_type.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<String>> getDisabledNotifications(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        final disabled = doc.data()!['disabled_notifications'];
        if (disabled is List) {
          return disabled.map((e) => e.toString()).toList();
        }
      }
      return [];
    } catch (e) {
      throw Exception('Erro ao buscar configurações de notificação: $e');
    }
  }

  Future<void> enableNotification(String userId, NotificationType type) async {
    try {
      final docRef = _firestore.collection('users').doc(userId);
      final doc = await docRef.get();
      if (doc.exists && doc.data() != null) {
        final disabled = (doc.data()!['disabled_notifications'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        final updated = disabled.where((id) => id != type.id).toList();
        await docRef.update({
          'disabled_notifications': updated.isEmpty ? FieldValue.delete() : updated,
        });
      }
    } catch (e) {
      throw Exception('Erro ao habilitar notificação: $e');
    }
  }

  Future<void> disableNotification(String userId, NotificationType type) async {
    try {
      final docRef = _firestore.collection('users').doc(userId);
      final doc = await docRef.get();
      if (doc.exists && doc.data() != null) {
        final disabled = (doc.data()!['disabled_notifications'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        if (!disabled.contains(type.id)) disabled.add(type.id);
        await docRef.update({'disabled_notifications': disabled});
      } else {
        await docRef.set(
          {'disabled_notifications': [type.id]},
          SetOptions(merge: true),
        );
      }
    } catch (e) {
      throw Exception('Erro ao desabilitar notificação: $e');
    }
  }
}
