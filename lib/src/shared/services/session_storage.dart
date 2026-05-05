import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../modules/auth/models/user_model.dart';

class SessionStorage {
  static const _userKey = 'church_hub_user';

  Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<UserModel?> loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_userKey);
      if (json == null) return null;
      return UserModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
}
