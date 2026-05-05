// lib/src/modules/profiles/models/profile_model.dart

class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.name,
    required this.permissions,
    this.isAdminRole = false,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final Map<String, bool> permissions;
  final bool isAdminRole;
  final bool isDefault;

  bool can(String permission) {
    if (isAdminRole) return true;
    return permissions[permission] ?? false;
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final rawPerms = json['permissions'];
    final Map<String, bool> perms = {};
    if (rawPerms is Map) {
      rawPerms.forEach((k, v) {
        if (v is bool) perms[k.toString()] = v;
      });
    }
    return ProfileModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      permissions: perms,
      isAdminRole: json['isAdminRole'] as bool? ?? false,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'isAdminRole': isAdminRole,
    'isDefault': isDefault,
    'permissions': permissions,
  };

  ProfileModel copyWith({
    String? id,
    String? name,
    Map<String, bool>? permissions,
    bool? isAdminRole,
    bool? isDefault,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      permissions: permissions ?? this.permissions,
      isAdminRole: isAdminRole ?? this.isAdminRole,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
