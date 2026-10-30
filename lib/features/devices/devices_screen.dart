import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../core/models/device.dart';
import '../../data/providers.dart';
import '../../shared/device_visuals.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/status_pill.dart';

enum _DeviceFilter { all, online, unknown, favorites, blocked }

class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key});

  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  _DeviceFilter _filter = _DeviceFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(devicesProvider.notifier).refresh(),
      ref.read(routerStatusProvider.notifier).refresh(),
    ]);
  }

  List<Device> _applyFilter(List<Device> devices) {
    final query = _query.trim().toLowerCase();
    return devices.where((device) {
      final matchesQuery =
          query.isEmpty ||
          device.name.toLowerCase().contains(query) ||
          device.ip.toLowerCase().contains(query) ||
          device.mac.toLowerCase().contains(query);
      if (!matchesQuery) return false;

      return switch (_filter) {
        _DeviceFilter.all => true,
        _DeviceFilter.online => device.online,
        _DeviceFilter.unknown => device.isUnknown,
        _DeviceFilter.favorites => device.favorite,
        _DeviceFilter.blocked => device.blocked,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final devicesAsync = ref.watch(devicesProvider);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 12, 0),
            child: devicesAsync.when(
              data: (devices) {
                final online = devices.where((d) => d.online).length;
                return PageHeader(
                  title: 'Devices',
                  subtitle: '$online online · ${devices.length} total',
                  trailing: IconButton(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                );
              },
              loading: () => const PageHeader(title: 'Devices'),
              error: (_, _) => const PageHeader(title: 'Devices'),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search name, IP or MAC',
                prefixIcon: const Icon(Icons.search_rounded, size: 19),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded, size: 17),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          devicesAsync.when(
            data: (devices) => _FilterRow(
              devices: devices,
              selected: _filter,
              onSelected: (filter) => setState(() => _filter = filter),
            ),
            loading: () => const SizedBox(height: 34),
            error: (_, _) => const SizedBox(height: 34),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: devicesAsync.when(
              data: (devices) {
                final filtered = _applyFilter(devices);
                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No devices found',
                    message: _query.isEmpty
                        ? 'Devices will appear here once the router reports them.'
                        : 'Try a different name, IP or MAC address.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: _refresh,
                  color: AppColors.accent,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 130),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return _DeviceCard(device: filtered[index]);
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (error, _) => EmptyState(
                icon: Icons.wifi_off_rounded,
                title: 'Could not load devices',
                message: error.toString(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.devices,
    required this.selected,
    required this.onSelected,
  });

  final List<Device> devices;
  final _DeviceFilter selected;
  final ValueChanged<_DeviceFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final counts = {
      _DeviceFilter.all: devices.length,
      _DeviceFilter.online: devices.where((d) => d.online).length,
      _DeviceFilter.unknown: devices.where((d) => d.isUnknown).length,
      _DeviceFilter.favorites: devices.where((d) => d.favorite).length,
      _DeviceFilter.blocked: devices.where((d) => d.blocked).length,
    };

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _DeviceFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _DeviceFilter.values[index];
          final active = filter == selected;
          return GestureDetector(
            onTap: () => onSelected(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.accent.withValues(alpha: 0.13)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: active
                      ? AppColors.accent.withValues(alpha: 0.3)
                      : Theme.of(context).dividerColor,
                ),
              ),
              child: Text(
                '${_label(filter)} ${counts[filter]}',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: active
                      ? AppColors.accent
                      : Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _label(_DeviceFilter filter) {
    return switch (filter) {
      _DeviceFilter.all => 'All',
      _DeviceFilter.online => 'Online',
      _DeviceFilter.unknown => 'Unknown',
      _DeviceFilter.favorites => 'Favorites',
      _DeviceFilter.blocked => 'Blocked',
    };
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.device});

  final Device device;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = accentForDevice(device.type);
    final offlineColor =
        theme.textTheme.bodySmall?.color ?? AppColors.textSecondary;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      radius: 18,
      onTap: () => context.push('/device/${Uri.encodeComponent(device.mac)}'),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withValues(alpha: 0.22)),
            ),
            child: Icon(iconForDevice(device.type), size: 21, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        device.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (device.favorite) ...[
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.star_rounded,
                        size: 13,
                        color: AppColors.warning,
                      ),
                    ],
                    if (device.blocked) ...[
                      const SizedBox(width: 6),
                      const StatusPill(
                        'Blocked',
                        color: AppColors.danger,
                        dense: true,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${device.ip} · ${device.vendor}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  device.mac,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10.5,
                    fontFamily: 'monospace',
                    letterSpacing: 0.2,
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: 0.7,
                    ),
                  ),
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
                color: device.online ? AppColors.success : offlineColor,
                dense: true,
              ),
              const SizedBox(height: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: offlineColor.withValues(alpha: 0.6),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
