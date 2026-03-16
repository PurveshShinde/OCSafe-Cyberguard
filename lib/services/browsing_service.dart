import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class BrowsingService {
  Set<String> _blacklist = {};
  bool _loaded = false;

  Future<void> loadBlacklist() async {
    if (_loaded) return;

    try {
      final jsonStr = await rootBundle.loadString(
        'assets/phishing_blacklist.json',
      );

      final List<dynamic> domains = json.decode(jsonStr);

      _blacklist = domains.map((e) => e.toString().toLowerCase()).toSet();

      _loaded = true;
    } catch (_) {
      _blacklist = {};

      _loaded = true;
    }
  }

  bool isPhishingUrl(String url) {
    final domain = _extractDomain(url);

    if (domain.isEmpty) return false;

    for (final blocked in _blacklist) {
      if (domain == blocked) return true;

      if (domain.endsWith('.$blocked')) return true;
    }

    return false;
  }

  Future<BrowsingResult> openUrlSafely(String url) async {
    await loadBlacklist();

    if (isPhishingUrl(url)) {
      return BrowsingResult(
        url: url,
        isBlocked: true,
        reason: 'Blocked: domain found in phishing blacklist.',
      );
    }

    try {
      final uri = Uri.parse(_normalizeUrl(url));

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      return BrowsingResult(url: url, isBlocked: false, opened: launched);
    } catch (e) {
      return BrowsingResult(
        url: url,
        isBlocked: false,
        opened: false,
        reason: e.toString(),
      );
    }
  }

  String _normalizeUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    return 'https://$url';
  }

  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(_normalizeUrl(url));

      final host = uri.host.toLowerCase();

      if (host.startsWith('www.')) {
        return host.substring(4);
      }

      return host;
    } catch (_) {
      return '';
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
