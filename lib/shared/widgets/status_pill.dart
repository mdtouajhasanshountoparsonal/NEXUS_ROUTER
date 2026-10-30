import 'package:flutter/material.dart';

class StatusPill extends StatelessWidget {
  const StatusPill(
    this.label, {
    super.key,
    required this.color,
    this.icon,
    this.dense = false,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 11 : 12, color: color),
            SizedBox(width: dense ? 4 : 5),
          ] else ...[
            Container(
              width: dense ? 5 : 6,
              height: dense ? 5 : 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            SizedBox(width: dense ? 5 : 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: dense ? 10.5 : 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class DemoBadge extends StatelessWidget {
  const DemoBadge({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return StatusPill(
      compact ? 'DEMO' : 'DEMO DATA',
      dense: true,
      color: const Color(0xFFF5A524),
      icon: Icons.science_outlined,
    );
  }
}
