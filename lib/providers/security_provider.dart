import 'package:flutter/foundation.dart';

import 'package:flutter/services.dart';
import 'package:ocsafe_cyberguard/models/threat.dart';
import 'package:ocsafe_cyberguard/models/scan_result.dart';
import 'package:ocsafe_cyberguard/models/activity_log.dart';
import 'package:ocsafe_cyberguard/models/app_info.dart';

import 'package:ocsafe_cyberguard/services/app_scanner.dart';
import 'package:ocsafe_cyberguard/services/apk_scanner.dart';
import 'package:ocsafe_cyberguard/services/threat_analyzer.dart';
import 'package:ocsafe_cyberguard/services/device_health_service.dart';
import 'package:ocsafe_cyberguard/services/database_service.dart';
import 'package:ocsafe_cyberguard/services/preferences_service.dart';
import 'package:ocsafe_cyberguard/services/notification_service.dart';
import 'package:ocsafe_cyberguard/services/safe_browsing_service.dart';
import 'package:device_apps/device_apps.dart';

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
  bool _isFullScan = false;
  
  ScanResult? _lastScanResult;
  List<Threat> _threats = [];
  List<ActivityLog> _activityLogs = [];
  List<ScanResult> _scanHistory = [];
  
  DeviceHealthData? _deviceData;

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
  bool get isFullScan => _isFullScan;
  ScanResult? get lastScanResult => _lastScanResult;
  List<Threat> get threats => _threats;
  List<ActivityLog> get activityLogs => _activityLogs;
  List<ScanResult> get scanHistory => _scanHistory;
  DeviceHealthData? get deviceData => _deviceData;

  bool get realtimeProtection => _realtimeProtection;
  bool get safeBrowsing => _safeBrowsing;
  bool get autoScan => _autoScan;
  String get userName => _userName;
  String get userEmail => _userEmail;

  /// Initialize all data on app start.
  Future<void> initialize() async {
    await _loadSettings();
    await loadDeviceInfo();
    await loadHistory();
    await loadActivityLogs();
    
    // Initialize Local Notifications
    await _notificationService.init();
    await _notificationService.requestPermission();
    
    // Setup Real-time Malware Installation Listener
    _setupRealtimeListener();
  }

  void _setupRealtimeListener() {
    DeviceApps.listenToAppsChanges().listen((ApplicationEvent event) async {
      if (event.event == ApplicationEventType.installed && _realtimeProtection) {
        // Fetch app WITH permissions for accurate threat analysis
        final appInfo = await _appScanner.fetchAppWithPermissions(event.packageName);
        if (appInfo != null) {
          final threat = _threatAnalyzer.analyzeApp(appInfo);

          if (threat != null && threat.riskLevel != 'LOW') {
            // Add to threats list
            _threats.add(threat);

            await _logActivity(
              'Real-Time Detection: ${threat.appName} flagged as ${threat.riskLevel} risk! Reason: ${threat.reasons.first}',
              ActivityType.threat,
            );

            // Show high-priority notification
            await _notificationService.showWarningNotification(
              id: threat.appName.hashCode,
              title: '⚠️ Threat Detected: ${threat.appName}',
              body: '${threat.riskLevel} risk app installed. ${threat.reasons.first}. Tap to view details.',
            );
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
        _threats.removeWhere((t) => t.packageName == event.packageName);

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

  void _updateScore() {
    int highRiskApps = _threats.where((t) => t.riskLevel == 'HIGH').length;
    int mediumRiskApps = _threats.where((t) => t.riskLevel == 'MEDIUM').length;
    int dangerousCount = _threats.where((t) => t.permissionsRequested.isNotEmpty).length;

    int score = 100 
                - (highRiskApps * 20) 
                - (mediumRiskApps * 10) 
                - (dangerousCount * 5) 
                - (_realtimeProtection ? 0 : 20);

    _securityScore = score.clamp(0, 100);
  }

  void removeApkThreat(Threat threat) async {
    _threats.removeWhere((t) => t.packageName == threat.packageName);
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
       _updateScore();
       notifyListeners();
    }
  }

  /// Sets whether the next scan should be a full device scan or limited scan.
  void setFullScan(bool value) {
    _isFullScan = value;
    notifyListeners();
  }

  /// Runs a smart security scan with staged timing for UX.
  /// If [_isFullScan] is true, scans both installed apps and device storage.
  /// If false, scans installed apps only (Limited Scan).
  Future<void> runScan() async {
    if (_isScanning) return; // prevent multiple scans
    
    _isScanning = true;
    _threats.clear();
    
    try {
      // 1. Scan installed apps
      _scanStage = 'Scanning installed apps...';
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 800));

      // 2. Fetch apps WITH real permissions for accurate analysis (in background isolate)
      _scanStage = 'Analyzing app permissions...';
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 800));

      final RootIsolateToken token = RootIsolateToken.instance!;
      final List<AppInfo> apps = await compute(fetchAllAppsBackground, token);


      // 3. Suspicious packages analysis + threat detection
      _scanStage = 'Detecting malware & suspicious packages...';
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 800));

      List<Threat> detectedThreats = [];

      for (var appInfo in apps) {
        Threat? threat = _threatAnalyzer.analyzeApp(appInfo);
        if (threat != null) {
          detectedThreats.add(threat);
        }
      }

      // 4. Scan for suspicious files across entire device storage (APKs, ZIPs, DEX, etc.)
      //    Only runs in Full Scan mode (when storage permission is granted).
      List<String> filePaths = [];
      if (_isFullScan) {
        _scanStage = 'Scanning whole device storage for malicious files...';
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 800));
        
        filePaths = await _apkScanner.scanForSuspiciousFiles();
        final fileThreats = _threatAnalyzer.evaluateSuspiciousFiles(filePaths);
        detectedThreats.addAll(fileThreats);
      } else {
        _scanStage = 'Limited scan — skipping storage (no permission)...';
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 600));
      }

      // 5. Deduplicate & calculate threats & generate report
      // On Android, /sdcard and /storage/emulated/0 are symlinked — same files
      // may be found twice. Deduplicate by packageName (file path for file threats).
      _scanStage = 'Calculating threats & generating report...';
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 800));

      final seen = <String>{};
      final uniqueThreats = detectedThreats.where((t) => seen.add(t.packageName)).toList();

      _threats = uniqueThreats;
      _updateScore();

      // Create scan result
      _lastScanResult = ScanResult(
        scanDate: DateTime.now(),
        totalAppsScanned: apps.length,
        threatCount: _threats.length,
        securityScore: _securityScore,
        threats: _threats,
        scanMode: _isFullScan ? 'full' : 'limited',
      );

      // Persist to database
      await _databaseService.insertScanResult(_lastScanResult!);

      // Log completion
      final modeLabel = _isFullScan ? 'Full Scan' : 'Limited Scan';
      await _logActivity(
        '$modeLabel completed: ${apps.length} apps scanned, ${filePaths.length} files checked, ${_threats.length} threats found',
        ActivityType.scan,
      );

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
      await _logActivity('Safe Browsing protection enabled', ActivityType.protection);
    } else {
      await _logActivity('Safe Browsing protection disabled', ActivityType.protection);
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
        body: 'Alert: ${threat.domain} is flagged as ${threat.threatType}. Avoid sharing any data.',
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
    _realtimeProtection = await _preferencesService.getRealtimeProtection();
    _safeBrowsing = await _preferencesService.getSafeBrowsing();
    _autoScan = await _preferencesService.getAutoScan();
    _userName = await _preferencesService.getUserName();
    _userEmail = await _preferencesService.getUserEmail();
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
