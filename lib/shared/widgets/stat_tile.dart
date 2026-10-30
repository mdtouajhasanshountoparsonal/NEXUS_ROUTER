import 'package:flutter/material.dart';

import 'glass_card.dart';

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.unit,
    this.footnote,
    this.onTap,
  });

  final String label;
  final String value;
  final String? unit;
  final String? footnote;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(14),
      radius: 18,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: accent.withValues(alpha: 0.22)),
                ),
                child: Icon(icon, size: 15, color: accent),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 25,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.9,
                    ),
                  ),
                ),
              ),
              if (unit != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 2),
                  child: Text(
                    unit!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (footnote != null) ...[
            const SizedBox(height: 5),
            Text(
              footnote!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10.5,
                color: theme.textTheme.bodySmall?.color?.withValues(
                  alpha: 0.75,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
