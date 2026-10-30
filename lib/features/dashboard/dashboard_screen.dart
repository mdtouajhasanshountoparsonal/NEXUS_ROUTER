import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../core/models/device.dart';
import '../../core/models/network_event.dart';
import '../../core/models/router_status.dart';
import '../../core/utils/formatters.dart';
import '../../data/providers.dart';
import '../../shared/widgets/action_button.dart';
import '../../shared/widgets/event_tile.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/sparkline.dart';
import '../../shared/widgets/stat_tile.dart';
import '../../shared/widgets/status_pill.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _rangeIndex = 1;

  static const _ranges = ['1H', '24H', '7D'];

  List<double> get _series {
    return switch (_rangeIndex) {
      0 => [14, 18, 16, 23, 20, 27, 24, 30, 26, 34, 29, 37],
      1 => [
        12,
        18,
        15,
        22,
        19,
        28,
        24,
        31,
        26,
        34,
        29,
        38,
        33,
        41,
        36,
        44,
        39,
        46,
        42,
        48,
        43,
        50,
        45,
        52,
      ],
      _ => [22, 28, 25, 34, 30, 38, 33, 42, 36, 45, 41, 49],
    };
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(routerStatusProvider.notifier).refresh(),
      ref.read(devicesProvider.notifier).refresh(),
      ref.read(eventsProvider.notifier).refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusAsync = ref.watch(routerStatusProvider);
    final isDemo = ref.watch(routerAdapterProvider).isDemo;
    final devices = ref.watch(devicesProvider).value ?? const <Device>[];
    final events = ref.watch(eventsProvider).value ?? const <NetworkEvent>[];
    final status = statusAsync.value;
    final online = devices.where((device) => device.online).length;
    final unknown = devices.where((device) => device.isUnknown).length;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.accent,
        backgroundColor: theme.colorScheme.surface,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 130),
          children: [
            _BrandHeader(isDemo: isDemo),
            const SizedBox(height: 20),
            Text('Network Command Center', style: theme.textTheme.displaySmall),
            const SizedBox(height: 6),
            Text(
              'Whole network at a glance · ${status?.host ?? '192.168.0.1'}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            statusAsync.when(
              data: (data) => _RouterHero(status: data, onRefresh: _refresh),
              loading: () => const _HeroLoading(),
              error: (error, _) =>
                  _HeroError(message: error.toString(), onRetry: _refresh),
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.42,
              children: [
                StatTile(
                  label: 'Connected devices',
                  value: '$online',
                  unit: '/ ${devices.length}',
                  icon: Icons.devices_other_rounded,
                  accent: AppColors.success,
                  footnote: '$unknown unknown flagged',
                  onTap: () => context.go('/devices'),
                ),
                StatTile(
                  label: 'Unknown devices',
                  value: '$unknown',
                  icon: Icons.help_outline_rounded,
                  accent: AppColors.warning,
                  footnote: 'Review queue',
                  onTap: () => context.go('/devices'),
                ),
                StatTile(
                  label: 'Download',
                  value: status == null || !isDemo
                      ? '—'
                      : formatMbps(status.downloadMbps),
                  unit: 'Mbps',
                  icon: Icons.arrow_downward_rounded,
                  accent: AppColors.secondary,
                  footnote: isDemo
                      ? 'WAN throughput · demo'
                      : 'Not exposed by firmware',
                ),
                StatTile(
                  label: 'Upload',
                  value: status == null || !isDemo
                      ? '—'
                      : formatMbps(status.uploadMbps),
                  unit: 'Mbps',
                  icon: Icons.arrow_upward_rounded,
                  accent: AppColors.info,
                  footnote: isDemo
                      ? 'WAN throughput · demo'
                      : 'Not exposed by firmware',
                ),
              ],
            ),
            const SizedBox(height: 20),
            GlassCard(
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
                                    'Network pulse',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'WAN throughput trend · demo',
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
                        const SizedBox(height: 16),
                        NetworkSparkline(
                          values: _series,
                          color: AppColors.secondary,
                          height: 92,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const _Legend(
                              color: AppColors.secondary,
                              icon: Icons.arrow_downward_rounded,
                              label: 'Download',
                              value: '18.4 Mbps',
                            ),
                            const SizedBox(width: 16),
                            const _Legend(
                              color: AppColors.info,
                              icon: Icons.arrow_upward_rounded,
                              label: 'Upload',
                              value: '3.2 Mbps',
                            ),
                            const Spacer(),
                            Text(
                              'Peak 52.0',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10.5,
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
                          'Network pulse',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'WAN counters unavailable',
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
                                'This firmware does not expose WAN byte counters '
                                'through the local admin API, so live throughput '
                                'cannot be graphed. Device and Wi-Fi data is live.',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Quick actions'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                QuickAction(
                  icon: Icons.devices_rounded,
                  label: 'Devices',
                  accent: AppColors.accent,
                  onTap: () => context.go('/devices'),
                ),
                QuickAction(
                  icon: Icons.block_rounded,
                  label: 'Blocked list',
                  accent: AppColors.danger,
                  onTap: () => context.go('/devices'),
                ),
                QuickAction(
                  icon: Icons.wifi_tethering_rounded,
                  label: 'Guest Wi-Fi',
                  accent: AppColors.secondary,
                  onTap: () => _showPending(
                    context,
                    'Guest Wi-Fi control',
                    'Guest network control is not available in this build.',
                  ),
                ),
                QuickAction(
                  icon: Icons.notifications_active_outlined,
                  label: 'Alerts',
                  accent: AppColors.warning,
                  onTap: () => context.go('/security'),
                ),
              ],
            ),
            const SizedBox(height: 22),
            SectionHeader(
              title: 'Recent activity',
              trailing: TextButton(
                onPressed: () => context.go('/security'),
                child: const Text('View all'),
              ),
            ),
            GlassCard(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: events.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Text(
                        'No activity recorded yet.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < events.length && i < 4; i++) ...[
                          if (i > 0) const Divider(),
                          EventTile(event: events[i]),
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 13,
                  color: theme.textTheme.bodySmall?.color,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isDemo
                        ? 'Demo mode: every value on this screen is synthetic. '
                              'Connect your router in Settings for live data. '
                              'Per-device traffic is not exposed by this firmware.'
                        : 'Live mode: status and wireless clients come from the '
                              'router. WAN throughput and DHCP leases are not '
                              'exposed by this firmware.',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPending(BuildContext context, String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.isDemo});

  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.accent, AppColors.secondary],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.35),
                blurRadius: 16,
                spreadRadius: -4,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.hub_rounded, color: Colors.white, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NEXUS ROUTER',
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 2.2,
                  fontSize: 10.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'TP-Link TL-WR840N · v6.20',
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.5),
              ),
            ],
          ),
        ),
        if (isDemo)
          const DemoBadge()
        else
          const StatusPill('LIVE', color: AppColors.success, dense: true),
      ],
    );
  }
}

