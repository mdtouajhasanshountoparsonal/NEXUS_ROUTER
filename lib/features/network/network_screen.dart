import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/providers.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/info_row.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/sparkline.dart';
import '../../shared/widgets/status_pill.dart';

class NetworkScreen extends ConsumerStatefulWidget {
  const NetworkScreen({super.key});

  @override
  ConsumerState<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends ConsumerState<NetworkScreen> {
  int _rangeIndex = 0;
  static const _ranges = ['Live', '24H', '7D'];

  List<double> get _series {
    return switch (_rangeIndex) {
      0 => [18, 22, 19, 26, 23, 30, 27, 33, 29, 36, 32, 40],
      1 => [
        14,
        19,
        17,
        23,
        21,
        28,
        25,
        31,
        27,
        34,
        30,
        38,
        34,
        41,
        37,
        44,
        40,
        46,
        42,
        49,
        45,
        51,
        47,
        53,
      ],
      _ => [24, 30, 27, 36, 31, 40, 35, 44, 39, 47, 43, 52],
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = ref.watch(routerStatusProvider).value;
    final adapter = ref.watch(routerAdapterProvider);
    final isDemo = adapter.isDemo;
    final capabilities = status?.capabilities ?? adapter.capabilities;

    return SafeArea(
      bottom: false,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 130),
        children: [
          PageHeader(
            title: 'Network',
            subtitle: 'WAN, Wi-Fi and router capabilities',
            trailing: IconButton(
              onPressed: () =>
                  ref.read(routerStatusProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
          const SizedBox(height: 18),
          GlassCard(
            glow: AppColors.secondary,
            padding: const EdgeInsets.all(18),
            child: isDemo
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'WAN throughput',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Router-reported totals · demo trend',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          _RangeSelector(
                            values: _ranges,
                            index: _rangeIndex,
                            onChanged: (index) {
                              setState(() => _rangeIndex = index);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      NetworkSparkline(
                        values: _series,
                        color: AppColors.secondary,
                        height: 110,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _TrafficStat(
                              icon: Icons.arrow_downward_rounded,
                              label: 'Download',
                              value: status == null
                                  ? '—'
                                  : formatMbps(status.downloadMbps),
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _TrafficStat(
                              icon: Icons.arrow_upward_rounded,
                              label: 'Upload',
                              value: status == null
                                  ? '—'
                                  : formatMbps(status.uploadMbps),
                              color: AppColors.info,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'Today',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '↓ 4.2 GB   ↑ 640 MB',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10.5,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WAN throughput',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Not reported by this firmware',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'The TL-WR840N admin API does not expose WAN byte '
                              'counters, so speed and usage graphs stay empty in '
                              'live mode. Wi-Fi and client data below is live.',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          SectionHeader(
            title: 'Router',
            trailing: isDemo
                ? const DemoBadge(compact: true)
                : const StatusPill(
                    'LIVE',
                    color: AppColors.success,
                    dense: true,
                  ),
          ),
          GlassCard(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
            child: Column(
              children: [
                InfoRow(label: 'Model', value: status?.model ?? 'TL-WR840N'),
                InfoRow(label: 'Firmware', value: status?.firmware ?? '—'),
                InfoRow(label: 'Mode', value: status?.mode ?? 'Router'),
                InfoRow(label: 'LAN ports', value: '${status?.ports ?? 4}'),
                InfoRow(
                  label: 'WAN',
                  value: status == null
                      ? '—'
                      : status.wanConnected
                      ? 'Connected · ${status.wanIp}'
                      : 'Disconnected',
                ),
                InfoRow(
                  label: 'Uptime',
                  value: status == null ? '—' : formatUptime(status.uptime),
                ),
                InfoRow(
                  label: 'Admin host',
                  value: status?.host ?? '192.168.0.1',
                  mono: true,
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionHeader(
            title: 'Wi-Fi',
            trailing: isDemo
                ? const DemoBadge(compact: true)
                : const StatusPill(
                    'LIVE',
                    color: AppColors.success,
                    dense: true,
                  ),
          ),
          GlassCard(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
            child: Column(
              children: [
                InfoRow(label: 'SSID', value: _valueOrDash(status?.ssid)),
                InfoRow(label: 'Band', value: _valueOrDash(status?.band)),
                InfoRow(label: 'Channel', value: _valueOrDash(status?.channel)),
                InfoRow(
                  label: 'Security',
                  value: _valueOrDash(status?.security),
                ),
                InfoRow(
                  label: 'Guest network',
                  value: status?.guestNetworkEnabled == true
                      ? 'Enabled · separate SSID'
                      : 'Disabled',
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'Router capabilities'),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _CapabilityRow(
                  icon: Icons.family_restroom_rounded,
                  title: 'Access control',
                  subtitle: 'Parental controls, host & schedule rules',
                  supported: capabilities.accessControl,
                ),
                _CapabilityRow(
                  icon: Icons.block_rounded,
                  title: 'Wireless MAC filtering',
                  subtitle: 'Block or allow devices by MAC address',
                  supported: capabilities.macFilter,
                ),
                _CapabilityRow(
                  icon: Icons.wifi_tethering_rounded,
                  title: 'Guest network',
                  subtitle: 'Separate SSID for visitors',
                  supported: capabilities.guestNetwork,
                ),
                _CapabilityRow(
                  icon: Icons.speed_rounded,
                  title: 'Bandwidth control',
                  subtitle: 'Per-IP ingress and egress limits',
                  supported: capabilities.bandwidthControl,
                ),
                _CapabilityRow(
                  icon: Icons.schedule_rounded,
                  title: 'Wi-Fi schedule',
                  subtitle: 'Turn radios off on a timetable',
                  supported: capabilities.wifiSchedule,
                ),
                _CapabilityRow(
                  icon: Icons.link_rounded,
                  title: 'IP & MAC binding',
                  subtitle: 'Reserve addresses for known devices',
                  supported: capabilities.ipMacBinding,
                ),
                _CapabilityRow(
                  icon: Icons.analytics_outlined,
                  title: 'Per-device usage',
                  subtitle: 'Not exposed by this firmware',
                  supported: capabilities.perDeviceUsage,
                  last: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isDemo
                ? 'Capabilities are inferred from the TL-WR840N v6.20 firmware '
                      'pages and object model. Demo values are synthetic.'
                : 'Capabilities reflect what this firmware exposes to the app. '
                      'MAC filtering is live; WAN counters, DHCP leases and '
                      'parental-control rules are not available.',
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}

String _valueOrDash(String? value) {
  return value == null || value.isEmpty ? '—' : value;
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({
    required this.values,
    required this.index,
    required this.onChanged,
  });

  final List<String> values;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < values.length; i++)
            GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: i == index
                      ? AppColors.secondary.withValues(alpha: 0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  values[i],
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: i == index
                        ? AppColors.secondary
                        : theme.textTheme.bodySmall?.color,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TrafficStat extends StatelessWidget {
  const _TrafficStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.5),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 21,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: Text(
                  'Mbps',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CapabilityRow extends StatelessWidget {
  const _CapabilityRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.supported,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool supported;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = supported ? AppColors.success : AppColors.warning;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            children: [
              Icon(icon, size: 17, color: theme.textTheme.bodySmall?.color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                supported
                    ? Icons.check_circle_rounded
                    : Icons.remove_circle_outline_rounded,
                size: 17,
                color: color,
              ),
            ],
          ),
        ),
        if (!last) const Divider(),
      ],
    );
  }
}
