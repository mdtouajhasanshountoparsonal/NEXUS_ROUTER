import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/theme_controller.dart';
import '../../data/providers.dart';
import '../../shared/widgets/action_button.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/info_row.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/status_pill.dart';
import 'connect_router_sheet.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mode = ref.watch(themeControllerProvider);
    final adapter = ref.watch(routerAdapterProvider);
    final status = ref.watch(routerStatusProvider).value;

    return SafeArea(
      bottom: false,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 130),
        children: [
          const PageHeader(
            title: 'Settings',
            subtitle: 'Appearance, router and local data',
          ),
          const SizedBox(height: 18),
          const SectionHeader(title: 'Appearance'),
          GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: _ThemeOption(
                    icon: Icons.dark_mode_rounded,
                    label: 'Dark',
                    selected: mode == ThemeMode.dark,
                    onTap: () => ref
                        .read(themeControllerProvider.notifier)
                        .setMode(ThemeMode.dark),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ThemeOption(
                    icon: Icons.light_mode_rounded,
                    label: 'Light',
                    selected: mode == ThemeMode.light,
                    onTap: () => ref
                        .read(themeControllerProvider.notifier)
                        .setMode(ThemeMode.light),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ThemeOption(
                    icon: Icons.brightness_auto_rounded,
                    label: 'System',
                    selected: mode == ThemeMode.system,
                    onTap: () => ref
                        .read(themeControllerProvider.notifier)
                        .setMode(ThemeMode.system),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SectionHeader(
            title: 'Router connection',
            trailing: adapter.isDemo
                ? const DemoBadge(compact: true)
                : const StatusPill(
                    'LIVE',
                    color: AppColors.success,
                    dense: true,
                  ),
          ),
          GlassCard(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
            child: Column(
              children: [
                InfoRow(label: 'Adapter', value: adapter.label),
                InfoRow(
                  label: 'Admin host',
                  value: status?.host ?? '192.168.0.1',
                  mono: true,
                ),
                InfoRow(label: 'Model', value: status?.model ?? 'TL-WR840N'),
                InfoRow(
                  label: 'Firmware',
                  value: status?.firmware ?? '—',
                  showDivider: false,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          adapter.isDemo
                              ? 'Demo mode uses synthetic data. Connect to '
                                    'read live status and wireless clients '
                                    'from your TL-WR840N.'
                              : 'Live mode reads status and wireless clients '
                                    'from the router. DHCP leases and WAN '
                                    'counters are not exposed by this firmware.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ActionButton(
                        icon: Icons.link_rounded,
                        label: adapter.isDemo ? 'Connect' : 'Update',
                        color: AppColors.accent,
                        filled: true,
                        onTap: () => _connect(context),
                      ),
                    ],
                  ),
                ),
                if (!adapter.isDemo)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => _disconnect(context, ref),
                        icon: const Icon(Icons.link_off_rounded, size: 16),
                        label: const Text('Disconnect and use demo data'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionHeader(title: 'Local data'),
          GlassCard(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Event history',
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Device names, notes and connection events live in SQLite on '
                  'this device. No cloud sync.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                ActionButton(
                  icon: Icons.delete_outline_rounded,
                  label: 'Clear event history',
                  color: AppColors.danger,
                  onTap: () => _clearHistory(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionHeader(title: 'About'),
          GlassCard(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
            child: const Column(
              children: [
                InfoRow(label: 'App', value: 'NEXUS ROUTER'),
                InfoRow(label: 'Version', value: '1.0.0 (build 1)'),
                InfoRow(label: 'Platform', value: 'Flutter · Android'),
                InfoRow(
                  label: 'Privacy',
                  value: 'Local-first · no cloud',
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Built for TP-Link TL-WR840N v6.20. The router admin panel is '
            'HTTP only, so credentials never leave the local network.',
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.5),
          ),
        ],
      ),
    );
  }

  Future<void> _connect(BuildContext context) async {
    final connected = await showConnectRouterSheet(context);
    if (connected != true || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Router connected. Loading live status…')),
    );
  }

  Future<void> _disconnect(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect router?'),
        content: const Text(
          'Stored router credentials will be deleted from this phone and the '
          'app will show demo data again. Local notes for live devices will '
          'be replaced.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(routerCredentialsProvider.notifier).disconnect();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Disconnected. Showing demo data.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _clearHistory(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear event history?'),
        content: const Text(
          'Connection events and security entries will be removed from this '
          'device. Devices, names and notes are kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear history'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(eventsProvider.notifier).clear();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Local event history cleared.')),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.accent.withValues(alpha: 0.3)
                  : theme.dividerColor,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 19,
                color: selected
                    ? AppColors.accent
                    : theme.textTheme.bodySmall?.color,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? AppColors.accent
                      : theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
