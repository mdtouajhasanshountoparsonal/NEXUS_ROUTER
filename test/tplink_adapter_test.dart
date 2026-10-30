import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_router/data/tplink/tplink_adapter.dart';

void main() {
  test('parses a live status batch from the TL-WR840N firmware', () async {
    final fake = _FakeAdapter({
      '1&1&1&5&5&5': [_statusResponse],
      '1': [_wlanDetailResponse, _guestResponse],
    });
    final adapter = _adapter(fake);
    addTearDown(adapter.dispose);

    final status = await adapter.fetchStatus();

    expect(status.model, 'TL-WR840N');
    expect(status.firmware, contains('0.9.1'));
    expect(status.mode, 'Router');
    expect(status.ports, 4);
    expect(status.uptime, const Duration(seconds: 202266));
    expect(status.ssid, 'TOUAJ 🦜');
    expect(status.band, '2.4 GHz');
    expect(status.channel, '1');
    expect(status.security, 'WPA2-PSK');
    expect(status.guestNetworkEnabled, isFalse);
    expect(status.wanIp, '10.0.7.156');
    expect(status.wanConnected, isTrue);
    expect(status.trafficSupported, isFalse);
    expect(fake.queries, ['1&1&1&5&5&5', '1', '1']);
  });

  test(
    'blocking in allow mode enables the filter without adding an entry',
    () async {
      const mac = '80:25:11:68:F9:7A';
      final state = _RouterState(filterEnabled: false, rule: 'allow')
        ..entries['E8:14:99:00:C1:DA'] = true;
      final fake = _BlockFakeAdapter(state);
      final adapter = _adapter(fake);
      addTearDown(adapter.dispose);

      final ok = await adapter.setBlocked(mac, true, name: 'Saddam');

      expect(ok, isTrue);
      expect(state.filterEnabled, isTrue);
      expect(state.rule, 'allow');
      expect(state.entries.containsKey(mac), isFalse);
      expect(fake.adds, 0);
      expect(fake.enableWrites, 1);
    },
  );

  test('blocking in deny mode adds an enabled entry', () async {
    const mac = '80:25:11:68:F9:7A';
    final state = _RouterState(filterEnabled: true, rule: 'deny')
      ..entries['E8:14:99:00:C1:DA'] = true;
    final fake = _BlockFakeAdapter(state);
    final adapter = _adapter(fake);
    addTearDown(adapter.dispose);

    final ok = await adapter.setBlocked(mac, true, name: 'Saddam');

    expect(ok, isTrue);
    expect(state.entries[mac], isTrue);
    expect(fake.adds, 1);
  });

  test('unblocking in allow mode re-enables the existing entry', () async {
    const mac = '80:25:11:68:F9:7A';
    final state = _RouterState(filterEnabled: true, rule: 'allow')
      ..entries[mac] = false;
    final fake = _BlockFakeAdapter(state);
    final adapter = _adapter(fake);
    addTearDown(adapter.dispose);

    final ok = await adapter.setBlocked(mac, false, name: 'Saddam');

    expect(ok, isTrue);
    expect(state.entries[mac], isTrue);
    expect(fake.entryWrites, 1);
  });

  test('blocking in allow mode disables the existing entry', () async {
    const mac = '80:25:11:68:F9:7A';
    final state = _RouterState(filterEnabled: true, rule: 'allow')
      ..entries[mac] = true;
    final fake = _BlockFakeAdapter(state);
    final adapter = _adapter(fake);
    addTearDown(adapter.dispose);

    final ok = await adapter.setBlocked(mac, true, name: 'Saddam');

    expect(ok, isTrue);
    expect(state.entries[mac], isFalse);
    expect(fake.entryWrites, 1);
  });

  test('unblocking in deny mode disables the existing entry', () async {
    const mac = '80:25:11:68:F9:7A';
    final state = _RouterState(filterEnabled: true, rule: 'deny')
      ..entries[mac] = true;
    final fake = _BlockFakeAdapter(state);
    final adapter = _adapter(fake);
    addTearDown(adapter.dispose);

    final ok = await adapter.setBlocked(mac, false, name: 'Saddam');

    expect(ok, isTrue);
    expect(state.entries[mac], isFalse);
    expect(fake.entryWrites, 1);
  });

  test('merges the MAC filter list with associated clients', () async {
    final fake = _FakeAdapter({
      '5': [_wlanResponse],
      '7': ['[error]0\r\n'],
      '6&6': [_filterAndAssocResponse],
    });
    final adapter = _adapter(fake);
    addTearDown(adapter.dispose);

    final devices = await adapter.fetchDevices();

    expect(fake.queries, ['5', '7', '6&6']);
    expect(devices, hasLength(2));

    final online = devices.firstWhere((device) => device.online);
    expect(online.name, 'PC 2');
    expect(online.mac, 'E8:14:99:00:C1:DA');
    expect(online.blocked, isFalse);
    expect(online.ip, '—');

    final offline = devices.firstWhere((device) => !device.online);
    expect(offline.name, 'Saddam vi');
    expect(offline.mac, '80:25:11:68:F9:7A');
    expect(offline.blocked, isTrue);
  });
}

