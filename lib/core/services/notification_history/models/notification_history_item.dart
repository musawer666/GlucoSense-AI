import 'package:equatable/equatable.dart';

/// Immutable item representing a delivered notification stored in Hive history.
class NotificationHistoryItem extends Equatable {
  const NotificationHistoryItem({
    required this.title,
    required this.body,
    required this.channelId,
    required this.timestamp,
  });

  final String title;
  final String body;
  final String channelId;
  final DateTime timestamp;

  /// Safe factory from a dynamic Hive map.
  /// Tolerates missing / malformed fields to avoid crashing the UI.
  factory NotificationHistoryItem.fromMap(Map<dynamic, dynamic> map) {
    final rawTs = map['timestamp'];
    DateTime parsedTs;
    if (rawTs is String) {
      parsedTs = DateTime.tryParse(rawTs) ?? DateTime.now();
    } else if (rawTs is DateTime) {
      parsedTs = rawTs;
    } else {
      parsedTs = DateTime.now();
    }

    return NotificationHistoryItem(
      title: (map['title'] ?? '').toString(),
      body: (map['body'] ?? '').toString(),
      channelId: (map['channelId'] ?? 'reminders_channel').toString(),
      timestamp: parsedTs,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'body': body,
        'channelId': channelId,
        'timestamp': timestamp.toIso8601String(),
      };

  @override
  List<Object?> get props => [title, body, channelId, timestamp];
}
