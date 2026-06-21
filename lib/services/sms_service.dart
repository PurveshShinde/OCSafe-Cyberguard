import 'package:permission_handler/permission_handler.dart';
import 'package:telephony/telephony.dart';
import 'package:ocsafe_cyberguard/models/sms_transaction.dart';
import 'package:ocsafe_cyberguard/utils/sms_parser.dart';

class SmsService {
  final Telephony _telephony = Telephony.instance;

  /// Requests the necessary SMS permissions.
  Future<bool> requestPermissions() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  /// Checks if SMS permissions are currently granted.
  Future<bool> hasPermissions() async {
    return await Permission.sms.isGranted;
  }

  /// Fetches recent SMS messages, filters and parses them for transactions.
  Future<List<SmsTransaction>> getRecentTransactions() async {
    bool hasPermission = await hasPermissions();
    if (!hasPermission) {
      hasPermission = await requestPermissions();
      if (!hasPermission) {
        throw Exception("SMS permission denied.");
      }
    }

    try {
      // Fetch inbox messages without filter for Android 12+ safety
      final messages = await _telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );

      List<SmsTransaction> transactions = [];

      for (var msg in messages) {
        if (transactions.length >= 20) break; // Limit to last 20 valid transactions
        
        final body = msg.body ?? '';
        final address = msg.address ?? 'Unknown';
        final dateInt = msg.date;
        
        String timestamp = '';
        if (dateInt != null) {
          timestamp = DateTime.fromMillisecondsSinceEpoch(dateInt).toIso8601String();
        }

        final transaction = SmsParser.parseSms(address, body, timestamp);
        if (transaction != null) {
          transactions.add(transaction);
        }
      }

      return transactions;
    } catch (e) {
      // Return empty or rethrow based on preference
      return [];
    }
  }
}
