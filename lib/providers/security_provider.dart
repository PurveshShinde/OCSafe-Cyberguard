import 'package:flutter/foundation.dart';

import 'package:flutter/services.dart';
import 'package:ocsafe_cyberguard/models/threat.dart';
import 'package:ocsafe_cyberguard/models/scan_result.dart';
import 'package:ocsafe_cyberguard/models/activity_log.dart';
import 'package:ocsafe_cyberguard/models/app_info.dart';

import 'package:ocsafe_cyberguard/services/app_scanner.dart'; // also exports fetchAllAppsBackground
import 'package:ocsafe_cyberguard/services/apk_scanner.dart';
import 'package:ocsafe_cyberguard/services/device_health_service.dart';
import 'package:ocsafe_cyberguard/services/database_service.dart';
import 'package:ocsafe_cyberguard/services/threat_analyzer.dart';
import 'package:ocsafe_cyberguard/services/preferences_service.dart';
import 'package:ocsafe_cyberguard/services/notification_service.dart';
import 'package:ocsafe_cyberguard/services/safe_browsing_service.dart';
import 'package:device_apps/device_apps.dart';

/// Determines whether to run a fast app-only scan or a thorough full-device scan.
enum ScanType { quick, deep }

/// Central state manager orchestrating the multi-module security scan.
class SecurityProvider extends ChangeNotifier {
  final AppScanner _appScanner = AppScanner();
  final ApkScanner _apkScanner = ApkScanner();
  final ThreatAnalyzer _threatAnalyzer = ThreatAnalyzer();
  final DeviceHealthService _deviceHealthService = DeviceHealthService();
  final DatabaseService _databaseService = DatabaseService();
  final PreferencesService _preferencesService = PreferencesService();
  final NotificationService _notificationService = NotificationService();
  final SafeBrowsingService _safeBrowsingService = SafeBrowsingService();

  // --- State ---
  int _securityScore = 100;
  bool _isScanning = false;
  String _scanStage = '';
  ScanType _scanType = ScanType.quick;

  ScanResult? _lastScanResult;
  List<Threat> _threats = [];
  List<ActivityLog> _activityLogs = [];
  List<ScanResult> _scanHistory = [];

  DeviceHealthData? _deviceData;
  final Set<String> _notifiedPackages = {};
  List<String> _trustedApps = [];

  // Settings
  bool _realtimeProtection = true;
  bool _safeBrowsing = true;
  bool _autoScan = false;
  String _userName = 'User';
  String _userEmail = '';

  // --- Getters ---
  int get securityScore => _securityScore;
  bool get isScanning => _isScanning;
  String get scanStage => _scanStage;
  ScanType get currentScanType => _scanType;
  /// Convenience getter — true when the current/last scan was a Deep Scan.
  bool get isFullScan => _scanType == ScanType.deep;
  ScanResult? get lastScanResult => _lastScanResult;
  List<Threat> get threats => _threats;
  List<ActivityLog> get activityLogs => _activityLogs;
  List<ScanResult> get scanHistory => _scanHistory;
  DeviceHealthData? get deviceData => _deviceData;
  List<String> get trustedApps => _trustedApps;

  bool get realtimeProtection => _realtimeProtection;
  bool get safeBrowsing => _safeBrowsing;
  bool get autoScan => _autoScan;
  String get userName => _userName;
  String get userEmail => _userEmail;

  /// Initialize all data on app start.
  Future<void> initialize() async {
    try {
      // MUST be called first — PreferencesService uses a `late` SharedPreferences
      // instance that throws LateInitializationError if accessed before init().
      await _preferencesService.init();

      await _loadSettings();
      await loadDeviceInfo();
      await loadHistory();
      await loadActivityLogs();

      // Initialize Local Notifications
      await _notificationService.init();
      await _notificationService.requestPermission();

      // Setup Real-time Malware Installation Listener
      _setupRealtimeListener();
    } catch (e) {
      // Log but don't crash — partial init is better than no init
      debugPrint('[SecurityProvider] initialize() error: $e');
      // Still attempt notification setup even if other steps failed
      try {
        await _notificationService.init();
        await _notificationService.requestPermission();
      } catch (_) {}
    }
  }

