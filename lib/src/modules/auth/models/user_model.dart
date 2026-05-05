import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { churchAdmin, member }

enum UserStatus { pending, active, disabled }

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.churchId,
    this.fcmToken,
    this.phone,
    this.birthday,
    this.profileId,
    this.disabledNotifications = const [],
    this.availability = const [],
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final UserStatus status;
  final String? churchId;
  final String? fcmToken;
  final String? phone;
  final DateTime? birthday;
  final String? profileId;
  final List<String> disabledNotifications;
  final List<DateTime> availability;

  bool get isAdmin => role == UserRole.churchAdmin;
  bool get isChurchAdmin => role == UserRole.churchAdmin;
  bool get isMember => role == UserRole.member;
  bool get isPending => status == UserStatus.pending;
  bool get isActive => status == UserStatus.active;
  bool get hasChurch => churchId != null && churchId!.isNotEmpty;

  bool isNotificationEnabled(String notificationId) =>
      !disabledNotifications.contains(notificationId);

  bool hasAvailabilityForDate(DateTime date) {
    return availability.any(
      (d) => d.year == date.year && d.month == date.month && d.day == date.day,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedBirthday;
    final rawBirthday = json['birthday'];
    if (rawBirthday is Map && rawBirthday['_seconds'] != null) {
      parsedBirthday = DateTime.fromMillisecondsSinceEpoch(
        (rawBirthday['_seconds'] as int) * 1000,
        isUtc: true,
      );
    } else if (rawBirthday is Timestamp) {
      parsedBirthday = rawBirthday.toDate();
    }

    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: _parseRole(json['role']?.toString()),
      status: _parseStatus(json['status']?.toString()),
      churchId: json['churchId']?.toString(),
      fcmToken: json['fcmToken']?.toString(),
      phone: json['phone']?.toString(),
      birthday: parsedBirthday,
      profileId: json['profileId']?.toString(),
      disabledNotifications:
          (json['disabled_notifications'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      availability: (json['availability'] as List<dynamic>?)
              ?.map((e) {
                if (e is Map && e['_seconds'] != null) {
                  return DateTime.fromMillisecondsSinceEpoch(
                    (e['_seconds'] as int) * 1000,
                    isUtc: true,
                  );
                }
                return DateTime.now();
              })
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role.name,
    'status': status.name,
    if (churchId != null) 'churchId': churchId,
    if (fcmToken != null) 'fcmToken': fcmToken,
    if (phone != null) 'phone': phone,
    if (birthday != null) 'birthday': Timestamp.fromDate(birthday!),
    if (profileId != null) 'profileId': profileId,
    if (disabledNotifications.isNotEmpty)
      'disabled_notifications': disabledNotifications,
  };

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    UserStatus? status,
    String? churchId,
    String? fcmToken,
    String? phone,
    DateTime? birthday,
    String? profileId,
    List<String>? disabledNotifications,
    List<DateTime>? availability,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      churchId: churchId ?? this.churchId,
      fcmToken: fcmToken ?? this.fcmToken,
      phone: phone ?? this.phone,
      birthday: birthday ?? this.birthday,
      profileId: profileId ?? this.profileId,
      disabledNotifications: disabledNotifications ?? this.disabledNotifications,
      availability: availability ?? this.availability,
    );
  }

  static UserRole _parseRole(String? value) {
    switch (value) {
      case 'churchAdmin':
        return UserRole.churchAdmin;
      default:
        return UserRole.member;
    }
  }

  static UserStatus _parseStatus(String? value) {
    switch (value) {
      case 'active':
        return UserStatus.active;
      case 'disabled':
        return UserStatus.disabled;
      default:
        return UserStatus.pending;
    }
  }
}
