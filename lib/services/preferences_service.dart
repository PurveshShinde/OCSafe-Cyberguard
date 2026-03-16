import 'package:shared_preferences/shared_preferences.dart';

/// Centralized preferences manager for CyberGuard.
/// Uses caching + singleton for faster access.
class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();

  factory PreferencesService() {
    return _instance;
  }

  PreferencesService._internal();

  late SharedPreferences _prefs;

  static const String _keyRealtimeProtection = 'realtime_protection';
  static const String _keySafeBrowsing = 'safe_browsing';
  static const String _keyAutoScan = 'auto_scan';
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';
  static const String _keyTrustedApps = 'trusted_apps';

  List<String> _trustedAppsCache = [];

  /// Initialize preferences once at app startup.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _trustedAppsCache = _prefs.getStringList(_keyTrustedApps) ?? [];
  }

  // ---------------- Security Settings ----------------

  bool getRealtimeProtection() {
    return _prefs.getBool(_keyRealtimeProtection) ?? true;
  }

  Future<void> setRealtimeProtection(bool value) async {
    await _prefs.setBool(_keyRealtimeProtection, value);
  }

  bool getSafeBrowsing() {
    return _prefs.getBool(_keySafeBrowsing) ?? true;
  }

  Future<void> setSafeBrowsing(bool value) async {
    await _prefs.setBool(_keySafeBrowsing, value);
  }

  bool getAutoScan() {
    return _prefs.getBool(_keyAutoScan) ?? false;
  }

  Future<void> setAutoScan(bool value) async {
    await _prefs.setBool(_keyAutoScan, value);
  }

  // ---------------- User Profile ----------------

  String getUserName() {
    return _prefs.getString(_keyUserName) ?? 'User';
  }

  Future<void> setUserName(String value) async {
    await _prefs.setString(_keyUserName, value);
  }

  String getUserEmail() {
    return _prefs.getString(_keyUserEmail) ?? '';
  }

  Future<void> setUserEmail(String value) async {
    await _prefs.setString(_keyUserEmail, value);
  }

  // ---------------- Trusted Apps ----------------

  List<String> getTrustedApps() {
    return List.unmodifiable(_trustedAppsCache);
  }

  Future<void> addTrustedApp(String packageName) async {
    if (_trustedAppsCache.contains(packageName)) return;

    _trustedAppsCache.add(packageName);
    await _prefs.setStringList(_keyTrustedApps, _trustedAppsCache);
  }

  Future<void> removeTrustedApp(String packageName) async {
    if (!_trustedAppsCache.contains(packageName)) return;

    _trustedAppsCache.remove(packageName);
    await _prefs.setStringList(_keyTrustedApps, _trustedAppsCache);
  }

  bool isTrustedApp(String packageName) {
    return _trustedAppsCache.contains(packageName);
  }
}
