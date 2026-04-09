import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theft_constants.dart';
import 'theft_detection_service.dart';
import 'device_lock_channel.dart';

/// ChangeNotifier that owns the [TheftDetectionService] lifecycle.
///
/// Responsibilities:
///  - Persist enabled/sensitivity state in SharedPreferences.
///  - Drive service start/stop based on toggle.
///  - Expose [isAdminActive] for UI to show permission warning.
class TheftStateManager extends ChangeNotifier {
  TheftStateManager._();

  static TheftStateManager? _instance;
  static TheftStateManager get instance =>
      _instance ??= TheftStateManager._();

  // ── Persisted state ────────────────────────────────────────────────────────
  bool _enabled = false;
  TheftSensitivity _sensitivity = TheftSensitivity.medium;

  // ── Runtime state ──────────────────────────────────────────────────────────
  bool _adminActive = false;
  bool _initialized = false;

  TheftDetectionService? _service;

  // ── Getters ────────────────────────────────────────────────────────────────
  bool get isEnabled    => _enabled;
  bool get isAdminActive => _adminActive;
  bool get isInitialized => _initialized;
  TheftSensitivity get sensitivity => _sensitivity;

  // ── Initialization ─────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(TheftConstants.prefEnabled) ?? false;

    final saved = prefs.getString(TheftConstants.prefSensitivity);
    _sensitivity = TheftSensitivity.values.firstWhere(
      (e) => e.name == saved,
      orElse: () => TheftSensitivity.medium,
    );

    await _refreshAdminStatus();

    if (_enabled) {
      _startService();
    }

    _initialized = true;
    notifyListeners();
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    _enabled = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(TheftConstants.prefEnabled, value);

    if (value) {
      await _refreshAdminStatus();
      _startService();
    } else {
      _stopService();
    }

    notifyListeners();
  }

  Future<void> setSensitivity(TheftSensitivity sensitivity) async {
    if (_sensitivity == sensitivity) return;
    _sensitivity = sensitivity;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(TheftConstants.prefSensitivity, sensitivity.name);

    _service?.updateSensitivity(sensitivity);
    notifyListeners();
  }

  /// Re-checks admin permission and updates UI.
  Future<void> refreshAdminStatus() async {
    await _refreshAdminStatus();
    notifyListeners();
  }

  Future<void> requestAdminPermission() async {
    await DeviceLockChannel.requestAdminPermission();
    // Delay to allow user to return from settings before re-checking.
    await Future.delayed(const Duration(seconds: 1));
    await refreshAdminStatus();
  }

  // ── Private ────────────────────────────────────────────────────────────────

  void _startService() {
    _service ??= TheftDetectionService(sensitivity: _sensitivity);
    _service!.start();
  }

  void _stopService() {
    _service?.stop();
    _service = null;
  }

  Future<void> _refreshAdminStatus() async {
    _adminActive = await DeviceLockChannel.isAdminActive();
  }

  @override
  void dispose() {
    _service?.dispose();
    super.dispose();
  }
}
