import 'dart:math';

import '../core/models/device.dart';
import '../core/models/network_event.dart';
import '../core/models/router_status.dart';
import 'router_adapter.dart';

/// Silently honest demo adapter.
///
/// Every value returned here is synthetic. The UI marks it with DEMO badges so
/// demo data is never mistaken for a live router reading.
class DemoRouterAdapter implements RouterAdapter {
  DemoRouterAdapter() {
    _bootedAt = DateTime.now().subtract(
      const Duration(days: 6, hours: 14, minutes: 22),
    );
  }

  final Random _random = Random();
  late final DateTime _bootedAt;

  @override
  String get label => 'Demo · TL-WR840N';

  @override
  bool get isDemo => true;

  @override
  RouterCapabilities get capabilities => const RouterCapabilities(
    accessControl: true,
    macFilter: true,
    guestNetwork: true,
    bandwidthControl: true,
    wifiSchedule: true,
    ipMacBinding: true,
    wirelessStats: true,
    perDeviceUsage: false,
  );

  List<Device> _devices() {
    final now = DateTime.now();
    Device build({
      required String mac,
      required String name,
      required String vendor,
      required DeviceType type,
      required String ip,
      required bool online,
      DeviceGroup group = DeviceGroup.unknown,
      bool favorite = false,
      bool trusted = false,
      String notes = '',
      int firstSeenDays = 30,
      int offlineHours = 0,
    }) {
      return Device(
        mac: mac,
        name: name,
        vendor: vendor,
        type: type,
        ip: ip,
        online: online,
        favorite: favorite,
        trusted: trusted,
        blocked: false,
        group: group,
        notes: notes,
        firstSeen: now.subtract(Duration(days: firstSeenDays)),
        lastSeen: online ? now : now.subtract(Duration(hours: offlineHours)),
      );
    }

    return [
      build(
        mac: 'AA:BB:CC:11:22:33',
        name: "Shanto's Phone",
        vendor: 'Xiaomi Communications',
        type: DeviceType.phone,
        ip: '192.168.0.105',
        online: true,
        group: DeviceGroup.personal,
        favorite: true,
        trusted: true,
        notes: 'Primary phone',
        firstSeenDays: 180,
      ),
      build(
        mac: '3C:22:FB:7A:10:4D',
        name: "Ayesha's iPhone",
        vendor: 'Apple, Inc.',
        type: DeviceType.phone,
        ip: '192.168.0.112',
        online: true,
        group: DeviceGroup.family,
        trusted: true,
        firstSeenDays: 120,
      ),
      build(
        mac: 'D8:44:89:1A:2B:3C',
        name: 'Living Room TV',
        vendor: 'Samsung Electronics',
        type: DeviceType.tv,
        ip: '192.168.0.118',
        online: true,
        group: DeviceGroup.family,
        firstSeenDays: 200,
      ),
      build(
        mac: '5C:F9:38:00:AA:71',
        name: 'Work Laptop',
        vendor: 'Dell Inc.',
        type: DeviceType.laptop,
        ip: '192.168.0.101',
        online: true,
        group: DeviceGroup.work,
        trusted: true,
        firstSeenDays: 240,
      ),
      build(
        mac: '24:0A:C4:9F:88:01',
        name: 'ESP32 Sensor',
        vendor: 'Espressif Inc.',
        type: DeviceType.iot,
        ip: '192.168.0.130',
        online: true,
        group: DeviceGroup.iot,
        firstSeenDays: 90,
      ),
      build(
        mac: '7E:11:9A:00:44:22',
        name: 'Unknown Device',
        vendor: 'Private / randomized MAC',
        type: DeviceType.unknown,
        ip: '192.168.0.140',
        online: true,
        firstSeenDays: 1,
      ),
      build(
        mac: 'B0:BE:76:12:34:56',
        name: 'Kids Tablet',
        vendor: 'Samsung Electronics',
        type: DeviceType.tablet,
        ip: '192.168.0.120',
        online: false,
        group: DeviceGroup.family,
        firstSeenDays: 150,
        offlineHours: 1,
      ),
      build(
        mac: '62:3A:88:11:22:99',
        name: 'Guest Phone',
        vendor: 'Private / randomized MAC',
        type: DeviceType.phone,
        ip: '192.168.0.150',
        online: false,
        group: DeviceGroup.guest,
        firstSeenDays: 5,
        offlineHours: 4,
      ),
      build(
        mac: '00:1B:A9:11:22:33',
        name: 'Office Printer',
        vendor: 'Brother Industries',
        type: DeviceType.printer,
        ip: '192.168.0.125',
        online: true,
        group: DeviceGroup.work,
        firstSeenDays: 300,
      ),
      build(
        mac: '84:0D:8E:55:66:77',
        name: 'Smart Bulb',
        vendor: 'Espressif Inc.',
        type: DeviceType.iot,
        ip: '192.168.0.132',
        online: true,
        group: DeviceGroup.iot,
        firstSeenDays: 60,
      ),
      build(
        mac: 'A6:77:09:1C:33:8B',
        name: 'Unknown Device 2',
        vendor: 'Private / randomized MAC',
        type: DeviceType.unknown,
        ip: '192.168.0.141',
        online: false,
        firstSeenDays: 3,
        offlineHours: 20,
      ),
      build(
        mac: '1C:3B:F3:44:55:66',
        name: 'Bedroom TV',
        vendor: 'LG Electronics',
        type: DeviceType.tv,
        ip: '192.168.0.119',
        online: true,
        group: DeviceGroup.family,
        firstSeenDays: 75,
      ),
    ];
  }

