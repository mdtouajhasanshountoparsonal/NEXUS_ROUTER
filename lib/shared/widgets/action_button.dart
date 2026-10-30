import 'package:flutter/material.dart';

import 'glass_card.dart';

class QuickAction extends StatelessWidget {
  const QuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      radius: 14,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: color.withValues(alpha: filled ? 0.18 : 0.09),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 7),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 12.5,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SwitchRow extends StatelessWidget {
  const SwitchRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 3),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
