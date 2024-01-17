import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {

  static Future<void> submitTime(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final time = DateTime.now().microsecondsSinceEpoch;
    prefs.setInt(key, time);
  }

  static Future<int?> getTime(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(key);
    } catch (e) {
      print('Error getting value for key $key: $e');
      return null;
    }
  }
}
