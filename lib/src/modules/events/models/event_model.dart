import 'package:cloud_firestore/cloud_firestore.dart';

enum EventStepType { step, music }

class EventStepModel {
  const EventStepModel({
    required this.title,
    required this.type,
    this.description,
    this.duration,
    this.musicId,
    this.musicTone,
  });

  final String title;
  final String? description;
  final int? duration;
  final EventStepType type;
  final String? musicId;
  final String? musicTone;

  factory EventStepModel.fromJson(Map<String, dynamic> json) {
    return EventStepModel(
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      duration: json['duration'] is int ? json['duration'] as int : int.tryParse(json['duration']?.toString() ?? ''),
      type: json['type'] == 'music' ? EventStepType.music : EventStepType.step,
      musicId: json['musicId']?.toString(),
      musicTone: json['musicTone']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    if (description != null) 'description': description,
    if (duration != null) 'duration': duration,
    'type': type.name,
    if (musicId != null) 'musicId': musicId,
    if (musicTone != null) 'musicTone': musicTone,
  };

  EventStepModel copyWith({
    String? title,
    String? description,
    int? duration,
    EventStepType? type,
    String? musicId,
    String? musicTone,
  }) {
    return EventStepModel(
      title: title ?? this.title,
      description: description ?? this.description,
      duration: duration ?? this.duration,
      type: type ?? this.type,
      musicId: musicId ?? this.musicId,
      musicTone: musicTone ?? this.musicTone,
    );
  }
}

// people: Map<roleId, List<userId>> — dinâmico, definido per-church
// teams: Map<teamTypeId, societyId> — dinâmico

class EventModel {
  const EventModel({
    required this.id,
    required this.churchId,
    required this.name,
    required this.date,
    required this.start,
    this.steps = const [],
    this.people = const {},
    this.teams = const {},
    this.templateId,
    this.societyId,
  });

  final String id;
  final String churchId;
  final String name;
  final DateTime date;
  final String start;
  final List<EventStepModel> steps;
  final Map<String, List<String>> people; // roleId → [userId, ...]
  final Map<String, String> teams; // teamTypeId → societyId
  final String? templateId;
  final String? societyId;

  List<String> get allPeopleIds {
    final ids = <String>{};
    for (final list in people.values) {
      ids.addAll(list);
    }
    return ids.toList();
  }

  bool isUserAssigned(String userId) => allPeopleIds.contains(userId);

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return EventModel.fromJson(data);
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    // Parse people map
    final people = <String, List<String>>{};
    final rawPeople = json['people'];
    if (rawPeople is Map) {
      rawPeople.forEach((key, val) {
        if (val is List) {
          people[key.toString()] = val.map((e) => e.toString()).toList();
        }
      });
    }

    // Parse teams map
    final teams = <String, String>{};
    final rawTeams = json['teams'];
    if (rawTeams is Map) {
      rawTeams.forEach((key, val) {
        if (val != null) teams[key.toString()] = val.toString();
      });
    }

    return EventModel(
      id: json['id']?.toString() ?? '',
      churchId: json['churchId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      date: _parseDate(json['date']),
      start: json['start']?.toString() ?? '',
      steps: _parseSteps(json['steps']),
      people: people,
      teams: teams,
      templateId: json['templateId']?.toString(),
      societyId: json['societyId']?.toString(),
    );
  }

  static DateTime _parseDate(dynamic val) {
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    if (val is String && val.isNotEmpty) return DateTime.tryParse(val) ?? DateTime.now();
    return DateTime.now();
  }

  static List<EventStepModel> _parseSteps(dynamic val) {
    if (val is List) {
      return val.map((e) => EventStepModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return const [];
  }

  Map<String, dynamic> toJson() => {
    'churchId': churchId,
    'name': name,
    'date': Timestamp.fromDate(date),
    'start': start,
    'steps': steps.map((s) => s.toJson()).toList(),
    'people': people,
    'teams': teams,
    if (templateId != null) 'templateId': templateId,
    if (societyId != null) 'societyId': societyId,
  };

  EventModel copyWith({
    String? name,
    DateTime? date,
    String? start,
    List<EventStepModel>? steps,
    Map<String, List<String>>? people,
    Map<String, String>? teams,
    String? templateId,
    String? societyId,
  }) {
    return EventModel(
      id: id,
      churchId: churchId,
      name: name ?? this.name,
      date: date ?? this.date,
      start: start ?? this.start,
      steps: steps ?? this.steps,
      people: people ?? this.people,
      teams: teams ?? this.teams,
      templateId: templateId ?? this.templateId,
      societyId: societyId ?? this.societyId,
    );
  }
}
