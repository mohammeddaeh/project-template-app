import 'package:equatable/equatable.dart';

/// One push notification kept for later review — a [PushNotificationEvent]
/// with the two facts a list screen needs and the wire event does not carry:
/// when it arrived, and whether it has been opened.
///
/// Hand-written `toJson`/`fromJson` rather than `json_serializable` — same
/// reason `DeviceSessionModel` in `modules/multi_device/` avoids it: this
/// module ships disabled by default, and a codegen dependency must not force
/// a `build_runner` step on a project that never turns it on.
class NotificationCenterItem extends Equatable {
  const NotificationCenterItem({
    required this.id,
    required this.receivedAt,
    this.title,
    this.body,
    this.data = const {},
    this.read = false,
  });

  /// FCM message id — see `PushNotificationEvent.id`. Used to de-duplicate
  /// and to address a single row for `markRead`.
  final String id;

  final String? title;
  final String? body;

  /// The arbitrary payload the server attached — kept verbatim so a project
  /// can route a tap without this module knowing what any key means.
  final Map<String, dynamic> data;

  final DateTime receivedAt;
  final bool read;

  NotificationCenterItem copyWith({bool? read}) => NotificationCenterItem(
    id: id,
    title: title,
    body: body,
    data: data,
    receivedAt: receivedAt,
    read: read ?? this.read,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'data': data,
    'received_at': receivedAt.toIso8601String(),
    'read': read,
  };

  /// Returns `null` on a malformed record rather than throwing — one corrupt
  /// line must not blank the whole stored list. See `NotificationCenterStore`.
  static NotificationCenterItem? tryFromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final receivedAtRaw = json['received_at'];
    if (id is! String || receivedAtRaw is! String) return null;
    final receivedAt = DateTime.tryParse(receivedAtRaw);
    if (receivedAt == null) return null;

    final rawData = json['data'];
    return NotificationCenterItem(
      id: id,
      title: json['title'] as String?,
      body: json['body'] as String?,
      data: rawData is Map ? Map<String, dynamic>.from(rawData) : const {},
      receivedAt: receivedAt,
      read: json['read'] == true,
    );
  }

  @override
  List<Object?> get props => [id, title, body, data, receivedAt, read];
}
