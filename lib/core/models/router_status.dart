class RouterCapabilities {
  final bool accessControl;
  final bool macFilter;
  final bool guestNetwork;
  final bool bandwidthControl;
  final bool wifiSchedule;
  final bool ipMacBinding;
  final bool wirelessStats;
  final bool perDeviceUsage;

  const RouterCapabilities({
    required this.accessControl,
    required this.macFilter,
    required this.guestNetwork,
    required this.bandwidthControl,
    required this.wifiSchedule,
    required this.ipMacBinding,
    required this.wirelessStats,
    required this.perDeviceUsage,
  });
}

class RouterStatus {
  final String model;
  final String firmware;
  final String mode;
  final String host;
  final int ports;
  final Duration uptime;
  final double downloadMbps;
  final double uploadMbps;
  final int connectedDevices;
  final int unknownDevices;
  final DateTime lastUpdated;
  final bool reachable;
  final bool demo;
  final RouterCapabilities capabilities;
  final String ssid;
  final String band;
  final String channel;
  final String security;
  final bool guestNetworkEnabled;
  final String wanIp;
  final bool wanConnected;
  final bool trafficSupported;

  const RouterStatus({
    required this.model,
    required this.firmware,
    required this.mode,
    required this.host,
    required this.ports,
    required this.uptime,
    required this.downloadMbps,
    required this.uploadMbps,
    required this.connectedDevices,
    required this.unknownDevices,
    required this.lastUpdated,
    required this.reachable,
    required this.demo,
    required this.capabilities,
    this.ssid = '',
    this.band = '',
    this.channel = '',
    this.security = '',
    this.guestNetworkEnabled = false,
    this.wanIp = '',
    this.wanConnected = false,
    this.trafficSupported = false,
  });
}