TplinkV6Adapter _adapter(HttpClientAdapter fake) {
  final dio = Dio(
    BaseOptions(
      responseType: ResponseType.plain,
      validateStatus: (status) => status != null,
    ),
  );
  dio.httpClientAdapter = fake;
  return TplinkV6Adapter(
    host: '192.168.0.1',
    username: 'admin',
    password: 'test-only',
    dio: dio,
  );
}

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.responses);

  final Map<String, List<String>> responses;
  final List<String> queries = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final query = options.uri.query;
    queries.add(query);
    final queue = responses[query];
    if (queue == null || queue.isEmpty) {
      return ResponseBody.fromString('[error]0\r\n', 200, headers: _headers);
    }
    final body = queue.length == 1 ? queue.first : queue.removeAt(0);
    return ResponseBody.fromString(body, 200, headers: _headers);
  }

  static const _headers = {
    Headers.contentTypeHeader: ['text/plain; charset=utf-8'],
  };

  @override
  void close({bool force = false}) {}
}

const _statusResponse =
    '[0,0,0,0,0,0]0\r\n'
    'mode=Router\r\n'
    '[0,0,0,0,0,0]1\r\n'
    'modelName=TL-WR840N\r\n'
    'softwareVersion=0.9.1 4.16 v0001.0 Build 180614 Rel.40494n\r\n'
    'hardwareVersion=TL-WR840N v6 00000007\r\n'
    'upTime=202266\r\n'
    '[0,0,0,0,0,0]2\r\n'
    'numberOfVirtualPorts=4\r\n'
    '[1,1,1,0,0,0]3\r\n'
    'enable=1\r\n'
    'connectionStatus=Connected\r\n'
    'externalIPAddress=169.254.61.92\r\n'
    'defaultGateway=0.0.0.0\r\n'
    'addressingType=Static\r\n'
    '[1,1,1,0,0,0]4\r\n'
    'enable=1\r\n'
    'connectionStatus=Connected\r\n'
    'externalIPAddress=10.0.7.156\r\n'
    'defaultGateway=10.0.0.1\r\n'
    'addressingType=DHCP\r\n'
    'username=demo-pppoe-user\r\n'
    'password=demo-pppoe-pass\r\n'
    'X_TP_BpaPassword=bpa-secret\r\n'
    '[1,1,0,0,0,0]5\r\n'
    'name=wlan0\r\n'
    'status=Up\r\n'
    'SSID=TOUAJ 🦜\r\n'
    'X_TP_Band=2.4GHz\r\n'
    'MACAddressControlEnabled=1\r\n'
    'X_TP_MACAddressControlRule=allow\r\n'
    '[1,2,0,0,0,0]5\r\n'
    'name=wlan5\r\n'
    'status=Disabled\r\n'
    'SSID=TP-Link_3C5A_5G\r\n'
    'X_TP_Band=5GHz\r\n'
    'MACAddressControlEnabled=0\r\n'
    'X_TP_MACAddressControlRule=deny\r\n'
    '[error]0\r\n';

const _wlanDetailResponse =
    '[1,1,0,0,0,0]0\r\n'
    'name=wlan0\r\n'
    'channel=1\r\n'
    'beaconType=11i\r\n'
    'WPAEncryptionModes=AES\r\n'
    'IEEE11iEncryptionModes=AES\r\n'
    'WPAAuthenticationMode=PSKAuthentication\r\n'
    'IEEE11iAuthenticationMode=PSKAuthentication\r\n'
    '[error]0\r\n';

const _guestResponse =
    '[1,1,0,0,0,0]0\r\n'
    'multiSSIDEnable=0\r\n'
    '[error]0\r\n';

const _wlanResponse =
    '[1,1,0,0,0,0]0\r\n'
    'name=wlan0\r\n'
    'status=Up\r\n'
    'SSID=TOUAJ 🦜\r\n'
    'channel=1\r\n'
    'X_TP_Band=2.4GHz\r\n'
    'beaconType=11i\r\n'
    'WPAAuthenticationMode=PSKAuthentication\r\n'
    'MACAddressControlEnabled=1\r\n'
    'X_TP_MACAddressControlRule=allow\r\n'
    '[error]0\r\n';

