import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/config/firebase_config.dart';
import '../../../core/utils/app_exception.dart';
import '../models/music_model.dart';
import '../models/youtube_search_result.dart';

class MusicsRepository {
  MusicsRepository({required this.churchId});

  final String churchId;
  final FirebaseFirestore _db = FirebaseConfig.firestore;

  CollectionReference get _musics =>
      _db.collection('churches').doc(churchId).collection('musics');

  CollectionReference get _categories =>
      _db.collection('churches').doc(churchId).collection('music_categories');

  Stream<List<MusicModel>> watchAll() {
    return _musics
        .orderBy('title')
        .snapshots()
        .map((q) => q.docs
            .map((d) => MusicModel.fromFirestore(d, churchId))
            .toList());
  }

  Future<List<MusicModel>> fetchAll() async {
    final q = await _musics.orderBy('title').get();
    return q.docs.map((d) => MusicModel.fromFirestore(d, churchId)).toList();
  }

  Future<MusicModel?> fetchById(String musicId) async {
    final doc = await _musics.doc(musicId).get();
    if (!doc.exists) return null;
    return MusicModel.fromFirestore(doc, churchId);
  }

  Future<List<MusicModel>> search(String query) async {
    final all = await fetchAll();
    final q = query.toLowerCase();
    return all.where((m) =>
        m.title.toLowerCase().contains(q) ||
        m.artist.toLowerCase().contains(q)).toList();
  }

  Future<MusicModel> create({
    required String title,
    required String artist,
    required String tone,
    required bool minorTone,
    required String category,
    String cipher = '',
    String? obs,
    String? youtube,
    String? lyrics,
    String? bpm,
    String? tempo,
    String? imageUrl,
  }) async {
    try {
      final ref = _musics.doc();
      final music = MusicModel(
        id: ref.id,
        churchId: churchId,
        title: title,
        artist: artist,
        tone: tone,
        minorTone: minorTone,
        category: category,
        cipher: cipher,
        obs: obs,
        youtube: youtube,
        lyrics: lyrics,
        bpm: bpm,
        tempo: tempo,
        imageUrl: imageUrl,
      );
      await ref.set(music.toJson());
      return music;
    } catch (e) {
      throw AppException(message: 'Erro ao criar música: ${e.toString()}');
    }
  }

  Future<void> update(String musicId, Map<String, dynamic> data) async {
    try {
      await _musics.doc(musicId).update(data);
    } catch (e) {
      throw AppException(message: 'Erro ao atualizar música: ${e.toString()}');
    }
  }

  Future<void> delete(String musicId) async {
    try {
      await _musics.doc(musicId).delete();
    } catch (e) {
      throw AppException(message: 'Erro ao deletar música: ${e.toString()}');
    }
  }

  // Categories
  Stream<List<MusicCategoryModel>> watchCategories() {
    return _categories
        .orderBy('name')
        .snapshots()
        .map((q) => q.docs.map((d) => MusicCategoryModel.fromFirestore(d)).toList());
  }

  Future<List<MusicCategoryModel>> fetchCategories() async {
    final q = await _categories.orderBy('name').get();
    return q.docs.map((d) => MusicCategoryModel.fromFirestore(d)).toList();
  }

  Future<void> createCategory(String name) async {
    await _categories.add({'name': name});
  }

  Future<void> deleteCategory(String categoryId) async {
    await _categories.doc(categoryId).delete();
  }

  Future<List<YoutubeSearchResult>> searchYoutube(String query) async {
    try {
      final apiKey = AppConfig.youtubeApiKey;
      if (apiKey.isEmpty) {
        throw AppException(message: 'API Key do YouTube não configurada.');
      }

      final url = Uri.parse(
        'https://www.googleapis.com/youtube/v3/search'
        '?part=snippet'
        '&type=video'
        '&maxResults=10'
        '&q=${Uri.encodeComponent(query)}'
        '&key=$apiKey',
      );

      final response = await http.get(url);
      if (response.statusCode != 200) {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        throw AppException(
            message: err['error']?['message']?.toString() ?? 'Erro ao buscar no YouTube');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];
      return items.map((item) {
        final id = (item['id'] as Map<String, dynamic>?)?['videoId']?.toString() ?? '';
        final snippet = item['snippet'] as Map<String, dynamic>?;
        final thumb = ((snippet?['thumbnails'] as Map<String, dynamic>?)?['default']
                as Map<String, dynamic>?)?['url']
            ?.toString() ??
            '';
        return YoutubeSearchResult(
          id: id,
          title: snippet?['title']?.toString() ?? '',
          thumbnail: thumb,
        );
      }).toList();
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(message: 'Erro ao buscar no YouTube: ${e.toString()}');
    }
  }
}
