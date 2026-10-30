import 'package:flutter/material.dart';

import '../app/theme/app_colors.dart';
import '../core/models/device.dart';
import '../core/models/network_event.dart';

IconData iconForDevice(DeviceType type) {
  return switch (type) {
    DeviceType.phone => Icons.smartphone_rounded,
    DeviceType.tablet => Icons.tablet_mac_rounded,
    DeviceType.laptop => Icons.laptop_mac_rounded,
    DeviceType.tv => Icons.tv_rounded,
    DeviceType.iot => Icons.memory_rounded,
    DeviceType.printer => Icons.print_rounded,
    DeviceType.unknown => Icons.help_outline_rounded,
  };
}

Color accentForDevice(DeviceType type) {
  return switch (type) {
    DeviceType.phone => AppColors.accent,
    DeviceType.tablet => const Color(0xFFFF9F43),
    DeviceType.laptop => AppColors.info,
    DeviceType.tv => AppColors.secondary,
    DeviceType.iot => AppColors.success,
    DeviceType.printer => const Color(0xFFFFD166),
    DeviceType.unknown => AppColors.textSecondary,
  };
}

Color eventColor(EventSeverity severity) {
  return switch (severity) {
    EventSeverity.success => AppColors.success,
    EventSeverity.warning => AppColors.warning,
    EventSeverity.danger => AppColors.danger,
    EventSeverity.info => AppColors.info,
  };
}

IconData iconForEvent(EventKind kind) {
  return switch (kind) {
    EventKind.joined => Icons.login_rounded,
    EventKind.left => Icons.logout_rounded,
    EventKind.unknownJoined => Icons.help_outline_rounded,
    EventKind.blocked => Icons.block_rounded,
    EventKind.unblocked => Icons.lock_open_rounded,
    EventKind.alert => Icons.warning_amber_rounded,
    EventKind.system => Icons.memory_rounded,
  };
}