  @override
  Future<List<Device>> fetchDevices() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return _devices();
  }

  @override
  Future<RouterStatus> fetchStatus() async {
    await Future<void>.delayed(const Duration(milliseconds: 160));
    final devices = _devices();
    final online = devices.where((device) => device.online).length;
    final unknown = devices.where((device) => device.isUnknown).length;
    final now = DateTime.now();

    return RouterStatus(
      model: 'TL-WR840N',
      firmware: '6.20',
      mode: 'Router',
      host: '192.168.0.1',
      ports: 4,
      uptime: now.difference(_bootedAt),
      downloadMbps: 12.5 + _random.nextDouble() * 11,
      uploadMbps: 2.1 + _random.nextDouble() * 3.4,
      connectedDevices: online,
      unknownDevices: unknown,
      lastUpdated: now,
      reachable: true,
      demo: true,
      capabilities: capabilities,
      ssid: 'NEXUS_HOME',
      band: '2.4 GHz',
      channel: '6',
      security: 'WPA2-PSK',
      guestNetworkEnabled: true,
      wanIp: '103.42.18.77',
      wanConnected: true,
      trafficSupported: true,
    );
  }

  @override
  Future<List<NetworkEvent>> seedEvents() async {
    final now = DateTime.now();
    NetworkEvent event(
      EventKind kind,
      EventSeverity severity,
      String title,
      String detail,
      Duration ago, {
      String? mac,
    }) {
      return NetworkEvent(
        mac: mac,
        kind: kind,
        severity: severity,
        title: title,
        detail: detail,
        createdAt: now.subtract(ago),
      );
    }

    return [
      event(
        EventKind.unknownJoined,
        EventSeverity.warning,
        'Unknown device joined',
        '7E:11:9A:00:44:22 · 192.168.0.140',
        const Duration(minutes: 8),
        mac: '7E:11:9A:00:44:22',
      ),
      event(
        EventKind.joined,
        EventSeverity.success,
        "Ayesha's iPhone connected",
        '3C:22:FB:7A:10:4D · 192.168.0.112',
        const Duration(minutes: 26),
        mac: '3C:22:FB:7A:10:4D',
      ),
      event(
        EventKind.left,
        EventSeverity.info,
        'Kids Tablet disconnected',
        'B0:BE:76:12:34:56',
        const Duration(hours: 1, minutes: 10),
        mac: 'B0:BE:76:12:34:56',
      ),
      event(
        EventKind.unblocked,
        EventSeverity.info,
        'Guest Phone unblocked',
        'Policy change verified on router',
        const Duration(hours: 2, minutes: 5),
        mac: '62:3A:88:11:22:99',
      ),
      event(
        EventKind.blocked,
        EventSeverity.warning,
        'Guest Phone blocked',
        'Action verified on router',
        const Duration(hours: 2, minutes: 10),
        mac: '62:3A:88:11:22:99',
      ),
      event(
        EventKind.alert,
        EventSeverity.warning,
        'Unknown MAC detected',
        'A6:77:09:1C:33:8B came online',
        const Duration(hours: 3),
        mac: 'A6:77:09:1C:33:8B',
      ),
      event(
        EventKind.joined,
        EventSeverity.success,
        'Smart Bulb connected',
        '84:0D:8E:55:66:77 · 192.168.0.132',
        const Duration(hours: 5),
        mac: '84:0D:8E:55:66:77',
      ),
      event(
        EventKind.system,
        EventSeverity.info,
        'Monitoring session started',
        'NEXUS ROUTER 1.0.0 · demo mode',
        const Duration(hours: 6),
      ),
    ];
  }

  @override
  Future<bool> setBlocked(String mac, bool blocked, {String? name}) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return true;
  }

  @override
  void dispose() {}
}
