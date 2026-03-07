import 'dart:convert';
import 'package:flutter/services.dart';

class ThreatIntel {
  static final ThreatIntel _instance = ThreatIntel._internal();

  factory ThreatIntel() => _instance;

  ThreatIntel._internal();

  List<String> _maliciousPackages = [];
  List<String> _maliciousDomains = [];
  List<List<String>> _dangerousPermissionSets = [];

  bool _isLoaded = false;

  List<String> get maliciousPackages => _maliciousPackages;
  List<String> get maliciousDomains => _maliciousDomains;
  List<List<String>> get dangerousPermissionSets => _dangerousPermissionSets;

  /// Loads the database at app startup.
  Future<void> loadDatabase() async {
    if (_isLoaded) return;

    try {
      final String jsonString =
          await rootBundle.loadString('assets/threat_signatures.json');
      final Map<String, dynamic> data = jsonDecode(jsonString);

      _maliciousPackages = List<String>.from(data['malicious_packages'] ?? []);
      _maliciousDomains = List<String>.from(data['malicious_domains'] ?? []);
      
      if (data['dangerous_permission_sets'] != null) {
         _dangerousPermissionSets = (data['dangerous_permission_sets'] as List)
            .map((item) => List<String>.from(item))
            .toList();
      }

      _isLoaded = true;
    } catch (e) {
      // In a real app we might log this to a crash reporter.
      print('Failed to load threat intelligence database: $e');
    }
  }
}
