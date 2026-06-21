class SmsTransaction {
  final double amount;
  final String type; // 'debit' or 'credit'
  final String sender;
  final String timestamp;
  final String rawText;
  final String source; // Always 'sms'
  final double confidence; // 0.0 - 1.0

  SmsTransaction({
    required this.amount,
    required this.type,
    required this.sender,
    required this.timestamp,
    required this.rawText,
    this.source = 'sms',
    required this.confidence,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'type': type,
      'sender': sender,
      'timestamp': timestamp,
      'raw_text': rawText,
      'source': source,
      'confidence': confidence,
    };
  }
}
