import '../core/models/device.dart';
import '../core/models/network_event.dart';
import '../core/models/router_status.dart';

abstract class RouterAdapter {
  String get label;

  bool get isDemo;

  RouterCapabilities get capabilities;

  Future<RouterStatus> fetchStatus();

  Future<List<Device>> fetchDevices();

  Future<List<NetworkEvent>> seedEvents();

  Future<bool> setBlocked(String mac, bool blocked, {String? name});

  void dispose() {}
}
