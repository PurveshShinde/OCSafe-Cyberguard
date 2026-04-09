/// Compile-time constants for the Smart Theft Shield feature.
/// Adjust thresholds here without touching detection logic.
library;

class TheftConstants {
  TheftConstants._();

  // ---------- Jerk detection ----------
  /// Magnitude-squared threshold to register a sudden jerk.
  static const double jerkThresholdLow    = 150.0;
  static const double jerkThresholdMedium = 200.0;
  static const double jerkThresholdHigh   = 250.0;

  // ---------- Continuous motion ----------
  /// Sum-of-absolutes threshold per sample during the monitoring window.
  static const double continuousThreshold = 25.0;

  /// Number of samples above [continuousThreshold] needed to confirm theft.
  static const int continuousSampleCount = 5;

  // ---------- Timing ----------
  /// Seconds the monitoring window stays open after a jerk.
  static const int monitoringWindowSeconds = 5;

  /// Delay (ms) between detection and actual lock — gives visual feedback time.
  static const int lockDelayMs = 1500;

  /// Cooldown (s) after a lock attempt before the sensor can trigger again.
  static const int cooldownSeconds = 5;

  // ---------- Platform channel ----------
  static const String channelName = 'cyberguard/theft_lock';

  // ---------- SharedPreferences keys ----------
  static const String prefEnabled     = 'theft_protection_enabled';
  static const String prefSensitivity = 'theft_protection_sensitivity';
}

/// Sensitivity levels exposed to the UI.
enum TheftSensitivity {
  low('Low', 'Fewer false alarms — good for active users', TheftConstants.jerkThresholdLow),
  medium('Medium', 'Balanced detection — recommended', TheftConstants.jerkThresholdMedium),
  high('High', 'Aggressive — best for stationary use', TheftConstants.jerkThresholdHigh);

  const TheftSensitivity(this.label, this.description, this.jerkThreshold);

  final String label;
  final String description;
  final double jerkThreshold;
}
