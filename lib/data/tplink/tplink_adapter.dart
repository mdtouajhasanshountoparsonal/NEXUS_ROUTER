import 'package:dio/dio.dart';

import '../../core/models/device.dart';
import '../../core/models/network_event.dart';
import '../../core/models/router_status.dart';
import '../router_adapter.dart';
import 'cgi_protocol.dart';
import 'oui.dart';
import 'tplink_client.dart';

const List<String> _wlanFields = [
  'name',
  'status',
  'X_TP_MACAddressControlRule',
  'MACAddressControlEnabled',
  'SSID',
  'X_TP_Band',
];

const List<String> _wlanDetailFields = [
  'name',
  'channel',
  'beaconType',
  'WPAEncryptionModes',
  'IEEE11iEncryptionModes',
  'WPAAuthenticationMode',
  'IEEE11iAuthenticationMode',
];

const List<String> _filterFields = [
  'Enabled',
  'MACAddress',
  'Description',
  'HostName',
];

const List<String> _assocFields = [
  'AssociatedDeviceMACAddress',
  'X_TP_TotalPacketsSent',
  'X_TP_TotalPacketsReceived',
  'X_TP_HostName',
];

/// Live adapter for the TL-WR840N v6 / RDPA firmware.
///
/// The firmware does not expose DHCP leases, wired clients or WAN byte
/// counters through the pages this app can reach, so those fields stay
/// unavailable rather than being invented.
class TplinkV6Adapter implements RouterAdapter {
  TplinkV6Adapter({
    required this.host,
    required String username,
    required String password,
    Dio? dio,
  }) : _client = TplinkClient(
         host: host,
         username: username,
         password: password,
         dio: dio,
       );

  final String host;
  final TplinkClient _client;

  _WlanInfo? _cachedWlan;
  DateTime? _cachedWlanAt;
  int _onlineCount = 0;
  int _unknownCount = 0;

  static const RouterCapabilities _capabilities = RouterCapabilities(
    accessControl: false,
    macFilter: true,
    guestNetwork: false,
    bandwidthControl: false,
    wifiSchedule: false,
    ipMacBinding: false,
    wirelessStats: true,
    perDeviceUsage: false,
  );

  @override
  String get label => 'TL-WR840N · live';

  @override
  bool get isDemo => false;

  @override
  RouterCapabilities get capabilities => _capabilities;

  @override
  Future<RouterStatus> fetchStatus() async {
    final response = await _client.execute(
      CgiRequest()
        ..read('MULTIMODE', const ['mode'])
        ..read('IGD_DEV_INFO', const [
          'softwareVersion',
          'hardwareVersion',
          'upTime',
        ])
        ..read('ETH_SWITCH', const ['numberOfVirtualPorts'])
        ..list('WAN_IP_CONN', const [])
        ..list('WAN_PPP_CONN', const [])
        ..list('LAN_WLAN', _wlanFields),
    );

    final multi = response.first(0);
    final device = response.first(1);
    final ethernet = response.first(2);
    final wlan = _applyWlan(response.objects(5));

    final wan = _parseWan(response.objects(3), response.objects(4));

    var channel = wlan?.channel ?? 0;
    var security = wlan?.security ?? 'Unknown';
    if (wlan != null) {
      try {
        final detail = await _client.execute(
          CgiRequest()..read('LAN_WLAN', _wlanDetailFields),
        );
        final object = _pickWlan(detail.objects(0));
        if (object != null) {
          channel = object.number('channel');
          security = _securityLabel(object);
        }
      } on RouterException catch (_) {
        // Keep the values from the status batch when the detail call fails.
      }
    }

    var guestNetwork = false;
    if (wlan != null) {
      try {
        final guest = await _client.execute(
          CgiRequest()..read('LAN_WLAN_MULTISSID', const [
            'MultiSSIDEnable',
          ], stack: wlan.stack),
        );
        guestNetwork = guest.first(0)?.flag('multissidenable') ?? false;
      } on RouterException catch (_) {
        guestNetwork = false;
      }
    }

    return RouterStatus(
      model: _modelName(device),
      firmware: _clean(device?['softwareversion']) ?? 'Unknown firmware',
      mode: _clean(multi?['mode']) ?? 'Router',
      host: host,
      ports: ethernet?.number('numberofvirtualports') ?? 4,
      uptime: Duration(seconds: device?.number('uptime') ?? 0),
      downloadMbps: 0,
      uploadMbps: 0,
      connectedDevices: _onlineCount,
      unknownDevices: _unknownCount,
      lastUpdated: DateTime.now(),
      reachable: true,
      demo: false,
      capabilities: _capabilities,
      ssid: wlan?.ssid ?? '',
      band: wlan?.band ?? '',
      channel: channel == 0 ? '' : channel.toString(),
      security: security,
      guestNetworkEnabled: guestNetwork,
      wanIp: wan.address,
      wanConnected: wan.connected,
      trafficSupported: false,
    );
  }

