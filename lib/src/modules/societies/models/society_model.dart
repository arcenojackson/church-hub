import 'package:cloud_firestore/cloud_firestore.dart';

class SocietyModel {
  const SocietyModel({
    required this.id,
    required this.churchId,
    required this.name,
    required this.description,
    required this.color,
    required this.userId,
    this.membersIds = const [],
    this.leadersIds = const [],
    this.boardWithPositions = const {},
    this.forumUsersByCategory = const {},
    this.vocaisIds = const [],
    this.ministrosIds = const [],
  });

  final String id;
  final String churchId;
  final String name;
  final String description;
  final int color;
  final String userId;
  final List<String> membersIds;
  final List<String> leadersIds;
  final Map<String, List<String>> boardWithPositions;
  final Map<String, List<String>> forumUsersByCategory;
  final List<String> vocaisIds;
  final List<String> ministrosIds;

  factory SocietyModel.fromFirestore(DocumentSnapshot doc, String churchId) {
    final data = doc.data() as Map<String, dynamic>;

    final board = <String, List<String>>{};
    final rawBoard = data['boardWithPositions'];
    if (rawBoard is Map) {
      rawBoard.forEach((k, v) {
        if (v is List) board[k.toString()] = v.map((e) => e.toString()).toList();
      });
    }

    final forum = <String, List<String>>{};
    final rawForum = data['forumUsersByCategory'];
    if (rawForum is Map) {
      rawForum.forEach((k, v) {
        if (v is List) forum[k.toString()] = v.map((e) => e.toString()).toList();
      });
    }

    return SocietyModel(
      id: doc.id,
      churchId: churchId,
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      color: (data['color'] as int?) ?? 0xFF3E6C3E,
      userId: data['userId']?.toString() ?? '',
      membersIds: (data['membersIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      leadersIds: (data['leadersIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      boardWithPositions: board,
      forumUsersByCategory: forum,
      vocaisIds: (data['vocaisIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      ministrosIds: (data['ministrosIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'color': color,
    'userId': userId,
    'membersIds': membersIds,
    if (leadersIds.isNotEmpty) 'leadersIds': leadersIds,
    'boardWithPositions': boardWithPositions,
    if (forumUsersByCategory.isNotEmpty)
      'forumUsersByCategory': forumUsersByCategory,
    if (vocaisIds.isNotEmpty) 'vocaisIds': vocaisIds,
    if (ministrosIds.isNotEmpty) 'ministrosIds': ministrosIds,
  };

  SocietyModel copyWith({
    String? name,
    String? description,
    int? color,
    List<String>? membersIds,
    List<String>? leadersIds,
    Map<String, List<String>>? boardWithPositions,
    Map<String, List<String>>? forumUsersByCategory,
    List<String>? vocaisIds,
    List<String>? ministrosIds,
  }) {
    return SocietyModel(
      id: id,
      churchId: churchId,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      userId: userId,
      membersIds: membersIds ?? this.membersIds,
      leadersIds: leadersIds ?? this.leadersIds,
      boardWithPositions: boardWithPositions ?? this.boardWithPositions,
      forumUsersByCategory: forumUsersByCategory ?? this.forumUsersByCategory,
      vocaisIds: vocaisIds ?? this.vocaisIds,
      ministrosIds: ministrosIds ?? this.ministrosIds,
    );
  }
}