  /// Initialize only what's necessary for a headless background scan
  Future<void> initializeHeadless() async {
    // MUST call init() first — same LateInitializationError risk in headless context
    await _preferencesService.init();
    await _loadSettings();
    await _notificationService.init();
  }

  void _setupRealtimeListener() {
    // Listen for installs and uninstalls to update the UI & memory state
    DeviceApps.listenToAppsChanges().listen((ApplicationEvent event) async {
      if (event.event == ApplicationEventType.installed ||
          event.event == ApplicationEventType.updated) {
        if (!_realtimeProtection) return;

        // Skip scanning if the app is trusted
        final packageName = event.packageName;
        if (_trustedApps.contains(packageName)) return;

        // Fetch app parameters for accurate threat analysis
        final appInfo = await _appScanner.fetchAppWithPermissions(packageName);
        if (appInfo != null) {
          final threat = _threatAnalyzer.analyzeApp(appInfo);

          if (threat != null && threat.riskLevel != 'LOW') {
            // Update UI list
            _threats.add(threat);

            await _logActivity(
              'Real-Time Detection: ${threat.appName} flagged as ${threat.riskLevel} risk! Reason: ${threat.reasons.first}',
              ActivityType.threat,
            );

            // NOTE: We don't need to trigger _notificationService here because
            // the Native PackageReceiver exclusively triggers the Headless isolate
            // for ALL push notifications, preventing duplicate notifications.
          } else {
            await _logActivity(
              'Real-Time Scanner: ${appInfo.appName} installed (Safe)',
              ActivityType.protection,
            );
          }
          _updateScore();
          notifyListeners();
          await loadActivityLogs();
        }
      } else if (event.event == ApplicationEventType.uninstalled) {
        // If an app was uninstalled, check if it was currently flagged as a threat
        final initialLength = _threats.length;

        // Find the threat to get its appName before removing it
        final resolvedThreat = _threats
            .where((t) => t.packageName == event.packageName)
            .firstOrNull;
        if (resolvedThreat != null) {
          _notificationService.cancelWarningNotification(
            resolvedThreat.appName,
          );
        }

        _threats.removeWhere((t) => t.packageName == event.packageName);
        _notifiedPackages.remove(
          event.packageName,
        ); // Allow user to be notified again if they reinstall the malware

        // Remove from database and history memory
        await _databaseService.removeThreatsByPackageName(event.packageName);
        for (var scan in _scanHistory) {
          scan.threats.removeWhere((t) => t.packageName == event.packageName);
        }

        if (_threats.length < initialLength) {
          await _logActivity(
            'Threat Removed: ${event.packageName} was successfully uninstalled.',
            ActivityType.protection,
          );
          _updateScore();
          notifyListeners();
          await loadActivityLogs();
        }
      }
    });
  }

