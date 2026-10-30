import 'package:flutter/material.dart';

import '../../core/models/network_event.dart';
import '../../core/utils/formatters.dart';
import '../device_visuals.dart';

class EventTile extends StatelessWidget {
  const EventTile({super.key, required this.event});

  final NetworkEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = eventColor(event.severity);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.20)),
            ),
            child: Icon(iconForEvent(event.kind), size: 17, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 13.5),
                ),
                const SizedBox(height: 3),
                Text(
                  event.detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            timeAgo(event.createdAt),
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10.5,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
