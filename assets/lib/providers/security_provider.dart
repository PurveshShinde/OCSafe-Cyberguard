import 'package:flutter/foundation.dart';

import 'package:flutter/services.dart';
import 'package:ocsafe_cyberguard/models/threat.dart';
import 'package:ocsafe_cyberguard/models/scan_result.dart';
import 'package:ocsafe_cyberguard/models/activity_log.dart';
import 'package:ocsafe_cyberguard/models/app_info.dart';
import 'package:ocsafe_cyberguard/models/app_scan_result.dart';

import 'package:ocsafe_cyberguard/services/app_scanner.dart';
import 'package:ocsafe_cyberguard/services/apk_scanner.dart';
import 'package:ocsafe_cyberguard/services/threat_analyzer.dart';
import 'package:ocsafe_cyberguard/services/device_health_service.dart';
import 'package:ocsafe_cyberguard/services/database_service.dart';
import 'package:ocsafe_cyberguard/services/preferences_service.dart';
import 'package:ocsafe_cyberguard/services/notification_service.dart';
import 'package:ocsafe_cyberguard/services/safe_browsing_service.dart';
import 'package:ocsafe_cyberguard/services/threat_intel.dart';
import 'package:ocsafe_cyberguard/services/apk_static_analyzer.dart';
import 'package:ocsafe_cyberguard/services/signature_scanner.dart';
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
  
  // Scan Cache Map: packageName -> threat hash (simplification for memory cache)
  final Map<String, Threat?> _scanCache = {};
  
  List<AppInfo> _installedApps = [];
  DeviceHealthData? _deviceData;

  int _scannedApps = 0;
  int _totalApps = 0;

  // Settings
  bool _realtimeProtection = true;
  bool _safeBrowsing = true;
  bool _autoScan = false;
  String _userName = '';
  String _userEmail = '';
  List<String> _trustedPackages = [];

  // --- Getters ---
  int get scannedApps => _scannedApps;
  int get totalApps => _totalApps;

  // --- Getters ---
  int get securityScore => _securityScore;
  bool get isScanning => _isScanning;
  String get scanStage => _scanStage;
  bool get isFullScan => _isFullScan;
  ScanResult? get lastScanResult => _lastScanResult;
  List<Threat> get threats => _threats;
  List<ActivityLog> get activityLogs => _activityLogs;
  List<ScanResult> get scanHistory => _scanHistory;
  List<AppInfo> get installedApps => _installedApps;
  List<Threat> get detectedThreats => _threats;
  DeviceHealthData? get deviceData => _deviceData;

  bool get realtimeProtection => _realtimeProtection;
  bool get safeBrowsing => _safeBrowsing;
  bool get autoScan => _autoScan;
  String get userName => _userName;
  String get userEmail => _userEmail;
  List<String> get trustedPackages => _trustedPackages;

  /// Initialize all data on app start.
  Future<void> initialize() async {
    await ThreatIntel().loadDatabase(); // Load Threat Database
    await SignatureScanner().initialize(); // Load Signature Database
    await _loadSettings();
    await loadDeviceInfo();
    await loadApps();
    await loadHistory();
    await loadActivityLogs();
    
    // Initialize Local Notifications
    await _notificationService.init();
    await _notificationService.requestPermission();
    
    // Setup Real-time Malware Installation Listener (Foreground)
    _setupRealtimeListener();
  }

  /// Initialize only what's necessary for a headless background scan
  Future<void> initializeHeadless() async {
    await ThreatIntel().loadDatabase();
    await SignatureScanner().initialize();
    await _loadSettings();
    await _notificationService.init();
  }

  void _setupRealtimeListener() {
    DeviceApps.listenToAppsChanges().listen((ApplicationEvent event) async {
      if (event.event == ApplicationEventType.installed && _realtimeProtection) {
        // Fetch app WITH permissions for accurate threat analysis
        final appInfo = await _appScanner.fetchAppWithPermissions(event.packageName);
        if (appInfo != null) {
          Threat? threat = await _checkSignatureMalware(appInfo);
          threat ??= _threatAnalyzer.analyzeApp(appInfo, _trustedPackages);

          if (threat != null && threat.threatScore >= 60) {
            // Add to threats list
            _threats.add(threat);

            await _logActivity(
              'Real-Time Detection: ${threat.appName} flagged as Malware!',
              ActivityType.threat,
            );

            await _notificationService.showThreatDetectedNotification(threat);
          } else if (threat != null) {
            // Suspicious but not Malware (30-60)
            _threats.add(threat);
            await _logActivity(
              'Real-Time Detection: ${threat.appName} flagged as Suspicious.',
              ActivityType.threat,
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

  /// Headless execution for a single app scan via background service
  Future<void> scanSingleAppHeadless(String packageName) async {
    if (!_realtimeProtection) return;

    print('DEBUG: scanSingleAppHeadless started for $packageName');

    // Attempt to fetch app info with a few retries as the OS might take a moment to manifest the new app fully
    AppInfo? appInfo;
    for (int i = 0; i < 3; i++) {
        appInfo = await _appScanner.fetchAppWithPermissions(packageName);
        if (appInfo != null) break;
        print('DEBUG: AppInfo not found for $packageName, retrying in 2s... (Attempt ${i+1})');
        await Future.delayed(const Duration(seconds: 2));
    }

    if (appInfo != null) {
      print('DEBUG: Analyzing $packageName in background...');
      Threat? threat = await _checkSignatureMalware(appInfo);
      threat ??= _threatAnalyzer.analyzeApp(appInfo, _trustedPackages);

      if (threat != null && threat.threatScore >= 60) {
        print('DEBUG: Threat detected in background! ${threat.appName}');
        await _logActivity(
          'Headless Detection: ${threat.appName} flagged as Malware!',
          ActivityType.threat,
        );
        await _notificationService.showThreatDetectedNotification(threat);
      } else {
        print('DEBUG: App is safe or suspicious but below notification threshold.');
      }
    }
  }

  /// Evaluates an app against the signature databases (Packages only)
  Future<Threat?> _checkSignatureMalware(AppInfo appInfo) async {
    final scanner = SignatureScanner();

    // 1. Check Package Name
    if (scanner.isMaliciousPackage(appInfo.packageName)) {
      return Threat(
        appName: appInfo.appName,
        packageName: appInfo.packageName,
        riskLevel: 'HIGH',
        threatScore: 100,
        reasons: ['Signature Match: Known malicious package name'],
        permissionsRequested: appInfo.requestedPermissions,
        recommendedAction: 'DANGEROUS: Known Malware. Uninstall immediately.',
      );
    }

    return null;
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

  /// Manually mark an app as trusted. It will no longer be flagged as a threat.
  Future<void> trustApp(String packageName) async {
    if (!_trustedPackages.contains(packageName)) {
      _trustedPackages.add(packageName);
      await _preferencesService.setTrustedPackages(_trustedPackages);
      
      // Remove from active threats if it was flagged
      removeAppThreat(packageName);
      
      await _logActivity(
        'User trusted app: $packageName',
        ActivityType.protection,
      );
      notifyListeners();
    }
  }

  /// Alias for trustApp used in UI widgets
  Future<void> addToTrusted(String packageName) => trustApp(packageName);

  /// Triggers a native uninstallation prompt for the given package.
  Future<void> uninstallApp(String packageName) async {
    try {
      const channel = MethodChannel('com.ocsafe.cyberguard/uninstall');
      await channel.invokeMethod('uninstall_app', {'package_name': packageName});
      await _logActivity('Requested uninstallation: $packageName', ActivityType.protection);
    } catch (e) {
      debugPrint('Uninstall Error: $e');
    }
  }

  /// Clears the scan cache and resets security state.
  Future<void> clearCache() async {
    await _preferencesService.saveScanCache({}, {});
    _threats.clear();
    _securityScore = 100;
    _scanCache.clear();
    await _logActivity('Scan cache cleared by user', ActivityType.protection);
    notifyListeners();
  }

  /// Sets whether the next scan should be a full device scan or limited scan.
  void setFullScan(bool value) {
    _isFullScan = value;
    notifyListeners();
  }

  /// Runs a smart security scan with staged timing for UX.
  /// If [_isFullScan] is true, scans both installed apps and device storage.
  /// If false, scans installed apps only (Limited Scan).
  /// Runs the full security scan using background isolates.
  Future<void> runScan() async {
    if (_isScanning) return;
    
    _isScanning = true;
    _threats.clear();
    _scannedApps = 0;
    _totalApps = 0;
    _scanStage = 'Starting Smart Scan...';
    notifyListeners();
    print("Scan started");
    
    try {
      // 1. Fetch apps — filter out system apps to focus on user-installed only
      final allApps = await _appScanner.fetchAllAppsWithPermissions();
      _installedApps = allApps.where((app) => !app.isSystemApp).toList();
      _totalApps = _installedApps.length;
      debugPrint("User apps found: $_totalApps (filtered from ${allApps.length} total)");
      notifyListeners();

      // 2. Perform Scan in background chunks for progress tracking
      final List<AppScanResult> allResults = [];
      const int chunkSize = 10;
      
      for (int i = 0; i < _installedApps.length; i += chunkSize) {
        final end = (i + chunkSize < _installedApps.length) 
            ? i + chunkSize 
            : _installedApps.length;
        
        final chunk = _installedApps.sublist(i, end);
        _scanStage = 'Analyzing apps ${i + 1} to $end...';
        notifyListeners();

        // Perform parallel scan for the chunk
        final List<AppScanResult> chunkResults = await compute(_performScanChunk, chunk);
        allResults.addAll(chunkResults);
        
        _scannedApps = end;
        notifyListeners();
      }

      // 3. Process results
      final List<Threat> detectedThreats = [];
      for (var res in allResults) {
        if (res.score >= 30) {
          final app = _installedApps.firstWhere((a) => a.packageName == res.packageName);
          final threat = _threatAnalyzer.analyzeApp(app, _trustedPackages);
          if (threat != null) detectedThreats.add(threat);
        }
      }

      _threats = detectedThreats;
      _updateScore();

      _lastScanResult = ScanResult(
        scanDate: DateTime.now(),
        totalAppsScanned: _totalApps,
        threatCount: _threats.length,
        securityScore: _securityScore,
        threats: _threats,
        appResults: allResults,
        scanMode: _isFullScan ? 'full' : 'limited',
      );

      await _databaseService.insertScanResult(_lastScanResult!);
      await _logActivity(
        'Scan completed: $_totalApps apps scanned, ${_threats.length} threats detected',
        ActivityType.scan,
      );

    } catch (e) {
      debugPrint('Scan Error: $e');
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

  /// Loads installed apps.
  Future<void> loadApps() async {
    _installedApps = await _appScanner.fetchAllAppsWithPermissions();
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
    _trustedPackages = await _preferencesService.getTrustedPackages();
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

/// Top-level function for scanning a chunk of apps.
Future<List<AppScanResult>> _performScanChunk(List<AppInfo> apps) async {
  List<AppScanResult> results = [];
  for (final app in apps) {
    final result = ThreatAnalyzer.analyzeFull(app);
    results.add(result);
    // Brief delay to prevent isolate hogging
    await Future.delayed(const Duration(milliseconds: 1));
  }
  return results;
}
