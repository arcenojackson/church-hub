import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarEventModel {
  const CalendarEventModel({
    required this.id,
    required this.churchId,
    required this.name,
    required this.date,
    required this.category,
    this.start = '00:00',
    this.sourceCollection,
  });

  final String id;
  final String churchId;
  final String name;
  final DateTime date;
  final String category;
  final String start;
  /// 'events_calendar' = calendar event. 'events' = planning event (Planejar).
  final String? sourceCollection;

  factory CalendarEventModel.fromFirestore(DocumentSnapshot doc, String churchId) {
    final data = doc.data() as Map<String, dynamic>;
    return CalendarEventModel(
      id: doc.id,
      churchId: churchId,
      name: data['name']?.toString() ?? '',
      date: data['date'] is Timestamp
          ? (data['date'] as Timestamp).toDate()
          : DateTime.now(),
      category: data['category']?.toString() ?? 'Geral',
      start: data['start']?.toString() ?? '00:00',
      sourceCollection: 'events_calendar',
    );
  }

  factory CalendarEventModel.fromJson(Map<String, dynamic> json, String churchId) {
    return CalendarEventModel(
      id: json['id']?.toString() ?? '',
      churchId: churchId,
      name: json['name']?.toString() ?? '',
      date: _parseDate(json['date']),
      category: json['category']?.toString() ?? 'Geral',
      start: json['start']?.toString() ?? '00:00',
      sourceCollection: json['sourceCollection']?.toString(),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  static int _startToMinutes(String start) {
    final parts = start.split(':');
    if (parts.length < 2) return 0;
    final h = int.tryParse(parts[0].trim()) ?? 0;
    final m = int.tryParse(parts[1].trim()) ?? 0;
    return h * 60 + m;
  }

  static int compareByDateAndTime(CalendarEventModel a, CalendarEventModel b) {
    final aDay = DateTime(a.date.year, a.date.month, a.date.day);
    final bDay = DateTime(b.date.year, b.date.month, b.date.day);
    final dateCompare = aDay.compareTo(bDay);
    if (dateCompare != 0) return dateCompare;
    return _startToMinutes(a.start).compareTo(_startToMinutes(b.start));
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'date': Timestamp.fromDate(date),
        'category': category,
        'start': start,
      };

  CalendarEventModel copyWith({
    String? id,
    String? name,
    DateTime? date,
    String? category,
    String? start,
    String? sourceCollection,
  }) {
    return CalendarEventModel(
      id: id ?? this.id,
      churchId: churchId,
      name: name ?? this.name,
      date: date ?? this.date,
      category: category ?? this.category,
      start: start ?? this.start,
      sourceCollection: sourceCollection ?? this.sourceCollection,
    );
  }
}
