import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../core/models/device.dart';
import '../../core/models/network_event.dart';
import '../../data/providers.dart';
import '../../shared/widgets/action_button.dart';
import '../../shared/widgets/event_tile.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/status_pill.dart';

class SecurityScreen extends ConsumerWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final devices = ref.watch(devicesProvider).value ?? const <Device>[];
    final events = ref.watch(eventsProvider).value ?? const <NetworkEvent>[];
    final rules = ref.watch(alertRulesProvider);
    final isDemo = ref.watch(routerAdapterProvider).isDemo;
    final rulesNotifier = ref.read(alertRulesProvider.notifier);

    final unknownCount = devices.where((device) => device.isUnknown).length;
    final blockedCount = devices.where((device) => device.blocked).length;
    final trustedCount = devices.where((device) => device.trusted).length;
    final score = (100 - unknownCount * 8 - 6).clamp(0, 100);
    final scoreColor = score >= 80
        ? AppColors.success
        : score >= 60
        ? AppColors.warning
        : AppColors.danger;

    final securityEvents = events
        .where(
          (event) =>
              event.severity == EventSeverity.warning ||
              event.severity == EventSeverity.danger ||
              event.kind == EventKind.unknownJoined ||
              event.kind == EventKind.blocked,
        )
        .take(6)
        .toList();

    return SafeArea(
      bottom: false,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 130),
        children: [
          PageHeader(
            title: 'Security',
            subtitle: 'Devices, alerts and policy changes',
            trailing: isDemo
                ? const DemoBadge(compact: true)
                : const StatusPill(
                    'LIVE',
                    color: AppColors.success,
                    dense: true,
                  ),
          ),
          const SizedBox(height: 18),
          GlassCard(
            glow: scoreColor,
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                SizedBox(
                  width: 84,
                  height: 84,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: score / 100,
                          strokeWidth: 8,
                          strokeCap: StrokeCap.round,
                          backgroundColor: theme.dividerColor,
                          color: scoreColor,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$score',
                            style: const TextStyle(
                              fontSize: 23,
                              height: 1,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '/ 100',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Security score',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        unknownCount > 0
                            ? '$unknownCount unknown device'
                                  '${unknownCount == 1 ? '' : 's'} need review. '
                                  'Admin panel runs over HTTP.'
                            : 'No unknown devices. Admin panel still runs '
                                  'over HTTP.',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          StatusPill(
                            '$blockedCount blocked',
                            color: AppColors.danger,
                            dense: true,
                          ),
                          const SizedBox(width: 6),
                          StatusPill(
                            '$trustedCount trusted',
                            color: AppColors.success,
                            dense: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'Assessment'),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _FactorRow(
                  icon: Icons.help_outline_rounded,
                  color: unknownCount > 0
                      ? AppColors.warning
                      : AppColors.success,
                  title: 'Unknown devices',
                  value: unknownCount > 0
                      ? '$unknownCount on the network'
                      : 'None detected',
                ),
                _FactorRow(
                  icon: Icons.lock_outline_rounded,
                  color: AppColors.warning,
                  title: 'Admin transport',
                  value: 'HTTP only · no TLS on this firmware',
                ),
                _FactorRow(
                  icon: Icons.wifi_off_rounded,
                  color: AppColors.info,
                  title: 'Blocked devices',
                  value: '$blockedCount blocked by policy',
                ),
                _FactorRow(
                  icon: Icons.verified_user_outlined,
                  color: AppColors.success,
                  title: 'Trusted devices',
                  value: '$trustedCount of ${devices.length} marked trusted',
                  last: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'Alert rules'),
          GlassCard(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              children: [
                SwitchRow(
                  title: 'New device joined',
                  subtitle: 'Notify when a new MAC appears on the network',
                  value: rules.newDevice,
                  onChanged: (value) => rulesNotifier.setNewDevice(value),
                ),
                const Divider(),
                SwitchRow(
                  title: 'Unknown device',
                  subtitle: 'Extra warning for unrecognised devices',
                  value: rules.unknownDevice,
                  onChanged: (value) => rulesNotifier.setUnknownDevice(value),
                ),
                const Divider(),
                SwitchRow(
                  title: 'Router offline',
                  subtitle: 'Alert when monitoring cannot reach the router',
                  value: rules.routerOffline,
                  onChanged: (value) => rulesNotifier.setRouterOffline(value),
                ),
                const Divider(),
                SwitchRow(
                  title: 'Repeated disconnects',
                  subtitle: 'A device keeps dropping off the network',
                  value: rules.repeatedDisconnects,
                  onChanged: (value) =>
                      rulesNotifier.setRepeatedDisconnects(value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionHeader(
            title: 'Security events',
            trailing: Text(
              '${securityEvents.length} shown',
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.5),
            ),
          ),
          GlassCard(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: securityEvents.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Text(
                      'Nothing to review right now.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < securityEvents.length; i++) ...[
                        if (i > 0) const Divider(),
                        EventTile(event: securityEvents[i]),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            isDemo
                ? 'The score is a local heuristic based on demo device state, '
                      'not a live vulnerability scan. Alerts are stored on this '
                      'device only.'
                : 'The score is a local heuristic based on live device state '
                      'and MAC-filter policy, not a vulnerability scan. Alerts '
                      'are stored on this device only.',
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}

class _FactorRow extends StatelessWidget {
  const _FactorRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    this.last = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 13.5),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        if (!last) const Divider(),
      ],
    );
  }
}
