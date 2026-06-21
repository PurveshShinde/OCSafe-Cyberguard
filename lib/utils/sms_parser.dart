import 'package:ocsafe_cyberguard/models/sms_transaction.dart';

class SmsParser {
  static SmsTransaction? parseSms(String address, String body, String timestamp) {
    final text = body.toLowerCase();

    // 1. Strict Exclusion Filtering
    if (!(text.contains('₹') || text.contains('inr'))) return null;
    
    if (!(text.contains('debited') ||
          text.contains('credited') ||
          text.contains('upi') ||
          text.contains('transferred'))) return null;

    if (text.contains('otp') ||
        text.contains('offer') ||
        text.contains('loan')) return null;

    // 2. Amount Extraction
    final rupeeRegex = RegExp(r'₹\s?([\d,]+(?:\.\d+)?)', caseSensitive: false);
    final inrRegex = RegExp(r'inr\s?([\d,]+(?:\.\d+)?)', caseSensitive: false);
    
    Match? match = rupeeRegex.firstMatch(text);
    match ??= inrRegex.firstMatch(text);
    
    if (match == null || match.group(1) == null) return null;

    String amountStr = match.group(1)!.replaceAll(',', '');
    double amount = double.tryParse(amountStr) ?? 0.0;
    
    if (amount <= 0) return null;

    // 3. Normalize Type Detection
    String type = text.contains('debited') ? 'debit' :
                  text.contains('credited') ? 'credit' : 'unknown';

    // 4. Sender Extraction (Address + Text context)
    String sender = address;
    final upperAddress = address.toUpperCase();
    final upperText = body.toUpperCase();
    
    if (upperAddress.contains("SBI") || upperText.contains("SBI")) {
      sender = "SBI";
    } else if (upperAddress.contains("HDFC") || upperText.contains("HDFC")) {
      sender = "HDFC";
    } else if (upperAddress.contains("ICICI") || upperText.contains("ICICI")) {
      sender = "ICICI";
    } else if (upperAddress.contains("AXIS") || upperText.contains("AXIS")) {
      sender = "Axis Bank";
    } else if (upperAddress.contains("PNB") || upperText.contains("PNB")) {
      sender = "PNB";
    }

    double confidence = 0.5; 
    if (type != 'unknown' && text.contains('upi')) {
      confidence = 0.9;
    } else if (type != 'unknown') {
      confidence = 0.8;
    }

    return SmsTransaction(
      amount: amount,
      type: type,
      sender: sender,
      timestamp: timestamp,
      rawText: body,
      confidence: confidence,
    );
  }
}
