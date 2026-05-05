import 'package:cloud_firestore/cloud_firestore.dart';

class ChurchModel {
  const ChurchModel({
    required this.id,
    required this.name,
    required this.accentColor,
    required this.tier,
    required this.createdAt,
    required this.setupCompleted,
    this.logo,
    this.city,
    this.state,
    this.description,
  });

  final String id;
  final String name;
  final String? logo;
  final String? city;
  final String? state;
  final String? description;
  final int accentColor;
  final String tier;
  final DateTime createdAt;
  final bool setupCompleted;

  // NOTE: These tier getters are no longer used for feature gating.
  // All features are unlocked for all churches (app is fully free).
  // Kept for data/reporting purposes only.
  bool get isFree => tier == 'free';
  bool get isBasic => tier == 'basic';
  bool get isPro => tier == 'pro' || tier == 'max';
  bool get isMax => tier == 'max';

  static const List<int> accentColorOptions = [
    0xFFC0392B, // Red
    0xFFE67E22, // Orange
    0xFFF39C12, // Yellow/Gold
    0xFF3E6C3E, // Green (original)
    0xFF2980B9, // Blue
    0xFF2C3E50, // Navy
    0xFF8E44AD, // Purple
    0xFF16A085, // Teal
    0xFFFFA000, // Amber
    0xFF0D6C2E, // Emerald
    0xFF5D6D7E, // Slate
    0xFF7B2D26, // Burgundy
    0xFF3949AB, // Indigo
    0xFFFF6F61, // Coral
    0xFF2E7D32, // Forest
    0xFF37474F, // Blue Grey
  ];

  factory ChurchModel.fromJson(Map<String, dynamic> json, String id) {
    return ChurchModel(
      id: id,
      name: json['name']?.toString() ?? '',
      logo: json['logo']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      description: json['description']?.toString(),
      accentColor: (json['accentColor'] as int?) ?? 0xFF3E6C3E,
      tier: json['tier']?.toString() ?? 'free',
      setupCompleted: json['setupCompleted'] == true,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    if (logo != null) 'logo': logo,
    if (city != null) 'city': city,
    if (state != null) 'state': state,
    if (description != null) 'description': description,
    'accentColor': accentColor,
    'tier': tier,
    'setupCompleted': setupCompleted,
    'createdAt': FieldValue.serverTimestamp(),
  };

  ChurchModel copyWith({
    String? id,
    String? name,
    String? logo,
    String? city,
    String? state,
    String? description,
    int? accentColor,
    String? tier,
    DateTime? createdAt,
    bool? setupCompleted,
  }) {
    return ChurchModel(
      id: id ?? this.id,
      name: name ?? this.name,
      logo: logo ?? this.logo,
      city: city ?? this.city,
      state: state ?? this.state,
      description: description ?? this.description,
      accentColor: accentColor ?? this.accentColor,
      tier: tier ?? this.tier,
      createdAt: createdAt ?? this.createdAt,
      setupCompleted: setupCompleted ?? this.setupCompleted,
    );
  }
}
