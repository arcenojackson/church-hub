import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/config/firebase_config.dart';
import '../../../core/utils/app_exception.dart';
import '../models/calendar_event_model.dart';
import '../models/event_model.dart';

class EventsRepository {
  EventsRepository({required this.churchId});

  final String churchId;
  final FirebaseFirestore _db = FirebaseConfig.firestore;

  CollectionReference get _events =>
      _db.collection('churches').doc(churchId).collection('events');

  CollectionReference get _templates =>
      _db.collection('churches').doc(churchId).collection('templates');

  // --- EVENTS ---

  Stream<List<EventModel>> watchUpcoming() {
    final now = DateTime.now();
    return _events
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(
            DateTime(now.year, now.month, now.day)))
        .orderBy('date')
        .limit(50)
        .snapshots()
        .map((q) => q.docs.map(_fromDoc).toList());
  }

  Stream<List<EventModel>> watchAll() {
    return _events
        .orderBy('date', descending: true)
        .snapshots()
        .map((q) => q.docs.map(_fromDoc).toList());
  }

  Future<EventModel?> fetchById(String eventId) async {
    try {
      final doc = await _events.doc(eventId).get();
      if (!doc.exists) return null;
      return _fromDoc(doc);
    } catch (_) {
      return null;
    }
  }

  Future<List<EventModel>> fetchUpcoming() async {
    final now = DateTime.now();
    final q = await _events
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(
            DateTime(now.year, now.month, now.day)))
        .orderBy('date')
        .limit(50)
        .get();
    return q.docs.map(_fromDoc).toList();
  }

  Future<List<EventModel>> fetchPast() async {
    final now = DateTime.now();
    final q = await _events
        .where('date', isLessThan: Timestamp.fromDate(
            DateTime(now.year, now.month, now.day)))
        .orderBy('date', descending: true)
        .limit(50)
        .get();
    return q.docs.map(_fromDoc).toList();
  }

  Future<List<EventModel>> fetchForUser(String userId) async {
    final all = await fetchUpcoming();
    return all.where((e) => e.isUserAssigned(userId)).toList();
  }

  Future<EventModel> createEvent({
    required String name,
    required DateTime date,
    required String start,
    String? templateId,
    List<EventStepModel>? steps,
    String? societyId,
  }) async {
    try {
      final ref = _events.doc();
      final event = EventModel(
        id: ref.id,
        churchId: churchId,
        name: name,
        date: date,
        start: start,
        templateId: templateId,
        steps: steps ?? const [],
        societyId: societyId,
      );
      await ref.set(event.toJson());
      return event;
    } catch (e) {
      throw AppException(message: 'Erro ao criar evento: ${e.toString()}');
    }
  }

  Future<void> updateEvent(String eventId, {
    String? name,
    DateTime? date,
    String? start,
    List<EventStepModel>? steps,
    Map<String, List<String>>? people,
    Map<String, String>? teams,
    String? templateId,
    String? societyId,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (date != null) data['date'] = Timestamp.fromDate(date);
    if (start != null) data['start'] = start;
    if (steps != null) data['steps'] = steps.map((s) => s.toJson()).toList();
    if (people != null) data['people'] = people;
    if (teams != null) data['teams'] = teams;
    if (templateId != null) data['templateId'] = templateId;
    if (societyId != null) data['societyId'] = societyId;

    try {
      await _events.doc(eventId).update(data);
    } catch (e) {
      throw AppException(message: 'Erro ao atualizar evento: ${e.toString()}');
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await _events.doc(eventId).delete();
    } catch (e) {
      throw AppException(message: 'Erro ao deletar evento: ${e.toString()}');
    }
  }

  // --- TEMPLATES ---

  Stream<List<EventTemplateModel>> watchTemplates() {
    return _templates
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((q) => q.docs.map(_templateFromDoc).toList());
  }

  Future<List<EventTemplateModel>> fetchTemplates() async {
    final q = await _templates.orderBy('createdAt', descending: true).get();
    return q.docs.map(_templateFromDoc).toList();
  }

  Future<EventTemplateModel> createTemplate({
    required String name,
    required List<EventStepModel> steps,
    required String userId,
  }) async {
    final ref = _templates.doc();
    final template = EventTemplateModel(
      id: ref.id,
      name: name,
      steps: steps,
      userId: userId,
      createdAt: DateTime.now(),
    );
    await ref.set(template.toJson());
    return template;
  }

  Future<void> updateTemplate(String templateId, String name, List<EventStepModel> steps) async {
    await _templates.doc(templateId).update({
      'name': name,
      'steps': steps.map((s) => s.toJson()).toList(),
    });
  }

  Future<void> deleteTemplate(String templateId) async {
    await _templates.doc(templateId).delete();
  }

  EventModel _fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    data['churchId'] = churchId;
    return EventModel.fromJson(data);
  }

  EventTemplateModel _templateFromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return EventTemplateModel.fromJson(data);
  }

  // --- CALENDAR EVENTS (events_calendar) ---

  CollectionReference get _calendarEvents =>
      _db.collection('churches').doc(churchId).collection('events_calendar');

  Future<CalendarEventModel> createCalendarEvent({
    required String name,
    required DateTime date,
    required String category,
    String start = '00:00',
  }) async {
    try {
      final ref = _calendarEvents.doc();
      final data = {
        'name': name,
        'date': Timestamp.fromDate(date),
        'category': category,
        'start': start,
      };
      await ref.set(data);
      final doc = await ref.get();
      return CalendarEventModel.fromFirestore(doc, churchId);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Erro ao criar evento: ${e.toString()}');
    }
  }

  Future<CalendarEventModel> updateCalendarEvent({
    required String id,
    required String name,
    required DateTime date,
    required String category,
    String start = '00:00',
  }) async {
    try {
      await _calendarEvents.doc(id).update({
        'name': name,
        'date': Timestamp.fromDate(date),
        'category': category,
        'start': start,
      });
      final doc = await _calendarEvents.doc(id).get();
      return CalendarEventModel.fromFirestore(doc, churchId);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Erro ao atualizar evento: ${e.toString()}');
    }
  }

  Future<void> deleteCalendarEvent(String id) async {
    try {
      await _calendarEvents.doc(id).delete();
    } catch (e) {
      throw AppException(message: 'Erro ao excluir evento: ${e.toString()}');
    }
  }

  Future<List<CalendarEventModel>> _fetchCalendarEventsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final snap = await _calendarEvents.get();
    final startNorm = DateTime(start.year, start.month, start.day);
    final endNorm = DateTime(end.year, end.month, end.day);
    final events = snap.docs
        .map((doc) => CalendarEventModel.fromFirestore(doc, churchId))
        .where((e) {
          final d = DateTime(e.date.year, e.date.month, e.date.day);
          return d.compareTo(startNorm) >= 0 && d.compareTo(endNorm) <= 0;
        })
        .toList();
    events.sort(CalendarEventModel.compareByDateAndTime);
    return events;
  }

  Future<List<CalendarEventModel>> fetchCalendarEventsByDate(DateTime date) async {
    return _fetchCalendarEventsByDateRange(
      DateTime(date.year, date.month, date.day),
      DateTime(date.year, date.month, date.day, 23, 59, 59),
    );
  }

  Future<List<CalendarEventModel>> fetchAllEventsForCalendar() async {
    try {
      final calSnap = await _calendarEvents.get();
      final calEvents = calSnap.docs
          .map((doc) => CalendarEventModel.fromFirestore(doc, churchId))
          .toList();

      final planSnap = await _events.get();
      final planEvents = planSnap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return CalendarEventModel(
          id: doc.id,
          churchId: churchId,
          name: data['name']?.toString() ?? '',
          date: data['date'] is Timestamp
              ? (data['date'] as Timestamp).toDate()
              : DateTime.now(),
          category: 'Geral',
          start: data['start']?.toString() ?? '00:00',
          sourceCollection: 'events',
        );
      }).where((pe) {
        // deduplicate: skip if there's already a calendar event with same name/date/time
        return !calEvents.any((ce) =>
            ce.name == pe.name &&
            ce.date.year == pe.date.year &&
            ce.date.month == pe.date.month &&
            ce.date.day == pe.date.day &&
            ce.start == pe.start);
      }).toList();

      final combined = [...calEvents, ...planEvents];
      combined.sort(CalendarEventModel.compareByDateAndTime);
      return combined;
    } catch (e) {
      throw AppException(message: 'Erro ao carregar eventos: ${e.toString()}');
    }
  }

  Future<List<CalendarEventModel>> fetchCalendarEventsByCategories(
    List<String> categories,
  ) async {
    if (categories.isEmpty) return fetchAllEventsForCalendar();
    try {
      final snap = await _calendarEvents.get();
      final calEvents = snap.docs
          .map((doc) => CalendarEventModel.fromFirestore(doc, churchId))
          .where((e) => categories.contains(e.category))
          .toList();

      if (categories.contains('Geral')) {
        final planSnap = await _events.get();
        final planEvents = planSnap.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return CalendarEventModel(
            id: doc.id,
            churchId: churchId,
            name: data['name']?.toString() ?? '',
            date: data['date'] is Timestamp
                ? (data['date'] as Timestamp).toDate()
                : DateTime.now(),
            category: 'Geral',
            start: data['start']?.toString() ?? '00:00',
            sourceCollection: 'events',
          );
        }).toList();
        final combined = [...calEvents, ...planEvents];
        combined.sort(CalendarEventModel.compareByDateAndTime);
        return combined;
      }
      calEvents.sort(CalendarEventModel.compareByDateAndTime);
      return calEvents;
    } catch (e) {
      throw AppException(message: 'Erro ao carregar eventos: ${e.toString()}');
    }
  }

  Future<List<CalendarEventModel>> fetchAllEventsForCalendarInRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final startNorm = DateTime(start.year, start.month, start.day);
      final endNorm = DateTime(end.year, end.month, end.day);
      final calEvents = await _fetchCalendarEventsByDateRange(start, end);

      final planSnap = await _events.get();
      final planEvents = planSnap.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return CalendarEventModel(
              id: doc.id,
              churchId: churchId,
              name: data['name']?.toString() ?? '',
              date: data['date'] is Timestamp
                  ? (data['date'] as Timestamp).toDate()
                  : DateTime.now(),
              category: 'Geral',
              start: data['start']?.toString() ?? '00:00',
              sourceCollection: 'events',
            );
          })
          .where((e) {
            final d = DateTime(e.date.year, e.date.month, e.date.day);
            return d.compareTo(startNorm) >= 0 && d.compareTo(endNorm) <= 0;
          })
          .toList();

      final combined = [...calEvents, ...planEvents];
      combined.sort(CalendarEventModel.compareByDateAndTime);
      return combined;
    } catch (e) {
      throw AppException(message: 'Erro ao carregar eventos: ${e.toString()}');
    }
  }
}

class EventTemplateModel {
  const EventTemplateModel({
    required this.id,
    required this.name,
    required this.steps,
    required this.userId,
    required this.createdAt,
  });

  final String id;
  final String name;
  final List<EventStepModel> steps;
  final String userId;
  final DateTime createdAt;

  factory EventTemplateModel.fromJson(Map<String, dynamic> json) {
    return EventTemplateModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      steps: (json['steps'] as List<dynamic>? ?? [])
          .map((s) => EventStepModel.fromJson(s as Map<String, dynamic>))
          .toList(),
      userId: json['userId']?.toString() ?? '',
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'steps': steps.map((s) => s.toJson()).toList(),
    'userId': userId,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
