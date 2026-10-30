import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/dashboard_screen.dart';
import '../features/devices/device_detail_screen.dart';
import '../features/devices/devices_screen.dart';
import '../features/network/network_screen.dart';
import '../features/security/security_screen.dart';
import '../features/settings/settings_screen.dart';
import 'shell/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/devices',
                builder: (context, state) => const DevicesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/network',
                builder: (context, state) => const NetworkScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/security',
                builder: (context, state) => const SecurityScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/device/:mac',
        builder: (context, state) {
          final mac = Uri.decodeComponent(state.pathParameters['mac'] ?? '');
          return DeviceDetailScreen(mac: mac);
        },
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
