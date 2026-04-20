import 'package:ocsafe_cyberguard/services/threat_intel.dart';

/// Result of a local reputation lookup.
class ReputationResult {
  /// True if the hash/package is confirmed malware — override scoring to 100.
  final bool isKnownMalware;

  /// True if the hash/package is confirmed safe — cap score at 20.
  final bool isKnownSafe;

  /// Human-readable label for the reputation verdict.
  final String label;

  const ReputationResult({
    required this.isKnownMalware,
    required this.isKnownSafe,
    required this.label,
  });

  static const ReputationResult unknown = ReputationResult(
    isKnownMalware: false,
    isKnownSafe: false,
    label: 'Unknown',
  );
}

/// Lightweight local reputation service — zero network latency.
///
/// Checks apps against:
///   1. Known-malicious SHA-256 hash table (from [ThreatIntel])
///   2. Known-safe SHA-256 hash table (from [ThreatIntel])
///   3. Known-malicious package name DB (from [ThreatIntel])
///   4. Trusted package whitelist (from [ThreatIntel])
///
/// This runs before heuristics. If a definitive verdict is found (known-malware
/// or known-safe), the caller should use it to **override** the heuristic score
/// rather than running the full pipeline.
///
/// For cloud-based reputation checks, [VirusTotalService] is the separate
/// on-demand layer that already exists in the codebase.
class ReputationService {
  static final Map<String, ReputationResult> _cache = {};

  /// Perform a local reputation lookup.
  ///
  /// [packageName] — the Android package identifier.  
  /// [apkHash]     — optional SHA-256 hash of the APK (from [ApkHashService]).
  ///
  /// Returns a [ReputationResult] with override guidance.
  ReputationResult check({
    required String packageName,
    String? apkHash,
  }) {
    final cacheKey = '$packageName:${apkHash ?? ""}';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    final result = _evaluate(packageName: packageName, apkHash: apkHash);
    _cache[cacheKey] = result;
    return result;
  }

  ReputationResult _evaluate({
    required String packageName,
    String? apkHash,
  }) {
    // ── Priority 1: Hash-based (most reliable) ────────────────────────────
    if (apkHash != null && apkHash.isNotEmpty) {
      if (ThreatIntel.isKnownMaliciousHash(apkHash)) {
        return const ReputationResult(
          isKnownMalware: true,
          isKnownSafe: false,
          label: 'Known malware (hash match)',
        );
      }
      if (ThreatIntel.isKnownSafeHash(apkHash)) {
        return const ReputationResult(
          isKnownMalware: false,
          isKnownSafe: true,
          label: 'Verified safe (hash match)',
        );
      }
    }

    // ── Priority 2: Package name — known malware ──────────────────────────
    if (ThreatIntel.isMaliciousPackage(packageName)) {
      return const ReputationResult(
        isKnownMalware: true,
        isKnownSafe: false,
        label: 'Known malware (package match)',
      );
    }

    // ── Priority 3: Package name — trusted whitelist ──────────────────────
    if (ThreatIntel.isTrustedPackage(packageName) ||
        ThreatIntel.isTrustedNamespace(packageName)) {
      return const ReputationResult(
        isKnownMalware: false,
        isKnownSafe: true,
        label: 'Trusted package',
      );
    }

    return ReputationResult.unknown;
  }

  /// Clear the reputation cache (e.g. between scan sessions).
  void clearCache() => _cache.clear();
}
