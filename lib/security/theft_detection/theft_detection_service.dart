import 'package:flutter/widgets.dart';
import 'theft_constants.dart';

/// Main detection engine for Smart Theft Shield.
///
/// Refactored to operate as a lightweight proxy. The actual functionality
/// has been moved to Native Android (BackgroundScannerService.kt) to ensure
/// the anti-theft feature continues running in the background when the Flutter
/// engine pauses. The native side listens to standard SharedPreferences changes.
class TheftDetectionService with WidgetsBindingObserver {
  TheftDetectionService({TheftSensitivity sensitivity = TheftSensitivity.medium});

  // ── State ──────────────────────────────────────────────────────────────────
  bool _isActive = false;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  /// Start lifecycle observer (Native handles the actual sensor logic)
  void start() {
    if (_isActive) return;
    _isActive = true;
  }

  /// Stop lifecycle observer
  void stop() {
    if (!_isActive) return;
    _isActive = false;
  }

  /// Update sensitivity at runtime
  void updateSensitivity(TheftSensitivity sensitivity) {
    // Native Background Scanner Service uses SharedPreferencesOnChangeListener
    // automatically reading the values updated by TheftStateManager.
  }

  /// Clean up everything — call when the feature is permanently disabled.
  void dispose() => stop();
}
