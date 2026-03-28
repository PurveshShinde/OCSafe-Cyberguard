import 'package:flutter/services.dart';

/// Flutter-side wrapper for the platform channel that computes
/// SHA-256 hashes of installed APKs.
///
/// Uses `publicSourceDir` (primary) and `splitSourceDirs` (fallback)
/// on the native side to handle split APKs on newer Android versions.
class ApkHashService {
  static const MethodChannel _channel =
      MethodChannel('com.ocsafe.cyberguard/apk_hash');

  /// Returns the SHA-256 hex hash of the base APK for [packageName].
  ///
  /// Returns `null` if the package is not found or hashing fails.
  Future<String?> getApkHash(String packageName) async {
    try {
      final result = await _channel.invokeMethod<String>(
        'getApkHash',
        {'packageName': packageName},
      );
      return result;
    } on PlatformException catch (e) {
      // Package not found or permission denied
      if (e.code != 'NOT_FOUND') {
        // Only log unexpected errors
        // ignore: avoid_print
        print('[ApkHash] Error hashing $packageName: ${e.message}');
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('[ApkHash] Unexpected error for $packageName: $e');
      return null;
    }
  }
}
