import 'package:shared_preferences/shared_preferences.dart';

/// Wrapper around SharedPreferences for app settings.
class PreferencesService {
  static const String _keyRealtimeProtection = 'realtime_protection';
  static const String _keySafeBrowsing = 'safe_browsing';
  static const String _keyAutoScan = 'auto_scan';
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // --- Security Settings ---

  Future<bool> getRealtimeProtection() async {
    final prefs = await _preferences;
    return prefs.getBool(_keyRealtimeProtection) ?? true;
  }

  Future<void> setRealtimeProtection(bool value) async {
    final prefs = await _preferences;
    await prefs.setBool(_keyRealtimeProtection, value);
  }

  Future<bool> getSafeBrowsing() async {
    final prefs = await _preferences;
    return prefs.getBool(_keySafeBrowsing) ?? true;
  }

  Future<void> setSafeBrowsing(bool value) async {
    final prefs = await _preferences;
    await prefs.setBool(_keySafeBrowsing, value);
  }

  Future<bool> getAutoScan() async {
    final prefs = await _preferences;
    return prefs.getBool(_keyAutoScan) ?? false;
  }

  Future<void> setAutoScan(bool value) async {
    final prefs = await _preferences;
    await prefs.setBool(_keyAutoScan, value);
  }

  // --- User Profile ---

  Future<String> getUserName() async {
    final prefs = await _preferences;
    return prefs.getString(_keyUserName) ?? 'User';
  }

  Future<void> setUserName(String value) async {
    final prefs = await _preferences;
    await prefs.setString(_keyUserName, value);
  }

  Future<String> getUserEmail() async {
    final prefs = await _preferences;
    return prefs.getString(_keyUserEmail) ?? '';
  }

  Future<void> setUserEmail(String value) async {
    final prefs = await _preferences;
    await prefs.setString(_keyUserEmail, value);
  }
}
