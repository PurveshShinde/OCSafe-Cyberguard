import 'theft_constants.dart';

/// Pure Dart class that encapsulates motion-analysis logic.
///
/// Designed to be stateless between detection cycles — call [reset] after
/// each confirmed detection or when the monitoring window expires.
class MotionAnalyzer {
  MotionAnalyzer({TheftSensitivity sensitivity = TheftSensitivity.medium})
      : _jerkThreshold = sensitivity.jerkThreshold;

  double _jerkThreshold;
  int _continuousCount = 0;

  /// Update sensitivity at runtime without recreating the analyzer.
  void updateSensitivity(TheftSensitivity sensitivity) {
    _jerkThreshold = sensitivity.jerkThreshold;
  }

  /// Returns `true` if the magnitude-squared acceleration exceeds the
  /// jerk threshold — indicates a sudden snatch/grab.
  bool detectJerk(double x, double y, double z) {
    final double magnitudeSquared = x * x + y * y + z * z;
    return magnitudeSquared > _jerkThreshold;
  }

  /// Accumulates continuous-motion samples.
  /// Returns `true` once [TheftConstants.continuousSampleCount] samples
  /// have exceeded [TheftConstants.continuousThreshold].
  bool detectContinuous(double x, double y, double z) {
    final double sumAbs = x.abs() + y.abs() + z.abs();
    if (sumAbs > TheftConstants.continuousThreshold) {
      _continuousCount++;
    }
    return _continuousCount >= TheftConstants.continuousSampleCount;
  }

  /// Reset internal counter — call after a lock trigger or window expiry.
  void reset() {
    _continuousCount = 0;
  }
}