  /// Scans a single app in a headless (background) context.
  ///
  /// [isSideloaded] — true when the installer is NOT a trusted store (Play Store, OEM stores).
  ///   Sideloaded apps get a full deep analysis and, if dangerous, trigger a notification.
  ///
  /// [isUpdate] — true when the package existed before (update vs. fresh install).
  ///   Updates from unknown sources still get scanned, but already-trusted apps are skipped.
  ///
  /// Play Store / trusted store installs: **log only, no notification** (expedited path).
  /// Sideloaded + HIGH/MEDIUM threat: **show warning notification**.
  /// Sideloaded + LOW/safe: **log only, no notification**.
  Future<void> scanSingleAppHeadless(
    String packageName, {
    bool isSideloaded = true,
    bool isUpdate = false,
  }) async {
    if (!_realtimeProtection) return;

    // Skip if trusted
    if (_trustedApps.contains(packageName)) {
      print('DEBUG: App $packageName is trusted. Bypassing scan.');
      return;
    }

    // ─── Play Store / Trusted Source Install ───────────────────────────────
    // Play Store manages its own security. Skip deep scan entirely and just log.
    if (!isSideloaded) {
      print('DEBUG: $packageName installed from trusted source. Log only.');
      final appInfo = await _appScanner.fetchAppWithPermissions(packageName);
      if (appInfo != null) {
        await _logActivity(
          'Play Store install: ${appInfo.appName} — trusted source, skipping deep scan.',
          ActivityType.protection,
        );
      }
      return;
    }

    // ─── Sideloaded APK — Full Deep Scan ──────────────────────────────────
    print('DEBUG: scanSingleAppHeadless — SIDELOADED scan for $packageName '
          '(isUpdate=$isUpdate)');

    // Retry up to 3 times: the OS may take a moment to manifest the new install
    AppInfo? appInfo;
    for (int i = 0; i < 3; i++) {
      appInfo = await _appScanner.fetchAppWithPermissions(packageName);
      if (appInfo != null) break;
      print('DEBUG: AppInfo not found for $packageName, retrying… (${i + 1}/3)');
      await Future.delayed(const Duration(seconds: 2));
    }

    if (appInfo != null) {
      print('DEBUG: Analyzing $packageName in background…');
      final threat = _threatAnalyzer.analyzeApp(appInfo);

      if (threat != null && (threat.riskLevel == 'HIGH' || threat.riskLevel == 'MEDIUM')) {
        // ── Dangerous sideloaded APK → notify the user ──────────────────
        print('DEBUG: Threat detected! ${threat.appName} (${threat.riskLevel})');
        await _logActivity(
          'Sideload Detection: ${threat.appName} flagged as ${threat.riskLevel} risk! '
          'Reason: ${threat.reasons.first}',
          ActivityType.threat,
        );
        await _notificationService.showWarningNotification(
          appName: threat.appName,
          riskLevel: threat.riskLevel,
          reason: threat.reasons.first,
          packageName: threat.packageName,
        );
      } else {
        // ── Safe or LOW-risk sideloaded APK → silent log only ───────────
        print('DEBUG: Sideloaded app is safe — no notification.');
        await _logActivity(
          'Sideload Scanner: ${appInfo.appName} installed — no threats found.',
          ActivityType.protection,
        );
      }
    }
  }

  void _updateScore() {
    int highRiskApps = _threats.where((t) => t.riskLevel == 'HIGH').length;
    int mediumRiskApps = _threats.where((t) => t.riskLevel == 'MEDIUM').length;
    int dangerousCount = _threats
        .where((t) => t.permissionsRequested.isNotEmpty)
        .length;

    int score =
        100 -
        (highRiskApps * 20) -
        (mediumRiskApps * 10) -
        (dangerousCount * 5) -
        (_realtimeProtection ? 0 : 20);

    _securityScore = score.clamp(0, 100);
  }

  void removeApkThreat(Threat threat) async {
    _threats.removeWhere((t) => t.packageName == threat.packageName);

    // Persist removal
    await _databaseService.removeThreatsByPackageName(threat.packageName);
    for (var scan in _scanHistory) {
      scan.threats.removeWhere((t) => t.packageName == threat.packageName);
    }

    _updateScore();
    await _logActivity(
      'Threat Removed: ${threat.appName} was deleted from storage.',
      ActivityType.protection,
    );
    notifyListeners();
    await loadActivityLogs();
  }

  void removeAppThreat(String packageName) async {
    final initialLength = _threats.length;
    _threats.removeWhere((t) => t.packageName == packageName);

    if (_threats.length < initialLength) {
      // Persist removal
      await _databaseService.removeThreatsByPackageName(packageName);
      for (var scan in _scanHistory) {
        scan.threats.removeWhere((t) => t.packageName == packageName);
      }

      _updateScore();
      notifyListeners();
    }
  }

  /// Trusts a flagged app, permanently whitelisting it and restoring the score.
  Future<void> trustApp(Threat threat) async {
    // 1. Save to persistent preferences
    await _preferencesService.addTrustedApp(threat.packageName);
    _trustedApps.add(threat.packageName);

    // 2. Remove from active threats
    _threats.removeWhere((t) => t.packageName == threat.packageName);

    // 3. Remove from history memory
    for (var scan in _scanHistory) {
      scan.threats.removeWhere((t) => t.packageName == threat.packageName);
    }

    // 4. Remove from database history
    await _databaseService.removeThreatsByPackageName(threat.packageName);

    // 5. Cancel any pending notification for it
    await _notificationService.cancelWarningNotification(threat.appName);

    // 6. Recalculate security score explicitly
    _updateScore();

    // 7. Log User Action
    await _logActivity(
      'User marked ${threat.appName} as Trusted. It will be ignored in future scans.',
      ActivityType.protection,
    );

    notifyListeners();
  }

