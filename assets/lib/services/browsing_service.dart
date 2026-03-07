import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service for detecting phishing URLs and safe browsing.
class BrowsingService {
  List<String> _blacklist = [];
  bool _loaded = false;

  /// Loads the phishing blacklist from the assets.
  Future<void> loadBlacklist() async {
    if (_loaded) return;
    try {
      final jsonStr = await rootBundle.loadString('assets/phishing_blacklist.json');
      final List<dynamic> domains = json.decode(jsonStr);
      _blacklist = domains.cast<String>();
      _loaded = true;
    } catch (e) {
      _blacklist = [];
      _loaded = true;
    }
  }

  /// Checks if a URL is in the phishing blacklist.
  /// Returns true if the URL is potentially malicious.
  bool isPhishingUrl(String url) {
    final domain = _extractDomain(url).toLowerCase();
    return _blacklist.any(
      (blocked) => domain.contains(blocked.toLowerCase()),
    );
  }

  /// Opens a URL safely, checking against the blacklist first.
  /// Returns a result indicating if it was blocked or opened.
  Future<BrowsingResult> openUrlSafely(String url) async {
    await loadBlacklist();

    if (isPhishingUrl(url)) {
      return BrowsingResult(
        url: url,
        isBlocked: true,
        reason: 'This URL matches a known phishing domain.',
      );
    }

    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      return BrowsingResult(url: url, isBlocked: false, opened: launched);
    } catch (e) {
      return BrowsingResult(url: url, isBlocked: false, opened: false, reason: e.toString());
    }
  }

  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
      return uri.host;
    } catch (_) {
      return url;
    }
  }

  int get blacklistSize => _blacklist.length;
}

class BrowsingResult {
  final String url;
  final bool isBlocked;
  final bool opened;
  final String? reason;

  const BrowsingResult({
    required this.url,
    required this.isBlocked,
    this.opened = false,
    this.reason,
  });
}
