import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_router/core/models/device.dart';
import 'package:nexus_router/core/utils/formatters.dart';

void main() {
  test('device round-trips through its sqlite map', () {
    final now = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final device = Device(
      mac: 'AA:BB:CC:11:22:33',
      name: "Shanto's Phone",
      vendor: 'Xiaomi Communications',
      type: DeviceType.phone,
      ip: '192.168.0.105',
      online: true,
      favorite: true,
      trusted: true,
      blocked: false,
      group: DeviceGroup.personal,
      notes: 'Primary phone',
      firstSeen: now.subtract(const Duration(days: 30)),
      lastSeen: now,
    );

    final restored = Device.fromMap(device.toMap());

    expect(restored.mac, device.mac);
    expect(restored.name, device.name);
    expect(restored.type, DeviceType.phone);
    expect(restored.group, DeviceGroup.personal);
    expect(restored.online, isTrue);
    expect(restored.favorite, isTrue);
    expect(restored.trusted, isTrue);
    expect(restored.blocked, isFalse);
    expect(restored.firstSeen, device.firstSeen);
    expect(restored.lastSeen, device.lastSeen);
  });

  test('named unclassified devices are not treated as unknown', () {
    Device build(String name) => Device(
      mac: 'AA:BB:CC:11:22:33',
      name: name,
      vendor: 'Unknown vendor',
      type: DeviceType.unknown,
      ip: '—',
      online: true,
      favorite: false,
      trusted: false,
      blocked: false,
      group: DeviceGroup.unknown,
      notes: '',
      firstSeen: DateTime.now(),
      lastSeen: DateTime.now(),
    );

    expect(build('Unknown device').isUnknown, isTrue);
    expect(build('Unknown Device 2').isUnknown, isTrue);
    expect(build('SHANTO').isUnknown, isFalse);
  });

  test('uptime formatting is compact and readable', () {
    expect(
      formatUptime(const Duration(days: 6, hours: 14, minutes: 22)),
      '6d 14h',
    );
    expect(formatUptime(const Duration(hours: 5, minutes: 7)), '5h 7m');
    expect(formatUptime(const Duration(minutes: 9)), '9m');
  });

  test('time ago handles recent events', () {
    expect(
      timeAgo(DateTime.now().subtract(const Duration(seconds: 5))),
      'Just now',
    );
    expect(
      timeAgo(DateTime.now().subtract(const Duration(minutes: 8))),
      '8m ago',
    );
  });
}
