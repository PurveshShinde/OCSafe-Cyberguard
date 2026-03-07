import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';

class SignatureScanner {
  // Singleton pattern for shared memory instance
  static final SignatureScanner _instance = SignatureScanner._internal();
  factory SignatureScanner() => _instance;
  SignatureScanner._internal();

  Set<String> _maliciousPackages = {};
  Set<String> _trustedPackages = {};

  bool _isInitialized = false;

  /// Loads the signature database into memory sets for O(1) lookups
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final String jsonString = await rootBundle.loadString('assets/malware_signatures.json');
      final Map<String, dynamic> data = jsonDecode(jsonString);

      if (data['malicious_packages'] != null) {
        _maliciousPackages = Set<String>.from(data['malicious_packages']);
      }
      if (data['trusted_packages'] != null) {
        _trustedPackages = Set<String>.from(data['trusted_packages']);
      }

      _isInitialized = true;
      debugPrint('SignatureScanner initialized: ${_maliciousPackages.length} malicious pkgs, ${_trustedPackages.length} trusted pkgs.');
    } catch (e) {
      debugPrint('Failed to load malware signatures: $e');
    }
  }

  bool isMaliciousPackage(String packageName) {
    if (!_isInitialized) return false;
    return _maliciousPackages.contains(packageName);
  }

  bool isTrustedPackage(String packageName) {
    if (!_isInitialized) return false;
    return _trustedPackages.contains(packageName);
  }
  
  Set<String> get trustedPackages => _trustedPackages;
}