class _RouterHero extends StatelessWidget {
  const _RouterHero({required this.status, required this.onRefresh});

  final RouterStatus status;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      glow: AppColors.accent,
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: AppColors.accent.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.25),
                  ),
                ),
                child: const Icon(
                  Icons.router_rounded,
                  color: AppColors.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(status.model, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 3),
                    Text(
                      '${status.mode} mode · ${status.host}',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (status.ssid.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${status.ssid} · ${status.band} · Ch ${status.channel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              StatusPill(
                status.reachable ? 'Connected' : 'Offline',
                color: status.reachable ? AppColors.success : AppColors.danger,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Uptime',
                  value: formatUptime(status.uptime),
                ),
              ),
              const _VerticalDivider(),
              Expanded(
                child: _Metric(label: 'Firmware', value: status.firmware),
              ),
              const _VerticalDivider(),
              Expanded(
                child: _Metric(label: 'Ports', value: '${status.ports} LAN'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.sync_rounded,
                size: 13,
                color: theme.textTheme.bodySmall?.color,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Updated ${timeAgo(status.lastUpdated)}',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.5),
                ),
              ),
              TextButton(
                onPressed: onRefresh,
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Refresh'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(label, style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.5)),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 26,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Theme.of(context).dividerColor,
    );
  }
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
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: i == index
                      ? AppColors.accent.withValues(alpha: 0.16)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  values[i],
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: i == index
                        ? AppColors.accent
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

class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.icon,
    required this.label,
    required this.value,
  });

  final Color color;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.5)),
        const SizedBox(width: 4),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }
}

class _HeroLoading extends StatelessWidget {
  const _HeroLoading();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            'Syncing with router…',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _HeroError extends StatelessWidget {
  const _HeroError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      borderColor: AppColors.danger.withValues(alpha: 0.3),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Router unreachable',
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
