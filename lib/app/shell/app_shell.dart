import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: _NexusNavBar(
        index: navigationShell.currentIndex,
        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}

class _NexusNavBar extends StatelessWidget {
  const _NexusNavBar({required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.space_dashboard_rounded, 'Home'),
    (Icons.devices_other_rounded, 'Devices'),
    (Icons.insights_rounded, 'Network'),
    (Icons.shield_outlined, 'Security'),
    (Icons.settings_outlined, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final border = dark ? AppColors.border : AppColors.lightBorder;
    final background = dark ? AppColors.background : AppColors.lightBackground;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: background.withValues(alpha: dark ? 0.86 : 0.9),
            border: Border(top: BorderSide(color: border)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
              child: Row(
                children: [
                  for (var i = 0; i < _items.length; i++)
                    Expanded(
                      child: _NavItem(
                        icon: _items[i].$1,
                        label: _items[i].$2,
                        active: i == index,
                        onTap: () => onTap(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final idle = dark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.accent.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: active
                    ? AppColors.accent.withValues(alpha: 0.24)
                    : Colors.transparent,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: active ? AppColors.accent : idle),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? AppColors.accent : idle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
