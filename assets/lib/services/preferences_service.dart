import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ocsafe_cyberguard/models/threat.dart';

/// Wrapper around SharedPreferences for app settings.
class PreferencesService {
  static const String _keyRealtimeProtection = 'realtime_protection';
  static const String _keySafeBrowsing = 'safe_browsing';
  static const String _keyAutoScan = 'auto_scan';
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';
  static const String _keyTrustedPackages = 'trusted_packages';
  static const String _keyScanVersions = 'scan_cache_versions';
  static const String _keyScanThreats = 'scan_cache_threats';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // --- Scan Cache ---

  Future<Map<String, int>> getScanCache() async {
    final prefs = await _preferences;
    final String? jsonStr = prefs.getString(_keyScanVersions);
    if (jsonStr == null) return {};
    try {
      final Map<String, dynamic> raw = jsonDecode(jsonStr);
      return raw.map((key, value) => MapEntry(key, value as int));
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, Threat>> getCachedThreats() async {
    final prefs = await _preferences;
    final String? jsonStr = prefs.getString(_keyScanThreats);
    if (jsonStr == null) return {};
    try {
      final Map<String, dynamic> raw = jsonDecode(jsonStr);
      return raw.map((key, value) => MapEntry(key, Threat.fromMap(value)));
    } catch (_) {
      return {};
    }
  }

  Future<void> saveScanCache(Map<String, int> versions, Map<String, Threat> threats) async {
    final prefs = await _preferences;
    await prefs.setString(_keyScanVersions, jsonEncode(versions));
    
    final Map<String, dynamic> threatsRaw = threats.map((key, value) => MapEntry(key, value.toMap()));
    await prefs.setString(_keyScanThreats, jsonEncode(threatsRaw));
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
    return prefs.getString(_keyUserName) ?? '';
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

  // --- Trusted Apps ---
  
  Future<List<String>> getTrustedPackages() async {
    final prefs = await _preferences;
    return prefs.getStringList(_keyTrustedPackages) ?? [];
  }

  Future<void> setTrustedPackages(List<String> packages) async {
    final prefs = await _preferences;
    await prefs.setStringList(_keyTrustedPackages, packages);
  }
}
