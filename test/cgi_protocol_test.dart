import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_router/data/tplink/cgi_protocol.dart';
import 'package:nexus_router/data/tplink/router_credentials.dart';

void main() {
  group('CgiRequest', () {
    test('serialises reads and list calls in order', () {
      final request = CgiRequest()
        ..read('MULTIMODE', const ['mode'])
        ..list('LAN_WLAN_MACTABLEENTRY', const [
          'MACAddress',
          'Enabled',
        ], parentStack: '1,1,0,0,0,0');

      expect(request.query, '1&5');
      expect(
        request.body,
        '[MULTIMODE#0,0,0,0,0,0#0,0,0,0,0,0]0,1\r\n'
        'mode\r\n'
        '[LAN_WLAN_MACTABLEENTRY#0,0,0,0,0,0#1,1,0,0,0,0]1,2\r\n'
        'MACAddress\r\n'
        'Enabled\r\n',
      );
    });

    test('serialises writes and operation calls', () {
      final request = CgiRequest()
        ..write('LAN_WLAN', const {'MACAddressControlEnabled': '1'})
        ..operation('ACT_WLAN_UPDATE_ASSOC', stack: '1,1,0,0,0,0');

      expect(request.query, '2&7');
      expect(
        request.body,
        '[LAN_WLAN#0,0,0,0,0,0#0,0,0,0,0,0]0,1\r\n'
        'MACAddressControlEnabled=1\r\n'
        '[ACT_WLAN_UPDATE_ASSOC#1,1,0,0,0,0#0,0,0,0,0,0]1,0\r\n',
      );
    });
    test('status batch keeps action indices stable', () {
      final request = CgiRequest()
        ..read('MULTIMODE', const ['mode'])
        ..read('IGD_DEV_INFO', const ['softwareVersion'])
        ..read('ETH_SWITCH', const ['numberOfVirtualPorts'])
        ..list('WAN_IP_CONN', const ['externalIPAddress'])
        ..list('WAN_PPP_CONN', const ['externalIPAddress'])
        ..list('LAN_WLAN', const ['SSID']);

      expect(request.query, '1&1&1&5&5&5');
      expect(request.body, contains(']0,1\r\nmode\r\n'));
      expect(request.body, contains(']1,1\r\nsoftwareVersion\r\n'));
      expect(request.body, contains(']2,1\r\nnumberOfVirtualPorts\r\n'));
      expect(request.body, contains(']3,1\r\nexternalIPAddress\r\n'));
      expect(request.body, contains(']4,1\r\nexternalIPAddress\r\n'));
      expect(request.body, contains(']5,1\r\nSSID\r\n'));
    });
  });

  group('CgiResponse', () {
    test('never retains credentials from unfiltered responses', () {
      final response = CgiResponse.parse(
        '[1,1,1,0,0,0]3\r\n'
        'username=demo-pppoe-user\r\n'
        'password=demo-pppoe-pass\r\n'
        'X_TP_BpaPassword=bpa-secret\r\n'
        'X_TP_PreSharedKey=wifi-secret\r\n'
        'externalIPAddress=10.0.7.156\r\n'
        '[error]0\r\n',
      );

      final wan = response.first(3)!;
      expect(wan['externalipaddress'], '10.0.7.156');
      expect(wan.attributes.containsKey('username'), isFalse);
      expect(wan.attributes.containsKey('password'), isFalse);
      expect(wan.attributes.containsKey('x_tp_bpapassword'), isFalse);
      expect(wan.attributes.containsKey('x_tp_presharedkey'), isFalse);
    });

    test('parses objects, normalises keys and reads the error code', () {
      final response = CgiResponse.parse(
        '[0,0,0,0,0,0]0\r\n'
        'modelName=TL-WR840N\r\n'
        'softwareVersion=0.9.1 4.16 v0001.0\r\n'
        '[1,1,0,0,0,0]3\r\n'
        'SSID=Home Net\r\n'
        'Enabled=1\r\n'
        'channel=6\r\n'
        '[1,2,0,0,0,0]4\r\n'
        'SSID=Guest\r\n'
        '[error]0\r\n',
      );

      expect(response.errorCode, 0);
      expect(response.first(0)?['modelname'], 'TL-WR840N');
      expect(response.first(0)?['MODELNAME'], 'TL-WR840N');
      expect(response.objects(3), hasLength(1));

      final radio = response.first(3)!;
      expect(radio.stack, '1,1,0,0,0,0');
      expect(radio['ssid'], 'Home Net');
      expect(radio.flag('enabled'), isTrue);
      expect(radio.number('channel'), 6);
    });

    test('keeps multiple objects in one block', () {
      final response = CgiResponse.parse(
        '[1,1,1,0,0,0]0\r\n'
        'name=wlan0\r\n'
        '[1,1,2,0,0,0]0\r\n'
        'name=wlan1\r\n'
        '[error]0\r\n',
      );

      expect(response.objects(0), hasLength(2));
      expect(response.objects(0)[1]['name'], 'wlan1');
    });

    test('reports non-zero router errors', () {
      final response = CgiResponse.parse('[error]-1\r\n');
      expect(response.errorCode, -1);
      expect(response.objects(0), isEmpty);
    });

    test('reads cgi blocks', () {
      final response = CgiResponse.parse(
        '[0,0,0,0,0,0]0\r\n'
        'mode=Router\r\n'
        '[cgi]1\r\n'
        'var userType="Admin";\r\n'
        '[error]0\r\n',
      );

      expect(response.first(0)?['mode'], 'Router');
      expect(response.cgiScripts, ['1']);
    });
  });

  group('normalizeRouterHost', () {
    test('accepts local IPv4 addresses and strips the scheme', () {
      expect(normalizeRouterHost('192.168.0.1'), '192.168.0.1');
      expect(normalizeRouterHost('http://192.168.0.1/'), '192.168.0.1');
      expect(normalizeRouterHost('10.0.0.1:8080'), '10.0.0.1:8080');
      expect(normalizeRouterHost('tplinkwifi.net'), 'tplinkwifi.net');
    });

    test('rejects public hosts and HTTPS', () {
      expect(
        () => normalizeRouterHost('https://192.168.0.1'),
        throwsFormatException,
      );
      expect(() => normalizeRouterHost('8.8.8.8'), throwsFormatException);
      expect(() => normalizeRouterHost('example.com'), throwsFormatException);
      expect(() => normalizeRouterHost(''), throwsFormatException);
    });
  });
}
