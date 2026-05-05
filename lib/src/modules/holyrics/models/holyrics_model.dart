import 'package:cloud_firestore/cloud_firestore.dart';

class HolyricsConfigModel {
  const HolyricsConfigModel({
    required this.id,
    required this.churchId,
    required this.ipAddress,
    required this.port,
    this.token,
    this.isEnabled = true,
  });

  final String id;
  final String churchId;
  final String ipAddress;
  final int port;
  final String? token;
  final bool isEnabled;

  String get baseUrl => 'http://$ipAddress:$port';

  factory HolyricsConfigModel.fromFirestore(DocumentSnapshot doc, String churchId) {
    final data = doc.data() as Map<String, dynamic>;
    return HolyricsConfigModel(
      id: doc.id,
      churchId: churchId,
      ipAddress: data['ipAddress']?.toString() ?? '192.168.1.100',
      port: (data['port'] as int?) ?? 8080,
      token: data['token']?.toString(),
      isEnabled: data['isEnabled'] != false,
    );
  }

  Map<String, dynamic> toJson() => {
    'ipAddress': ipAddress,
    'port': port,
    if (token != null) 'token': token,
    'isEnabled': isEnabled,
  };

  HolyricsConfigModel copyWith({
    String? ipAddress,
    int? port,
    String? token,
    bool? isEnabled,
  }) {
    return HolyricsConfigModel(
      id: id,
      churchId: churchId,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      token: token ?? this.token,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