  @override
  Future<List<Device>> fetchDevices() async {
    final wlan = await _loadWlan();
    if (wlan == null) {
      throw const RouterProtocolException(
        'The router did not report a wireless interface.',
      );
    }

    try {
      await _client.execute(
        CgiRequest()..operation('ACT_WLAN_UPDATE_ASSOC', stack: wlan.stack),
      );
    } on CgiException catch (_) {
      // The refresh hint is optional; the tables below are still authoritative.
    }

    final response = await _client.execute(
      CgiRequest()
        ..selection(
          'LAN_WLAN_MACTABLEENTRY',
          _filterFields,
          parentStack: wlan.stack,
        )
        ..selection(
          'LAN_WLAN_ASSOC_DEV',
          _assocFields,
          parentStack: wlan.stack,
        ),
    );

    final entries = <String, _FilterEntry>{};
    for (final object in response.objects(0)) {
      final mac = normalizeMac(_clean(object['macaddress']) ?? '');
      if (!_validMac.hasMatch(mac)) continue;
      entries[mac] = _FilterEntry(
        mac: mac,
        stack: object.stack,
        enabled: object.flag('enabled'),
        description: _clean(object['description']) ?? '',
      );
    }

    final online = <String>{};
    final devices = <String, Device>{};
    for (final object in response.objects(1)) {
      final mac = normalizeMac(
        _clean(object['associateddevicemacaddress']) ?? '',
      );
      if (!_validMac.hasMatch(mac)) continue;
      online.add(mac);
      final entry = entries[mac];
      final hint = entry?.description.isNotEmpty == true
          ? entry!.description
          : _clean(object['x_tp_hostname']) ?? '';
      devices[mac] = _deviceFor(
        mac: mac,
        nameHint: hint,
        online: true,
        blocked: _isBlocked(entry, wlan),
      );
    }

    for (final entry in entries.values) {
      if (online.contains(entry.mac)) continue;
      devices[entry.mac] = _deviceFor(
        mac: entry.mac,
        nameHint: entry.description,
        online: false,
        blocked: _isBlocked(entry, wlan),
      );
    }

    _onlineCount = online.length;
    _unknownCount = devices.values.where((device) => device.isUnknown).length;

    return devices.values.toList(growable: false);
  }

