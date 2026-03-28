import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ocsafe_cyberguard/models/vt_result.dart';
import 'package:ocsafe_cyberguard/models/app_features.dart';

/// VirusTotal cloud reputation service with FIFO rate-limiting queue.
///
/// Free tier: 4 lookups/minute, 500/day. This service enforces a minimum
/// delay of 15 seconds between requests to stay well within limits.
class VirusTotalService {
  static const String _baseUrl = 'https://www.virustotal.com/api/v3';
  static const Duration _minDelay = Duration(seconds: 15);
  static const Duration _httpTimeout = Duration(seconds: 5);

  final String apiKey;

  /// FIFO queue state.
  DateTime? _lastCallTime;
  final _queue = <Completer<VTResult?>>[];
  bool _processing = false;

  VirusTotalService({required this.apiKey});

  /// Whether we should bother calling VT for this app.
  ///
  /// Only calls VT if:
  ///   - App is sideloaded, OR
  ///   - Local score > 25 (worth verifying)
  bool shouldCheck(AppFeatures features, int localScore) {
    if (apiKey.isEmpty) return false;
    if (features.isPlayStoreApp && localScore <= 25) return false;
    if (features.isSideloaded) return true;
    return localScore > 25;
  }

  /// Check a file hash against VirusTotal. Returns null on error/timeout.
  ///
  /// Requests are queued and rate-limited (1 per 15 sec).
  Future<VTResult?> checkFileHash(
    String sha256, {
    required String packageName,
    String? versionCode,
  }) async {
    if (apiKey.isEmpty) return null;

    final completer = Completer<VTResult?>();
    _queue.add(completer);

    // Enqueue a task to process
    _enqueueTask(() async {
      try {
        final result = await _doHashLookup(
          sha256,
          packageName: packageName,
          versionCode: versionCode,
        );
        completer.complete(result);
      } catch (e) {
        debugPrint('[VT] Error checking hash $sha256: $e');
        completer.complete(null);
      }
    });

    return completer.future;
  }

  /// Merge VT results into a local threat score (ratio-based).
  ///
  /// Uses ratio of malicious/total instead of raw count to reduce
  /// false positives from single-engine detections.
  static int calculateVTScoreBoost(VTResult result) {
    final ratio = result.maliciousRatio;
    final suspiciousRatio = result.suspiciousRatio;

    int boost = 0;

    // Ratio-based scoring: prevents 1/70 engines from triggering +40
    if (ratio > 0.3) {
      boost += 40; // Strong consensus: malware
    } else if (ratio > 0.1) {
      boost += 25; // Moderate consensus
    } else if (ratio > 0) {
      boost += 10; // Weak signal: few engines flagged
    }

    // Suspicious signals (lower weight)
    if (suspiciousRatio > 0.1) {
      boost += 10;
    } else if (suspiciousRatio > 0) {
      boost += 5;
    }

    return boost;
  }

  // ─── Internal rate-limited queue ──────────────────────────────────────

  void _enqueueTask(Future<void> Function() task) {
    if (_processing) return;
    _processQueue(task);
  }

  Future<void> _processQueue(Future<void> Function() task) async {
    _processing = true;

    try {
      // Rate limit: wait until enough time has elapsed since last call
      if (_lastCallTime != null) {
        final elapsed = DateTime.now().difference(_lastCallTime!);
        if (elapsed < _minDelay) {
          await Future.delayed(_minDelay - elapsed);
        }
      }

      _lastCallTime = DateTime.now();
      await task();
    } finally {
      _processing = false;
    }
  }

  Future<VTResult?> _doHashLookup(
    String sha256, {
    required String packageName,
    String? versionCode,
  }) async {
    try {
      debugPrint('DEBUG [VT HTTP]: Sending GET to VT api/v3/files/$sha256');
      final uri = Uri.parse('$_baseUrl/files/$sha256');
      final response = await http.get(
        uri,
        headers: {
          'x-apikey': apiKey,
          'Accept': 'application/json',
        },
      ).timeout(_httpTimeout);

      debugPrint('DEBUG [VT HTTP]: Received status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final attrs = body['data']?['attributes'] as Map<String, dynamic>?;
        if (attrs == null) return null;

        final stats = attrs['last_analysis_stats'] as Map<String, dynamic>?;
        if (stats == null) return null;

        return VTResult(
          malicious: (stats['malicious'] as int?) ?? 0,
          suspicious: (stats['suspicious'] as int?) ?? 0,
          undetected: (stats['undetected'] as int?) ?? 0,
          harmless: (stats['harmless'] as int?) ?? 0,
          checkedAt: DateTime.now(),
          hash: sha256,
          packageName: packageName,
          versionCode: versionCode,
        );
      } else if (response.statusCode == 404) {
        // Not found in VT — not necessarily safe, just unknown
        debugPrint('[VT] Hash $sha256 not found in VirusTotal database.');
        return null;
      } else {
        debugPrint(
            '[VT] API returned status ${response.statusCode} for $sha256');
        return null;
      }
    } on TimeoutException {
      debugPrint('[VT] Request timed out for hash $sha256');
      return null;
    } catch (e) {
      debugPrint('[VT] Network error for hash $sha256: $e');
      return null;
    }
  }
}
