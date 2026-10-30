import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../core/models/device.dart';
import '../../core/models/network_event.dart';
import '../../core/utils/formatters.dart';
import '../../data/providers.dart';
import '../../shared/device_visuals.dart';
import '../../shared/widgets/action_button.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/event_tile.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/info_row.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/status_pill.dart';

class DeviceDetailScreen extends ConsumerWidget {
  const DeviceDetailScreen({super.key, required this.mac});

  final String mac;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(devicesProvider);

    Device? found;
    for (final device in devicesAsync.value ?? const <Device>[]) {
      if (device.mac == mac) {
        found = device;
        break;
      }
    }

    if (found == null && devicesAsync.isLoading) {
      return const Scaffold(
        body: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final device = found;
    if (device == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.device_unknown_rounded,
          title: 'Device not found',
          message: 'This device is no longer in the local database.',
        ),
      );
    }

    final accent = accentForDevice(device.type);
    final events = (ref.watch(eventsProvider).value ?? const <NetworkEvent>[])
        .where((event) => event.mac == device.mac)
        .take(10)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device details'),
        actions: [
          IconButton(
            tooltip: device.favorite ? 'Remove favorite' : 'Add favorite',
            onPressed: () {
              ref
                  .read(devicesProvider.notifier)
                  .save(device.copyWith(favorite: !device.favorite));
            },
            icon: Icon(
              device.favorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: device.favorite ? AppColors.warning : null,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 48),
        children: [
          GlassCard(
            glow: accent,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Icon(
                        iconForDevice(device.type),
                        size: 25,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${Device.typeLabel(device.type)} · '
                            '${Device.groupLabel(device.group)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        StatusPill(
                          device.online ? 'Online' : 'Offline',
                          color: device.online
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                        if (device.blocked) ...[
                          const SizedBox(height: 6),
                          const StatusPill(
                            'Blocked',
                            color: AppColors.danger,
                            dense: true,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                if (device.notes.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.sticky_note_2_outlined,
                        size: 15,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          device.notes,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionHeader(
            title: 'Local identity',
            trailing: Text(
              'Stored on this phone',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(fontSize: 10.5),
            ),
          ),
          GlassCard(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
            child: Column(
              children: [
                InfoRow(label: 'MAC address', value: device.mac, mono: true),
                InfoRow(label: 'IP address', value: device.ip, mono: true),
                InfoRow(label: 'Vendor', value: device.vendor),
                InfoRow(label: 'Group', value: Device.groupLabel(device.group)),
                InfoRow(
                  label: 'First seen',
                  value: formatDateTime(device.firstSeen),
                ),
                InfoRow(
                  label: 'Last seen',
                  value: device.online
                      ? 'Online now'
                      : '${formatDateTime(device.lastSeen)} '
                            '(${timeAgo(device.lastSeen)})',
                ),
                InfoRow(
                  label: 'Trusted',
                  value: device.trusted ? 'Yes' : 'Not marked',
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Actions'),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ActionButton(
                icon: Icons.edit_rounded,
                label: 'Rename',
                color: AppColors.info,
                onTap: () => _rename(context, ref, device),
              ),
              ActionButton(
                icon: Icons.sticky_note_2_outlined,
                label: 'Notes',
                color: AppColors.secondary,
                onTap: () => _editNotes(context, ref, device),
              ),
              ActionButton(
                icon: device.favorite
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                label: device.favorite ? 'Favorited' : 'Favorite',
                color: AppColors.warning,
                onTap: () {
                  ref
                      .read(devicesProvider.notifier)
                      .save(device.copyWith(favorite: !device.favorite));
                },
              ),
              ActionButton(
                icon: Icons.verified_user_outlined,
                label: device.trusted ? 'Trusted' : 'Mark trusted',
                color: AppColors.success,
                onTap: () {
                  ref
                      .read(devicesProvider.notifier)
                      .save(device.copyWith(trusted: !device.trusted));
                },
              ),
              ActionButton(
                icon: device.blocked
                    ? Icons.lock_open_rounded
                    : Icons.block_rounded,
                label: device.blocked ? 'Unblock' : 'Block device',
                color: AppColors.danger,
                filled: true,
                onTap: () => _toggleBlock(context, ref, device),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SectionHeader(
            title: 'Connection history',
            trailing: Text(
              '${events.length} events',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(fontSize: 10.5),
            ),
          ),
          GlassCard(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: events.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No events recorded for this device yet.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < events.length; i++) ...[
                        if (i > 0) const Divider(),
                        EventTile(event: events[i]),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About usage data',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontSize: 13.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'This firmware does not expose per-device traffic '
                        'counters. NEXUS tracks connection history locally '
                        'instead of showing fabricated usage numbers.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    Device device,
  ) async {
    final controller = TextEditingController(text: device.name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename device'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 40,
          decoration: const InputDecoration(hintText: 'Device name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(controller.text.trim());
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (result == null || result.isEmpty || result == device.name) return;
    await ref
        .read(devicesProvider.notifier)
        .save(device.copyWith(name: result));
  }

  Future<void> _editNotes(
    BuildContext context,
    WidgetRef ref,
    Device device,
  ) async {
    final controller = TextEditingController(text: device.notes);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Device notes'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 3,
          maxLines: 5,
          maxLength: 200,
          decoration: const InputDecoration(
            hintText: 'Whose phone is this? Anything worth remembering.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(controller.text.trim());
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (result == null) return;
    await ref
        .read(devicesProvider.notifier)
        .save(device.copyWith(notes: result));
  }

  Future<void> _toggleBlock(
    BuildContext context,
    WidgetRef ref,
    Device device,
  ) async {
    final blocking = !device.blocked;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(blocking ? 'Block this device?' : 'Unblock this device?'),
        content: Text(
          blocking
              ? '${device.name} will lose network access after the router '
                    'confirms the policy change. You can undo this from the '
                    'device page.'
              : '${device.name} will be allowed back on the network.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: blocking ? AppColors.danger : AppColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(blocking ? 'Block device' : 'Unblock'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(devicesProvider.notifier).setBlocked(device, blocking);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${device.name} ${blocking ? 'blocked' : 'unblocked'} · '
            'verified on router',
          ),
        ),
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
}
