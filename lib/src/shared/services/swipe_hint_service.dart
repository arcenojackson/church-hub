import 'package:shared_preferences/shared_preferences.dart';

class SwipeHintService {
  static const _prefix = 'swipe_hint_shown_';

  static Future<bool> shouldShow(String screenKey) async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('$_prefix$screenKey') ?? false);
  }

  static Future<void> markShown(String screenKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$screenKey', true);
  }
}