const _filterAndAssocResponse =
    '[1,1,1,0,0,0]0\r\n'
    'enabled=1\r\n'
    'MACAddress=E8:14:99:00:C1:DA\r\n'
    'description=PC 2\r\n'
    'hostName=wlan0\r\n'
    '[1,1,2,0,0,0]0\r\n'
    'enabled=0\r\n'
    'MACAddress=80:25:11:68:F9:7A\r\n'
    'description=Saddam vi\r\n'
    'hostName=wlan0\r\n'
    '[1,1,1,0,0,0]1\r\n'
    'associatedDeviceMACAddress=E8:14:99:00:C1:DA\r\n'
    'X_TP_TotalPacketsSent=2098\r\n'
    'X_TP_TotalPacketsReceived=1073\r\n'
    'X_TP_HostName=wlan0\r\n'
    '[error]0\r\n';

class _RouterState {
  _RouterState({required this.filterEnabled, required this.rule});

  bool filterEnabled;
  String rule;
  final Map<String, bool> entries = {};
  final Map<String, String> stacks = {};

  String stackFor(String mac) {
    return stacks.putIfAbsent(mac, () => '1,1,${stacks.length + 1},0,0,0');
  }
}

class _BlockFakeAdapter implements HttpClientAdapter {
  _BlockFakeAdapter(this.state);

  final _RouterState state;
  int adds = 0;
  int enableWrites = 0;
  int entryWrites = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final query = options.uri.query;
    final body = options.data is String ? options.data as String : '';

    switch (query) {
      case '5':
        return _text(_wlanStateResponse(state));
      case '6':
        return _text(_filterStateResponse(state));
      case '2':
        _applyWrite(body);
        return _text('[error]0\r\n');
      case '3':
        _applyAdd(body);
        return _text('[error]0\r\n');
      case '7':
        return _text('[error]0\r\n');
      default:
        return _text('[error]0\r\n');
    }
  }

  void _applyWrite(String body) {
    final lines = body.split('\r\n');
    final header = lines.first;
    if (header.startsWith('[LAN_WLAN#')) {
      enableWrites++;
      state.filterEnabled = true;
      return;
    }
    if (header.startsWith('[LAN_WLAN_MACTABLEENTRY#')) {
      entryWrites++;
      final stack = header.split('#')[1];
      final enabled = lines.any((line) => line == 'Enabled=1');
      for (final entry in state.stacks.entries) {
        if (entry.value == stack) {
          state.entries[entry.key] = enabled;
          return;
        }
      }
    }
  }

  void _applyAdd(String body) {
    adds++;
    final lines = body.split('\r\n');
    String? mac;
    var enabled = true;
    for (final line in lines.skip(1)) {
      if (line.startsWith('MACAddress=')) {
        mac = line.substring('MACAddress='.length);
      } else if (line.startsWith('Enabled=')) {
        enabled = line.endsWith('=1');
      }
    }
    if (mac == null) return;
    state.entries[mac] = enabled;
    state.stackFor(mac);
  }

  static ResponseBody _text(String body) {
    return ResponseBody.fromString(
      body,
      200,
      headers: const {
        Headers.contentTypeHeader: ['text/plain; charset=utf-8'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

String _wlanStateResponse(_RouterState state) {
  return '[1,1,0,0,0,0]0\r\n'
      'name=wlan0\r\n'
      'status=Up\r\n'
      'SSID=TOUAJ 🦜\r\n'
      'channel=1\r\n'
      'X_TP_Band=2.4GHz\r\n'
      'beaconType=11i\r\n'
      'WPAAuthenticationMode=PSKAuthentication\r\n'
      'MACAddressControlEnabled=${state.filterEnabled ? 1 : 0}\r\n'
      'X_TP_MACAddressControlRule=${state.rule}\r\n'
      '[error]0\r\n';
}

String _filterStateResponse(_RouterState state) {
  final buffer = StringBuffer();
  for (final entry in state.entries.entries) {
    buffer.write(
      '[${state.stackFor(entry.key)}]0\r\n'
      'enabled=${entry.value ? 1 : 0}\r\n'
      'MACAddress=${entry.key}\r\n'
      'description=Device ${entry.key.substring(12)}\r\n'
      'hostName=wlan0\r\n',
    );
  }
  buffer.write('[error]0\r\n');
  return buffer.toString();
}
