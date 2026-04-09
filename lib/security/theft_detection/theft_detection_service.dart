import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'motion_analyzer.dart';
import 'device_lock_channel.dart';
import 'theft_constants.dart';

/// Main detection engine for Smart Theft Shield.
///
/// Design fixes applied:
///  - Single [StreamSubscription] — no duplicate listeners, no memory leaks.
///  - [WidgetsBindingObserver] — skips processing when screen is off.
///  - Cooldown flag — prevents back-to-back lock triggers.
///  - Time-bounded monitoring window — resets if no follow-up motion.
///  - All platform calls wrapped in try/catch.
class TheftDetectionService with WidgetsBindingObserver {
  TheftDetectionService({TheftSensitivity sensitivity = TheftSensitivity.medium})
      : _analyzer = MotionAnalyzer(sensitivity: sensitivity);

  final MotionAnalyzer _analyzer;

  // ── State ──────────────────────────────────────────────────────────────────
  bool _isActive        = false;
  bool _isMonitoring    = false; // inside jerk window
  bool _isCooldown      = false; // post-lock cooldown
  bool _isScreenOn      = true;  // updated by lifecycle observer
  DateTime? _windowStart;

  StreamSubscription<AccelerometerEvent>? _subscription;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  /// Start the sensor subscription and register lifecycle observer.
  void start() {
    if (_isActive) return;
    _isActive = true;

    WidgetsBinding.instance.addObserver(this);

    // Single subscription — fixes multi-listener memory leak.
    _subscription = accelerometerEventStream(
      samplingPeriod: SensorInterval.normalInterval,
    ).listen(_handleEvent);
  }

  /// Stop sensor subscription and remove lifecycle observer.
  void stop() {
    if (!_isActive) return;
    _isActive = false;

    _subscription?.cancel();
    _subscription = null;
    _resetMonitoring();
    WidgetsBinding.instance.removeObserver(this);
  }

  /// Update sensitivity at runtime — takes effect on next event.
  void updateSensitivity(TheftSensitivity sensitivity) {
    _analyzer.updateSensitivity(sensitivity);
  }

  // ── WidgetsBindingObserver ─────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Screen/app going to background ↔ foreground is our best proxy for
    // screen-on state without a native plugin.
    switch (state) {
      case AppLifecycleState.resumed:
        _isScreenOn = true;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _isScreenOn = false;
        _resetMonitoring(); // cancel any pending window when screen goes off
      case AppLifecycleState.detached:
        stop();
    }
  }

  // ── Detection Logic ────────────────────────────────────────────────────────

  void _handleEvent(AccelerometerEvent event) {
    if (!_isActive || _isCooldown) return;

    // Fix #2: skip when screen is off to avoid pocket-lock.
    if (!_isScreenOn) return;

    // Phase 1 — jerk detected: open monitoring window.
    if (!_isMonitoring && _analyzer.detectJerk(event.x, event.y, event.z)) {
      _isMonitoring = true;
      _windowStart  = DateTime.now();
      _analyzer.reset();
    }

    // Phase 2 — inside monitoring window.
    if (_isMonitoring) {
      final elapsed = DateTime.now().difference(_windowStart!).inSeconds;

      // Window expired — no theft confirmed.
      if (elapsed > TheftConstants.monitoringWindowSeconds) {
        _resetMonitoring();
        return;
      }

      // Continuous motion confirmed → trigger lock.
      if (_analyzer.detectContinuous(event.x, event.y, event.z)) {
        _triggerLock();
        _resetMonitoring();
      }
    }
  }

  void _resetMonitoring() {
    _isMonitoring = false;
    _windowStart  = null;
    _analyzer.reset();
  }

  // ── Lock Trigger ───────────────────────────────────────────────────────────

  void _triggerLock() async {
    // Fix #4: cooldown prevents repeated locks.
    if (_isCooldown) return;
    _isCooldown = true;

    // Short delay for UI feedback before locking.
    await Future.delayed(
      const Duration(milliseconds: TheftConstants.lockDelayMs),
    );

    await DeviceLockChannel.lockDevice();

    // Release cooldown after 5 s to allow future detections.
    Future.delayed(
      Duration(seconds: TheftConstants.cooldownSeconds),
      () => _isCooldown = false,
    );
  }

  /// Clean up everything — call when the feature is permanently disabled.
  void dispose() => stop();
}
