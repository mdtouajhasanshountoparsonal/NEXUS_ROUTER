import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../app/theme/theme_controller.dart';
import '../core/db/app_database.dart';
import '../core/models/device.dart';
import '../core/models/network_event.dart';
import '../core/models/router_status.dart';
import 'demo_router_adapter.dart';
import 'device_repository.dart';
import 'router_adapter.dart';
import 'tplink/router_credentials.dart';
import 'tplink/tplink_adapter.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final initialRouterCredentialsProvider = Provider<RouterCredentials?>(
  (ref) => null,
);

final routerCredentialsStoreProvider = Provider<RouterCredentialsStore>(
  (ref) => const RouterCredentialsStore(FlutterSecureStorage()),
);

class RouterCredentialsNotifier extends Notifier<RouterCredentials?> {
  @override
  RouterCredentials? build() => ref.watch(initialRouterCredentialsProvider);

  Future<void> connect(RouterCredentials credentials) async {
    await ref.read(routerCredentialsStoreProvider).write(credentials);
    state = credentials;
  }

  Future<void> disconnect() async {
    await ref.read(routerCredentialsStoreProvider).clear();
    state = null;
  }
}

final routerCredentialsProvider =
    NotifierProvider<RouterCredentialsNotifier, RouterCredentials?>(
      RouterCredentialsNotifier.new,
    );

final routerAdapterProvider = Provider<RouterAdapter>((ref) {
  final credentials = ref.watch(routerCredentialsProvider);
  final RouterAdapter adapter;
  if (credentials != null && credentials.isConfigured) {
    adapter = TplinkV6Adapter(
      host: credentials.host,
      username: credentials.username,
      password: credentials.password,
    );
  } else {
    adapter = DemoRouterAdapter();
  }
  ref.onDispose(adapter.dispose);
  return adapter;
});

final isLiveRouterProvider = Provider<bool>((ref) {
  return !ref.watch(routerAdapterProvider).isDemo;
});

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(routerAdapterProvider),
  );
});

final devicesProvider = AsyncNotifierProvider<DevicesNotifier, List<Device>>(
  DevicesNotifier.new,
);

class DevicesNotifier extends AsyncNotifier<List<Device>> {
  @override
  Future<List<Device>> build() {
    return ref.watch(deviceRepositoryProvider).fetchAndSync();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(deviceRepositoryProvider).fetchAndSync(),
    );
  }

  Future<void> save(Device device) async {
    await ref.read(deviceRepositoryProvider).saveDevice(device);
    final current = state.value ?? const <Device>[];
    final updated = [
      for (final item in current)
        if (item.mac == device.mac) device else item,
    ];
    state = AsyncData(_sorted(updated));
  }

  Future<void> setBlocked(Device device, bool blocked) async {
    final updated = await ref
        .read(deviceRepositoryProvider)
        .setBlocked(device, blocked);
    final current = state.value ?? const <Device>[];
    state = AsyncData([
      for (final item in current)
        if (item.mac == updated.mac) updated else item,
    ]);
    ref.invalidate(eventsProvider);
    ref.invalidate(routerStatusProvider);
  }

  List<Device> _sorted(List<Device> devices) {
    final copy = [...devices]
      ..sort((a, b) {
        if (a.online != b.online) return a.online ? -1 : 1;
        if (a.favorite != b.favorite) return a.favorite ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return copy;
  }
}

final routerStatusProvider =
    AsyncNotifierProvider<RouterStatusNotifier, RouterStatus>(
      RouterStatusNotifier.new,
    );

class RouterStatusNotifier extends AsyncNotifier<RouterStatus> {
  @override
  Future<RouterStatus> build() {
    return ref.watch(routerAdapterProvider).fetchStatus();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(routerAdapterProvider).fetchStatus(),
    );
  }
}

final eventsProvider =
    AsyncNotifierProvider<EventsNotifier, List<NetworkEvent>>(
      EventsNotifier.new,
    );

class EventsNotifier extends AsyncNotifier<List<NetworkEvent>> {
  @override
  Future<List<NetworkEvent>> build() {
    return ref.watch(deviceRepositoryProvider).fetchEvents();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(deviceRepositoryProvider).fetchEvents(),
    );
  }

  Future<void> clear() async {
    await ref.read(deviceRepositoryProvider).clearEvents();
    state = const AsyncData<List<NetworkEvent>>(<NetworkEvent>[]);
  }
}

final blockedDevicesProvider = Provider<List<Device>>((ref) {
  final devices = ref.watch(devicesProvider).value ?? const <Device>[];
  return devices.where((device) => device.blocked).toList();
});

final unknownDevicesProvider = Provider<List<Device>>((ref) {
  final devices = ref.watch(devicesProvider).value ?? const <Device>[];
  return devices.where((device) => device.isUnknown).toList();
});

class AlertRules {
  final bool newDevice;
  final bool unknownDevice;
  final bool routerOffline;
  final bool repeatedDisconnects;

  const AlertRules({
    required this.newDevice,
    required this.unknownDevice,
    required this.routerOffline,
    required this.repeatedDisconnects,
  });

  AlertRules copyWith({
    bool? newDevice,
    bool? unknownDevice,
    bool? routerOffline,
    bool? repeatedDisconnects,
  }) {
    return AlertRules(
      newDevice: newDevice ?? this.newDevice,
      unknownDevice: unknownDevice ?? this.unknownDevice,
      routerOffline: routerOffline ?? this.routerOffline,
      repeatedDisconnects: repeatedDisconnects ?? this.repeatedDisconnects,
    );
  }
}

class AlertRulesNotifier extends Notifier<AlertRules> {
  static const _newDeviceKey = 'alert_new_device';
  static const _unknownKey = 'alert_unknown_device';
  static const _offlineKey = 'alert_router_offline';
  static const _disconnectKey = 'alert_repeated_disconnects';

  @override
  AlertRules build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AlertRules(
      newDevice: prefs.getBool(_newDeviceKey) ?? true,
      unknownDevice: prefs.getBool(_unknownKey) ?? true,
      routerOffline: prefs.getBool(_offlineKey) ?? true,
      repeatedDisconnects: prefs.getBool(_disconnectKey) ?? false,
    );
  }

  Future<void> setNewDevice(bool value) async {
    state = state.copyWith(newDevice: value);
    await ref.read(sharedPreferencesProvider).setBool(_newDeviceKey, value);
  }

  Future<void> setUnknownDevice(bool value) async {
    state = state.copyWith(unknownDevice: value);
    await ref.read(sharedPreferencesProvider).setBool(_unknownKey, value);
  }

  Future<void> setRouterOffline(bool value) async {
    state = state.copyWith(routerOffline: value);
    await ref.read(sharedPreferencesProvider).setBool(_offlineKey, value);
  }

  Future<void> setRepeatedDisconnects(bool value) async {
    state = state.copyWith(repeatedDisconnects: value);
    await ref.read(sharedPreferencesProvider).setBool(_disconnectKey, value);
  }
}

final alertRulesProvider = NotifierProvider<AlertRulesNotifier, AlertRules>(
  AlertRulesNotifier.new,
);
