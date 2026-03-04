import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ocsafe_cyberguard/models/threat.dart';
import 'package:ocsafe_cyberguard/models/scan_result.dart';
import 'package:ocsafe_cyberguard/models/activity_log.dart';
import 'package:ocsafe_cyberguard/services/scan_service.dart';
import 'package:ocsafe_cyberguard/services/permission_service.dart';
import 'package:ocsafe_cyberguard/services/browsing_service.dart';
import 'package:ocsafe_cyberguard/services/optimization_service.dart';
import 'package:ocsafe_cyberguard/services/database_service.dart';
import 'package:ocsafe_cyberguard/services/preferences_service.dart';

/// Central state manager for the entire app.
class SecurityProvider extends ChangeNotifier {
  final ScanService _scanService = ScanService();
  final PermissionService _permissionService = PermissionService();
  final BrowsingService _browsingService = BrowsingService();
  final OptimizationService _optimizationService = OptimizationService();
  final DatabaseService _databaseService = DatabaseService();
  final PreferencesService _preferencesService = PreferencesService();

  // --- State ---
  int _securityScore = 100;
  bool _isScanning = false;
  ScanResult? _lastScanResult;
  List<Threat> _threats = [];
  List<ActivityLog> _activityLogs = [];
  List<ScanResult> _scanHistory = [];
  Map<Permission, PermissionStatus> _permissionStatuses = {};
  DeviceData? _deviceData;
  int _batteryLevel = -1;

  // Settings
  bool _realtimeProtection = true;
  bool _safeBrowsing = true;
  bool _autoScan = false;

  // User profile
  String _userName = 'User';
  String _userEmail = '';

  // --- Getters ---
  int get securityScore => _securityScore;
  bool get isScanning => _isScanning;
  ScanResult? get lastScanResult => _lastScanResult;
  List<Threat> get threats => _threats;
  List<ActivityLog> get activityLogs => _activityLogs;
  List<ScanResult> get scanHistory => _scanHistory;
  Map<Permission, PermissionStatus> get permissionStatuses => _permissionStatuses;
  DeviceData? get deviceData => _deviceData;
  int get batteryLevel => _batteryLevel;
  bool get realtimeProtection => _realtimeProtection;
  bool get safeBrowsing => _safeBrowsing;
  bool get autoScan => _autoScan;
  String get userName => _userName;
  String get userEmail => _userEmail;

  // Service access
  BrowsingService get browsingService => _browsingService;
  PermissionService get permissionService => _permissionService;

  /// Initialize all data on app start.
  Future<void> initialize() async {
    await _loadSettings();
    await _browsingService.loadBlacklist();
    await refreshPermissions();
    await loadDeviceInfo();
    await loadHistory();
    await loadActivityLogs();
    _recalculateScore();
  }

  /// Runs a full smart security scan.
  Future<void> runScan() async {
    _isScanning = true;
    notifyListeners();

    try {
      // Scan installed apps
      final apps = await _scanService.scanInstalledApps();
      _threats = _scanService.detectSuspiciousApps(apps);

      // Refresh permissions
      await refreshPermissions();

      // Calculate score
      final dangerousCount = _permissionService.countGrantedDangerous(_permissionStatuses);
      _securityScore = _scanService.calculateSecurityScore(
        threatCount: _threats.length,
        dangerousPermissions: dangerousCount,
        realtimeProtectionEnabled: _realtimeProtection,
      );

      // Create scan result
      _lastScanResult = ScanResult(
        scanDate: DateTime.now(),
        totalAppsScanned: apps.length,
        threatCount: _threats.length,
        securityScore: _securityScore,
        threats: _threats,
      );

      // Persist to database
      await _databaseService.insertScanResult(_lastScanResult!);

      // Log activity
      await _logActivity(
        'Scan completed: ${apps.length} apps scanned, ${_threats.length} threats found',
        ActivityType.scan,
      );

      if (_threats.isNotEmpty) {
        for (final threat in _threats) {
          await _logActivity(
            'Threat detected: ${threat.appName} — ${threat.reason}',
            ActivityType.threat,
          );
        }
      }

      // Refresh history
      await loadHistory();
      await loadActivityLogs();
    } catch (e) {
      await _logActivity('Scan failed: $e', ActivityType.scan);
    }

    _isScanning = false;
    notifyListeners();
  }

  /// Toggles real-time protection on/off.
  Future<void> toggleRealtimeProtection(bool value) async {
    _realtimeProtection = value;
    await _preferencesService.setRealtimeProtection(value);
    _recalculateScore();
    await _logActivity(
      'Real-time protection ${value ? "enabled" : "disabled"}',
      ActivityType.protection,
    );
    await loadActivityLogs();
    notifyListeners();
  }

  /// Toggles safe browsing on/off.
  Future<void> toggleSafeBrowsing(bool value) async {
    _safeBrowsing = value;
    await _preferencesService.setSafeBrowsing(value);
    notifyListeners();
  }

  /// Toggles auto scan on/off.
  Future<void> toggleAutoScan(bool value) async {
    _autoScan = value;
    await _preferencesService.setAutoScan(value);
    notifyListeners();
  }

  /// Refreshes permission statuses.
  Future<void> refreshPermissions() async {
    _permissionStatuses = await _permissionService.checkAllPermissions();
    notifyListeners();
  }

  /// Loads device info and battery level.
  Future<void> loadDeviceInfo() async {
    _deviceData = await _optimizationService.getDeviceInfo();
    _batteryLevel = await _optimizationService.getBatteryLevel();
    notifyListeners();
  }

  /// Loads scan history from database.
  Future<void> loadHistory() async {
    _scanHistory = await _databaseService.getScanHistory();
    notifyListeners();
  }

  /// Loads recent activity logs from database.
  Future<void> loadActivityLogs() async {
    _activityLogs = await _databaseService.getActivityLogs();
    notifyListeners();
  }

  /// Updates user profile name.
  Future<void> updateUserName(String name) async {
    _userName = name;
    await _preferencesService.setUserName(name);
    notifyListeners();
  }

  /// Updates user profile email.
  Future<void> updateUserEmail(String email) async {
    _userEmail = email;
    await _preferencesService.setUserEmail(email);
    notifyListeners();
  }

  // --- Private helpers ---

  Future<void> _loadSettings() async {
    _realtimeProtection = await _preferencesService.getRealtimeProtection();
    _safeBrowsing = await _preferencesService.getSafeBrowsing();
    _autoScan = await _preferencesService.getAutoScan();
    _userName = await _preferencesService.getUserName();
    _userEmail = await _preferencesService.getUserEmail();
    notifyListeners();
  }

  void _recalculateScore() {
    final dangerousCount = _permissionService.countGrantedDangerous(_permissionStatuses);
    _securityScore = _scanService.calculateSecurityScore(
      threatCount: _threats.length,
      dangerousPermissions: dangerousCount,
      realtimeProtectionEnabled: _realtimeProtection,
    );
    notifyListeners();
  }

  Future<void> _logActivity(String message, ActivityType type) async {
    final log = ActivityLog(
      message: message,
      type: type,
      timestamp: DateTime.now(),
    );
    await _databaseService.insertActivityLog(log);
  }
}