  @override
  Future<bool> setBlocked(String mac, bool blocked, {String? name}) async {
    final target = normalizeMac(mac);
    if (!_validMac.hasMatch(target)) {
      throw const RouterProtocolException('That MAC address is not valid.');
    }

    final wlan = await _loadWlan(force: true);
    if (wlan == null) {
      throw const RouterProtocolException(
        'The router did not report a wireless interface.',
      );
    }

    var rule = wlan.filterRule;
    var filterEnabled = wlan.filterEnabled;

    if (!filterEnabled && !blocked) return true;

    if (!filterEnabled) {
      // Keep the existing allow/deny rule. Flipping it would invert every
      // entry in the list and block the wrong devices.
      await _client.execute(
        CgiRequest()..write('LAN_WLAN', const {
          'MACAddressControlEnabled': '1',
        }, stack: wlan.stack),
      );
      filterEnabled = true;
    }

    var entry = await _findFilterEntry(wlan, target);
    final expectedEnabled = rule == 'allow' ? !blocked : blocked;

    if (entry == null) {
      final alreadyMatches = (rule == 'allow') == blocked;
      if (!alreadyMatches) {
        await _client.execute(
          CgiRequest()..add('LAN_WLAN_MACTABLEENTRY', {
            'MACAddress': target,
            'HostName': wlan.name,
            'Description': _asciiLabel(name),
            'Enabled': expectedEnabled ? '1' : '0',
          }, parentStack: wlan.stack),
        );
        entry = await _findFilterEntry(wlan, target);
      }
    } else if (entry.enabled != expectedEnabled) {
      await _client.execute(
        CgiRequest()..write('LAN_WLAN_MACTABLEENTRY', {
          'Enabled': expectedEnabled ? '1' : '0',
        }, stack: entry.stack),
      );
    }

    final verifiedWlan = await _loadWlan(force: true);
    if (verifiedWlan == null) return false;
    final verifiedEntry = await _findFilterEntry(verifiedWlan, target);
    return _isBlocked(verifiedEntry, verifiedWlan) == blocked;
  }

  @override
  Future<List<NetworkEvent>> seedEvents() async => const [];

  @override
  void dispose() => _client.dispose();

  Future<_WlanInfo?> _loadWlan({bool force = false}) async {
    final cached = _cachedWlan;
    final cachedAt = _cachedWlanAt;
    if (!force &&
        cached != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < const Duration(seconds: 20)) {
      return cached;
    }

    final response = await _client.execute(
      CgiRequest()..list('LAN_WLAN', _wlanFields),
    );
    return _applyWlan(response.objects(0));
  }

  CgiObject? _pickWlan(List<CgiObject> objects) {
    if (objects.isEmpty) return null;
    for (final object in objects) {
      if (object['name']?.toLowerCase() == 'wlan0') return object;
    }
    return objects.first;
  }

  _WlanInfo? _applyWlan(List<CgiObject> objects) {
    final chosen = _pickWlan(objects);
    if (chosen == null) return null;

    final info = _WlanInfo(
      name: _clean(chosen['name']) ?? 'wlan0',
      stack: chosen.stack,
      ssid: _clean(chosen['ssid']) ?? '',
      band: _bandLabel(chosen['x_tp_band']),
      channel: chosen.number('channel'),
      security: _securityLabel(chosen),
      filterEnabled: chosen.flag('macaddresscontrolenabled'),
      filterRule:
          _clean(chosen['x_tp_macaddresscontrolrule'])?.toLowerCase() ??
          'allow',
    );

    _cachedWlan = info;
    _cachedWlanAt = DateTime.now();
    return info;
  }

  Future<_FilterEntry?> _findFilterEntry(_WlanInfo wlan, String mac) async {
    final response = await _client.execute(
      CgiRequest()..selection(
        'LAN_WLAN_MACTABLEENTRY',
        _filterFields,
        parentStack: wlan.stack,
      ),
    );
    for (final object in response.objects(0)) {
      final candidate = normalizeMac(_clean(object['macaddress']) ?? '');
      if (candidate != mac) continue;
      return _FilterEntry(
        mac: candidate,
        stack: object.stack,
        enabled: object.flag('enabled'),
        description: _clean(object['description']) ?? '',
      );
    }
    return null;
  }

  Device _deviceFor({
    required String mac,
    required String nameHint,
    required bool online,
    required bool blocked,
  }) {
    final vendor = vendorForMac(mac);
    final name = nameHint.trim().isEmpty ? 'Unknown device' : nameHint.trim();
    return Device(
      mac: mac,
      name: name,
      vendor: vendor,
      type: inferDeviceType(name, vendor),
      ip: '—',
      online: online,
      favorite: false,
      trusted: false,
      blocked: blocked,
      group: DeviceGroup.unknown,
      notes: '',
      firstSeen: DateTime.now(),
      lastSeen: DateTime.now(),
    );
  }
}

