import '../utils/enums.dart';

enum EventKind {
  joined,
  left,
  unknownJoined,
  blocked,
  unblocked,
  alert,
  system,
}

enum EventSeverity { info, success, warning, danger }

class NetworkEvent {
  final int? id;
  final String? mac;
  final EventKind kind;
  final EventSeverity severity;
  final String title;
  final String detail;
  final DateTime createdAt;

  const NetworkEvent({
    this.id,
    this.mac,
    required this.kind,
    required this.severity,
    required this.title,
    required this.detail,
    required this.createdAt,
  });

  Map<String, Object?> toMap() {
    return {
      'mac': mac,
      'kind': kind.name,
      'severity': severity.name,
      'title': title,
      'detail': detail,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory NetworkEvent.fromMap(Map<String, Object?> map) {
    return NetworkEvent(
      id: map['id'] as int?,
      mac: map['mac'] as String?,
      kind: enumByName(EventKind.values, map['kind'], EventKind.system),
      severity: enumByName(
        EventSeverity.values,
        map['severity'],
        EventSeverity.info,
      ),
      title: (map['title'] as String?) ?? 'Event',
      detail: (map['detail'] as String?) ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['created_at'] as int? ?? 0,
      ),
    );
  }
}
