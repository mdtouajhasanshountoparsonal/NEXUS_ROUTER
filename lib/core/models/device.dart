import '../utils/enums.dart';

enum DeviceType { phone, tablet, laptop, tv, iot, printer, unknown }

enum DeviceGroup { personal, family, guest, work, iot, unknown }

class Device {
  final String mac;
  final String name;
  final String vendor;
  final DeviceType type;
  final String ip;
  final bool online;
  final bool favorite;
  final bool trusted;
  final bool blocked;
  final DeviceGroup group;
  final String notes;
  final DateTime firstSeen;
  final DateTime lastSeen;

  const Device({
    required this.mac,
    required this.name,
    required this.vendor,
    required this.type,
    required this.ip,
    required this.online,
    required this.favorite,
    required this.trusted,
    required this.blocked,
    required this.group,
    required this.notes,
    required this.firstSeen,
    required this.lastSeen,
  });

  String get id => mac;

  bool get isUnknown {
    if (type != DeviceType.unknown) return false;
    final normalized = name.toLowerCase();
    return normalized.startsWith('unknown device') ||
        normalized.startsWith('unnamed');
  }

  Device copyWith({
    String? mac,
    String? name,
    String? vendor,
    DeviceType? type,
    String? ip,
    bool? online,
    bool? favorite,
    bool? trusted,
    bool? blocked,
    DeviceGroup? group,
    String? notes,
    DateTime? firstSeen,
    DateTime? lastSeen,
  }) {
    return Device(
      mac: mac ?? this.mac,
      name: name ?? this.name,
      vendor: vendor ?? this.vendor,
      type: type ?? this.type,
      ip: ip ?? this.ip,
      online: online ?? this.online,
      favorite: favorite ?? this.favorite,
      trusted: trusted ?? this.trusted,
      blocked: blocked ?? this.blocked,
      group: group ?? this.group,
      notes: notes ?? this.notes,
      firstSeen: firstSeen ?? this.firstSeen,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'mac': mac,
      'name': name,
      'vendor': vendor,
      'type': type.name,
      'ip': ip,
      'online': online ? 1 : 0,
      'favorite': favorite ? 1 : 0,
      'trusted': trusted ? 1 : 0,
      'blocked': blocked ? 1 : 0,
      'grp': group.name,
      'notes': notes,
      'first_seen': firstSeen.millisecondsSinceEpoch,
      'last_seen': lastSeen.millisecondsSinceEpoch,
    };
  }

  factory Device.fromMap(Map<String, Object?> map) {
    return Device(
      mac: map['mac'] as String,
      name: (map['name'] as String?) ?? 'Unknown device',
      vendor: (map['vendor'] as String?) ?? 'Unknown vendor',
      type: enumByName(DeviceType.values, map['type'], DeviceType.unknown),
      ip: (map['ip'] as String?) ?? '—',
      online: (map['online'] as int? ?? 0) == 1,
      favorite: (map['favorite'] as int? ?? 0) == 1,
      trusted: (map['trusted'] as int? ?? 0) == 1,
      blocked: (map['blocked'] as int? ?? 0) == 1,
      group: enumByName(DeviceGroup.values, map['grp'], DeviceGroup.unknown),
      notes: (map['notes'] as String?) ?? '',
      firstSeen: DateTime.fromMillisecondsSinceEpoch(
        map['first_seen'] as int? ?? 0,
      ),
      lastSeen: DateTime.fromMillisecondsSinceEpoch(
        map['last_seen'] as int? ?? 0,
      ),
    );
  }

  static String groupLabel(DeviceGroup group) {
    return switch (group) {
      DeviceGroup.personal => 'Personal',
      DeviceGroup.family => 'Family',
      DeviceGroup.guest => 'Guest',
      DeviceGroup.work => 'Work',
      DeviceGroup.iot => 'IoT',
      DeviceGroup.unknown => 'Unassigned',
    };
  }

  static String typeLabel(DeviceType type) {
    return switch (type) {
      DeviceType.phone => 'Phone',
      DeviceType.tablet => 'Tablet',
      DeviceType.laptop => 'Laptop',
      DeviceType.tv => 'Smart TV',
      DeviceType.iot => 'IoT device',
      DeviceType.printer => 'Printer',
      DeviceType.unknown => 'Unknown',
    };
  }
}
