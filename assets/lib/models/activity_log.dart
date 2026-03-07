/// A logged security event.
class ActivityLog {
  final int? id;
  final String message;
  final ActivityType type;
  final DateTime timestamp;

  const ActivityLog({
    this.id,
    required this.message,
    required this.type,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ActivityLog.fromMap(Map<String, dynamic> map) {
    return ActivityLog(
      id: map['id'] as int?,
      message: map['message'] as String,
      type: ActivityType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ActivityType.scan,
      ),
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}

enum ActivityType { scan, threat, permission, protection }
