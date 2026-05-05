class EloRoleConfig {
  const EloRoleConfig({
    required this.id,
    required this.name,
    this.description,
  });

  final String id;
  final String name;
  final String? description;

  factory EloRoleConfig.fromJson(Map<String, dynamic> json, String id) {
    return EloRoleConfig(
      id: id,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    if (description != null) 'description': description,
    'groupId': 'elo',
  };
}

class TeamTypeConfig {
  const TeamTypeConfig({
    required this.id,
    required this.name,
    this.description,
  });

  final String id;
  final String name;
  final String? description;

  factory TeamTypeConfig.fromJson(Map<String, dynamic> json, String id) {
    return TeamTypeConfig(
      id: id,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    if (description != null) 'description': description,
  };
}

class BoardPositionConfig {
  const BoardPositionConfig({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory BoardPositionConfig.fromJson(Map<String, dynamic> json, String id) {
    return BoardPositionConfig(
      id: id,
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'name': name};
}

class ReminderRule {
  const ReminderRule({
    required this.id,
    required this.type,
    required this.daysBeforeEvent,
    this.message,
  });

  final String id;
  final String type;
  final int daysBeforeEvent;
  final String? message;

  factory ReminderRule.fromJson(Map<String, dynamic> json, String id) {
    return ReminderRule(
      id: id,
      type: json['type']?.toString() ?? '',
      daysBeforeEvent: (json['daysBeforeEvent'] as int?) ?? 1,
      message: json['message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'daysBeforeEvent': daysBeforeEvent,
    if (message != null) 'message': message,
  };
}

class ChurchSettingsModel {
  const ChurchSettingsModel({
    required this.churchId,
    this.eloRoles = const [],
    this.teamTypes = const [],
    this.boardPositions = const [],
    this.reminderRules = const [],
    this.calendarCategories = const [],
    this.defaultSteps = const [],
  });

  final String churchId;
  final List<EloRoleConfig> eloRoles;
  final List<TeamTypeConfig> teamTypes;
  final List<BoardPositionConfig> boardPositions;
  final List<ReminderRule> reminderRules;
  final List<String> calendarCategories;
  final List<Map<String, dynamic>> defaultSteps;

  factory ChurchSettingsModel.fromJson(Map<String, dynamic> json, String churchId) {
    final roles = <EloRoleConfig>[];
    final rolesMap = json['roles'] as Map<String, dynamic>?;
    rolesMap?.forEach((id, val) {
      if (val is Map<String, dynamic>) {
        roles.add(EloRoleConfig.fromJson(val, id));
      }
    });

    final teamTypes = <TeamTypeConfig>[];
    final teamMap = json['teamTypes'] as Map<String, dynamic>?;
    teamMap?.forEach((id, val) {
      if (val is Map<String, dynamic>) {
        teamTypes.add(TeamTypeConfig.fromJson(val, id));
      }
    });

    final boardPositions = <BoardPositionConfig>[];
    final boardMap = json['boardPositions'] as Map<String, dynamic>?;
    boardMap?.forEach((id, val) {
      if (val is Map<String, dynamic>) {
        boardPositions.add(BoardPositionConfig.fromJson(val, id));
      }
    });

    final reminderRules = <ReminderRule>[];
    final reminderMap = json['reminderRules'] as Map<String, dynamic>?;
    reminderMap?.forEach((id, val) {
      if (val is Map<String, dynamic>) {
        reminderRules.add(ReminderRule.fromJson(val, id));
      }
    });

    return ChurchSettingsModel(
      churchId: churchId,
      eloRoles: roles,
      teamTypes: teamTypes,
      boardPositions: boardPositions,
      reminderRules: reminderRules,
      calendarCategories:
          (json['calendarCategories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      defaultSteps:
          (json['defaultSteps'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    final rolesMap = <String, dynamic>{};
    for (final r in eloRoles) {
      rolesMap[r.id] = r.toJson();
    }

    final teamMap = <String, dynamic>{};
    for (final t in teamTypes) {
      teamMap[t.id] = t.toJson();
    }

    final boardMap = <String, dynamic>{};
    for (final b in boardPositions) {
      boardMap[b.id] = b.toJson();
    }

    final reminderMap = <String, dynamic>{};
    for (final r in reminderRules) {
      reminderMap[r.id] = r.toJson();
    }

    return {
      if (rolesMap.isNotEmpty) 'roles': rolesMap,
      if (teamMap.isNotEmpty) 'teamTypes': teamMap,
      if (boardMap.isNotEmpty) 'boardPositions': boardMap,
      if (reminderMap.isNotEmpty) 'reminderRules': reminderMap,
      if (calendarCategories.isNotEmpty) 'calendarCategories': calendarCategories,
      if (defaultSteps.isNotEmpty) 'defaultSteps': defaultSteps,
    };
  }

  ChurchSettingsModel copyWith({
    List<EloRoleConfig>? eloRoles,
    List<TeamTypeConfig>? teamTypes,
    List<BoardPositionConfig>? boardPositions,
    List<ReminderRule>? reminderRules,
    List<String>? calendarCategories,
    List<Map<String, dynamic>>? defaultSteps,
  }) {
    return ChurchSettingsModel(
      churchId: churchId,
      eloRoles: eloRoles ?? this.eloRoles,
      teamTypes: teamTypes ?? this.teamTypes,
      boardPositions: boardPositions ?? this.boardPositions,
      reminderRules: reminderRules ?? this.reminderRules,
      calendarCategories: calendarCategories ?? this.calendarCategories,
      defaultSteps: defaultSteps ?? this.defaultSteps,
    );
  }
}
