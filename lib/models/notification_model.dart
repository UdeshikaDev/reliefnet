/// An in-app notification sent to a user (victim, volunteer, or admin).
/// Displayed on the Notifications screen and triggered via FCM in Phase 2.
class NotificationModel {
  final String notificationId;
  final String recipientUid;

  /// Notification type key. Examples:
  /// `task_assigned`, `request_accepted`, `request_completed`,
  /// `volunteer_approved`, `broadcast`, `parcel_packed`.
  final String type;

  final String title;
  final String body;
  final bool isRead;

  /// Optional navigation target — passed to GoRouter on tap.
  final String? routePath;

  final DateTime createdAt;

  const NotificationModel({
    required this.notificationId,
    required this.recipientUid,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.routePath,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return NotificationModel(
      notificationId: id ?? map['notificationId'] as String,
      recipientUid: map['recipientUid'] as String,
      type: map['type'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      isRead: map['isRead'] as bool? ?? false,
      routePath: map['routePath'] as String?,
      createdAt: _parseDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'notificationId': notificationId,
        'recipientUid': recipientUid,
        'type': type,
        'title': title,
        'body': body,
        'isRead': isRead,
        'routePath': routePath,
        'createdAt': createdAt.toIso8601String(),
      };

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        notificationId: notificationId,
        recipientUid: recipientUid,
        type: type,
        title: title,
        body: body,
        isRead: isRead ?? this.isRead,
        routePath: routePath,
        createdAt: createdAt,
      );
}

DateTime _parseDate(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  return DateTime.now();
}