  /// Sets which scan type to run next.
  void setScanType(ScanType type) {
    _scanType = type;
    notifyListeners();
  }

  /// Kept for backwards-compat (dashboard used setFullScan).
  void setFullScan(bool value) {
    _scanType = value ? ScanType.deep : ScanType.quick;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────
  // SCAN ENTRY POINT
  // ─────────────────────────────────────────────────────────────────

  /// Runs either Quick or Deep scan based on [type].
  Future<void> runScan([ScanType? type]) async {
    if (_isScanning) return;
    if (type != null) _scanType = type;

    _isScanning = true;
    _threats.clear();
    notifyListeners();

    try {
      if (_scanType == ScanType.quick) {
        await _runQuickScan();
      } else {
        await _runDeepScan();
      }
    } catch (e) {
      await _logActivity('Scan failed: $e', ActivityType.scan);
    } finally {
      _isScanning = false;
      _scanStage = '';
      await loadHistory();
      await loadActivityLogs();
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // QUICK SCAN — Apps only, depth-limited file skip
  // Target: 1–3 seconds
  // ─────────────────────────────────────────────────────────────────
  Future<void> _runQuickScan() async {
    _scanStage = 'Quick Scan: Fetching installed apps...';
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 150));

    final RootIsolateToken token = RootIsolateToken.instance!;
    final List<AppInfo> apps = await compute<Map<String, dynamic>, List<AppInfo>>(
      fetchAllAppsBackground,
      {
        'token': token,
        'trusted_packages': List<String>.from(_trustedApps),
      },
    );

    _scanStage = 'Quick Scan: Analyzing threats...';
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 150));

    final List<Threat> detectedThreats = await compute(
      runThreatAnalysisBackground,
      apps,
    );

    _scanStage = 'Quick Scan: Building report...';
    notifyListeners();

    final seen = <String>{};
    _threats = detectedThreats.where((t) => seen.add(t.packageName)).toList();
    _updateScore();

    _lastScanResult = ScanResult(
      scanDate: DateTime.now(),
      totalAppsScanned: apps.length,
      threatCount: _threats.length,
      securityScore: _securityScore,
      threats: _threats,
      scanMode: 'quick',
    );

    await _databaseService.insertScanResult(_lastScanResult!);
    await _logActivity(
      'Quick Scan completed: ${apps.length} apps scanned, ${_threats.length} threats found.',
      ActivityType.scan,
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // DEEP SCAN — Apps + full file system at depth 6
  // Target: 8–12 seconds
  // ─────────────────────────────────────────────────────────────────
  Future<void> _runDeepScan() async {
    _scanStage = 'Deep Scan: Fetching installed apps...';
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 150));

    final RootIsolateToken token = RootIsolateToken.instance!;
    final List<AppInfo> apps = await compute<Map<String, dynamic>, List<AppInfo>>(
      fetchAllAppsBackground,
      {
        'token': token,
        'trusted_packages': List<String>.from(_trustedApps),
      },
    );

