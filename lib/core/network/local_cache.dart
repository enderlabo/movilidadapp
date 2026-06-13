import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Local cache using SharedPreferences.
/// Replaces Hive to avoid version conflicts with the analyzer on Dart 3.11.
/// Single access point for local storage across the whole app.
class LocalCache {
  // Cached instance — avoids repeated async getInstance() calls per operation.
  SharedPreferences? _prefs;

  Future<SharedPreferences> _instance() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> setString(String key, String value) async {
    final prefs = await _instance();
    await prefs.setString(key, value);
  }

  Future<String?> getString(String key) async {
    final prefs = await _instance();
    return prefs.getString(key);
  }

  Future<void> setJson(String key, Map<String, dynamic> json) async {
    await setString(key, jsonEncode(json));
  }

  Future<Map<String, dynamic>?> getJson(String key) async {
    final raw = await getString(key);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> setJsonList(String key, List<Map<String, dynamic>> list) async {
    await setString(key, jsonEncode(list));
  }

  Future<List<Map<String, dynamic>>?> getJsonList(String key) async {
    final raw = await getString(key);
    if (raw == null) return null;
    final decoded = jsonDecode(raw) as List;
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> remove(String key) async {
    final prefs = await _instance();
    await prefs.remove(key);
  }

  Future<void> clear() async {
    final prefs = await _instance();
    await prefs.clear();
  }
}