class _WlanInfo {
  const _WlanInfo({
    required this.name,
    required this.stack,
    required this.ssid,
    required this.band,
    required this.channel,
    required this.security,
    required this.filterEnabled,
    required this.filterRule,
  });

  final String name;
  final String stack;
  final String ssid;
  final String band;
  final int channel;
  final String security;
  final bool filterEnabled;
  final String filterRule;
}

class _FilterEntry {
  const _FilterEntry({
    required this.mac,
    required this.stack,
    required this.enabled,
    required this.description,
  });

  final String mac;
  final String stack;
  final bool enabled;
  final String description;
}

bool _isBlocked(_FilterEntry? entry, _WlanInfo wlan) {
  if (!wlan.filterEnabled) return false;
  if (wlan.filterRule == 'allow') {
    return entry == null || !entry.enabled;
  }
  return entry?.enabled ?? false;
}

({String address, bool connected}) _parseWan(
  List<CgiObject> ipConnections,
  List<CgiObject> pppConnections,
) {
  for (final connection in pppConnections) {
    if (!connection.flag('enable') || !_isConnected(connection)) {
      continue;
    }
    final address = _clean(connection['externalipaddress']) ?? '';
    if (_usableWanAddress(address)) {
      return (address: address, connected: true);
    }
  }
  for (final connection in ipConnections) {
    if (!connection.flag('enable') || !_isConnected(connection)) {
      continue;
    }
    final address = _clean(connection['externalipaddress']) ?? '';
    if (!_usableWanAddress(address)) continue;
    final gateway = _clean(connection['defaultgateway']) ?? '';
    if (gateway.isEmpty || gateway == '0.0.0.0') continue;
    return (address: address, connected: true);
  }
  return (address: '—', connected: false);
}

bool _isConnected(CgiObject connection) {
  final status = (connection['connectionstatus'] ?? '').trim().toLowerCase();
  return status == 'connected' || status == 'up' || status == '1';
}

bool _usableWanAddress(String address) {
  if (!_validIpv4.hasMatch(address)) return false;
  if (address == '0.0.0.0') return false;
  return !address.startsWith('169.254.');
}

String _bandLabel(String? raw) {
  final value = (raw ?? '').toLowerCase();
  if (value.contains('5')) return '5 GHz';
  if (value.contains('2')) return '2.4 GHz';
  return '2.4 GHz';
}

String _securityLabel(CgiObject object) {
  final beacon = (object['beacontype'] ?? '').toLowerCase();
  final auth = (object['wpaauthenticationmode'] ?? '').toLowerCase();
  final enterprise = auth.contains('enterprise');
  if (beacon.contains('11i')) {
    return enterprise ? 'WPA2-Enterprise' : 'WPA2-PSK';
  }
  if (beacon.contains('wpa')) {
    return enterprise ? 'WPA-Enterprise' : 'WPA-PSK';
  }
  if (beacon.contains('basic')) return 'WEP / Open';
  if (beacon.contains('none')) return 'Open';
  return 'Unknown';
}

String _modelName(CgiObject? device) {
  final hardware = _clean(device?['hardwareversion']);
  if (hardware != null) {
    final match = RegExp(r'^([A-Za-z0-9-]+)').firstMatch(hardware);
    if (match != null) return match.group(1)!;
  }
  return _clean(device?['modelname']) ?? 'TL-WR840N';
}

String? _clean(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String _asciiLabel(String? name) {
  final buffer = StringBuffer();
  for (final rune in (name ?? '').runes) {
    if (rune >= 32 && rune < 127) buffer.writeCharCode(rune);
  }
  final label = buffer.toString().trim();
  final fallback = label.isEmpty ? 'Blocked from NEXUS' : label;
  return fallback.length <= 31 ? fallback : fallback.substring(0, 31);
}

final RegExp _validMac = RegExp(r'^([0-9A-F]{2}:){5}[0-9A-F]{2}$');
final RegExp _validIpv4 = RegExp(r'^\d{1,3}(\.\d{1,3}){3}$');