    _scanStage = 'Deep Scan: Analyzing app threats...';
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 150));

    List<Threat> detectedThreats = await compute(
      runThreatAnalysisBackground,
      apps,
    );

    // Full storage scan at depth 6
    _scanStage = 'Deep Scan: Scanning device storage (depth 6)...';
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 150));

    final filePaths = await _apkScanner.scanForSuspiciousFiles(
      depth: ApkScanner.deepScanDepth,
    );
    final fileThreats = await compute(evaluateSuspiciousFilesBackground, filePaths);
    detectedThreats.addAll(fileThreats);

    _scanStage = 'Deep Scan: Building report...';
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 150));

    final seen = <String>{};
    _threats = detectedThreats.where((t) => seen.add(t.packageName)).toList();
    _updateScore();

    _lastScanResult = ScanResult(
      scanDate: DateTime.now(),
      totalAppsScanned: apps.length,
      threatCount: _threats.length,
      securityScore: _securityScore,
      threats: _threats,
      scanMode: 'deep',
    );

    await _databaseService.insertScanResult(_lastScanResult!);
    await _logActivity(
      'Deep Scan completed: ${apps.length} apps + ${filePaths.length} files scanned, ${_threats.length} threats found.',
      ActivityType.scan,
    );
  }

  /// Toggles real-time protection on/off.
  Future<void> toggleRealtimeProtection(bool value) async {
    _realtimeProtection = value;
    await _preferencesService.setRealtimeProtection(value);
    await _logActivity(
      'Real-time protection ${value ? "enabled" : "disabled"}',
      ActivityType.protection,
    );
    notifyListeners();
  }

  /// Toggles safe browsing on/off.
  Future<void> toggleSafeBrowsing(bool value) async {
    _safeBrowsing = value;
    await _preferencesService.setSafeBrowsing(value);

    if (value) {
      await _logActivity(
        'Safe Browsing protection enabled',
        ActivityType.protection,
      );
    } else {
      await _logActivity(
        'Safe Browsing protection disabled',
        ActivityType.protection,
      );
    }
    notifyListeners();
  }

  /// Checks a URL for threats and notifies the user if detected.
  /// This can be called from an AccessibilityService or via clipboard monitoring.
  Future<void> checkUrlForThreats(String url) async {
    if (!_safeBrowsing) return;

    final threat = await _safeBrowsingService.checkUrl(url);
    if (threat != null) {
      await _logActivity(
        'Safe Browsing: Blocked ${threat.threatType} site: ${threat.domain}',
        ActivityType.threat,
      );

      await _notificationService.showSafeBrowsingNotification(
        id: url.hashCode,
        title: '🛑 Malicious Site Detected!',
        body:
            'Alert: ${threat.domain} is flagged as ${threat.threatType}. Avoid sharing any data.',
      );
    }
  }

  /// Toggles auto scan on/off.
  Future<void> toggleAutoScan(bool value) async {
    _autoScan = value;
    await _preferencesService.setAutoScan(value);
    notifyListeners();
  }

  /// Loads device info.
  Future<void> loadDeviceInfo() async {
    _deviceData = await _deviceHealthService.getDeviceHealth();
    notifyListeners();
  }

  /// Loads scan history from database.
  Future<void> loadHistory() async {
    _scanHistory = await _databaseService.getScanHistory();
    if (_scanHistory.isNotEmpty) {
      _lastScanResult = _scanHistory.first;
      _threats = List.from(_lastScanResult!.threats); // Restore active threats
      _updateScore(); // Restore the previous security score based on threats
    }
    notifyListeners();
  }

  /// Loads recent activity logs from database.
  Future<void> loadActivityLogs() async {
    _activityLogs = await _databaseService.getActivityLogs();
    notifyListeners();
  }

  Future<void> updateUserName(String name) async {
    _userName = name;
    await _preferencesService.setUserName(name);
    notifyListeners();
  }

  Future<void> updateUserEmail(String email) async {
    _userEmail = email;
    await _preferencesService.setUserEmail(email);
    notifyListeners();
  }

  // --- Private helpers ---

  Future<void> _loadSettings() async {
    // Note: PreferencesService getters are synchronous after init() is called.
    // The await is harmless here but the real risk was calling these before init().
    _realtimeProtection = _preferencesService.getRealtimeProtection();
    _safeBrowsing = _preferencesService.getSafeBrowsing();
    _autoScan = _preferencesService.getAutoScan();
    _userName = _preferencesService.getUserName();
    _userEmail = _preferencesService.getUserEmail();
    _trustedApps = _preferencesService.getTrustedApps();
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

  /// Removes a threat from the database and history in a headless/background context.
  Future<void> removeThreatHeadless(String packageName) async {
    print('DEBUG: Headless removal for $packageName');
    await _databaseService.removeThreatsByPackageName(packageName);
    await _logActivity(
      'Headless Cleanup: $packageName was uninstalled (Removed from history)',
      ActivityType.protection,
    );
  }
}
