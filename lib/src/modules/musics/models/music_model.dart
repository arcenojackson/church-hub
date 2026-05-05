import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/utils/tone_utils.dart';

class MusicModel {
  const MusicModel({
    required this.id,
    required this.churchId,
    required this.title,
    required this.artist,
    required this.tone,
    required this.category,
    this.obs,
    this.youtube,
    this.cipher = '',
    this.lyrics,
    this.bpm,
    this.tempo,
    this.minorTone = false,
    this.selectedTimes = const [],
    this.imageUrl,
  });

  final String id;
  final String churchId;
  final String title;
  final String artist;
  final String? obs;
  final String? youtube;
  final String cipher;
  final String? lyrics;
  final String? bpm;
  final String? tempo;
  final String tone;
  final bool minorTone;
  final String category;
  final List<String> selectedTimes;
  final String? imageUrl;

  String get displayTone => minorTone ? '${toneLabel(tone)}m' : toneLabel(tone);

  factory MusicModel.fromFirestore(DocumentSnapshot doc, String churchId) {
    final data = doc.data() as Map<String, dynamic>;
    return MusicModel(
      id: doc.id,
      churchId: churchId,
      title: data['title']?.toString() ?? '',
      artist: data['artist']?.toString() ?? '',
      obs: data['obs']?.toString(),
      youtube: data['youtube']?.toString(),
      cipher: data['cipher']?.toString() ?? '',
      lyrics: data['lyrics']?.toString(),
      bpm: data['bpm']?.toString(),
      tempo: data['tempo']?.toString(),
      tone: data['tone']?.toString() ?? 'C',
      minorTone: data['minorTone'] == true,
      category: data['category']?.toString() ?? '',
      selectedTimes: (data['selectedTimes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      imageUrl: data['imageUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'artist': artist,
    if (obs != null) 'obs': obs,
    if (youtube != null) 'youtube': youtube,
    'cipher': cipher,
    if (lyrics != null) 'lyrics': lyrics,
    if (bpm != null) 'bpm': bpm,
    if (tempo != null) 'tempo': tempo,
    'tone': tone,
    'minorTone': minorTone,
    'category': category,
    if (selectedTimes.isNotEmpty) 'selectedTimes': selectedTimes,
    if (imageUrl != null) 'imageUrl': imageUrl,
  };

  MusicModel copyWith({
    String? title,
    String? artist,
    String? obs,
    String? youtube,
    String? cipher,
    String? lyrics,
    String? bpm,
    String? tempo,
    String? tone,
    bool? minorTone,
    String? category,
    List<String>? selectedTimes,
    String? imageUrl,
  }) {
    return MusicModel(
      id: id,
      churchId: churchId,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      obs: obs ?? this.obs,
      youtube: youtube ?? this.youtube,
      cipher: cipher ?? this.cipher,
      lyrics: lyrics ?? this.lyrics,
      bpm: bpm ?? this.bpm,
      tempo: tempo ?? this.tempo,
      tone: tone ?? this.tone,
      minorTone: minorTone ?? this.minorTone,
      category: category ?? this.category,
      selectedTimes: selectedTimes ?? this.selectedTimes,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

class MusicCategoryModel {
  const MusicCategoryModel({required this.id, required this.name});

  final String id;
  final String name;

  factory MusicCategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MusicCategoryModel(
      id: doc.id,
      name: data['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'name': name};
}
