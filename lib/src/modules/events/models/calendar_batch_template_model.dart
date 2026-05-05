import 'package:cloud_firestore/cloud_firestore.dart';

/// Defines a recurring event pattern for batch creation.
/// dayOfWeek follows DateTime.weekday: 1=Monday … 7=Sunday.
class CalendarBatchTemplateModel {
  const CalendarBatchTemplateModel({
    required this.id,
    required this.churchId,
    required this.name,
    required this.dayOfWeek,
    required this.time,
    this.eventTemplateId,
    this.active = true,
    this.weekGroups = const {},
    this.steps = const [],
  });

  final String id;
  final String churchId;
  final String name;
  final int dayOfWeek; // 1=Mon … 7=Sun
  final String time;  // "HH:mm"
  final String? eventTemplateId;
  final bool active;
  /// weekNumber (1–4) → society/group id
  final Map<int, String> weekGroups;
  /// Ordered list of service steps: {title, type ('step'|'music'), duration (int)}
  final List<Map<String, dynamic>> steps;

  factory CalendarBatchTemplateModel.fromFirestore(
      DocumentSnapshot doc, String churchId) {
    final data = doc.data() as Map<String, dynamic>;
    final rawGroups = data['weekGroups'];
    final weekGroups = <int, String>{};
    if (rawGroups is Map) {
      rawGroups.forEach((k, v) {
        final week = int.tryParse(k.toString());
        if (week != null && v is String && v.isNotEmpty) {
          weekGroups[week] = v;
        }
      });
    }
    final rawSteps = data['steps'];
    final steps = (rawSteps is List)
        ? rawSteps.whereType<Map<String, dynamic>>().toList()
        : <Map<String, dynamic>>[];

    return CalendarBatchTemplateModel(
      id: doc.id,
      churchId: churchId,
      name: data['name']?.toString() ?? '',
      dayOfWeek: (data['dayOfWeek'] as int?) ?? 7,
      time: data['time']?.toString() ?? '00:00',
      eventTemplateId: data['eventTemplateId']?.toString(),
      active: (data['active'] as bool?) ?? true,
      weekGroups: weekGroups,
      steps: steps,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'dayOfWeek': dayOfWeek,
        'time': time,
        if (eventTemplateId != null && eventTemplateId!.isNotEmpty)
          'eventTemplateId': eventTemplateId,
        'active': active,
        'weekGroups': weekGroups.map((k, v) => MapEntry(k.toString(), v)),
        'steps': steps,
      };

  CalendarBatchTemplateModel copyWith({
    String? name,
    int? dayOfWeek,
    String? time,
    String? eventTemplateId,
    bool? active,
    Map<int, String>? weekGroups,
    List<Map<String, dynamic>>? steps,
  }) {
    return CalendarBatchTemplateModel(
      id: id,
      churchId: churchId,
      name: name ?? this.name,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      time: time ?? this.time,
      eventTemplateId: eventTemplateId ?? this.eventTemplateId,
      active: active ?? this.active,
      weekGroups: weekGroups ?? this.weekGroups,
      steps: steps ?? this.steps,
    );
  }

  static String dayOfWeekLabel(int day) {
    const labels = {
      1: 'Segunda-feira',
      2: 'Terça-feira',
      3: 'Quarta-feira',
      4: 'Quinta-feira',
      5: 'Sexta-feira',
      6: 'Sábado',
      7: 'Domingo',
    };
    return labels[day] ?? 'Desconhecido';
  }
}
