import 'package:flutter/material.dart';

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.displaySmall),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(subtitle!, style: theme.textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        if (trailing != null) const SizedBox(width: 12),
        ?trailing,
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.bottomPadding = 12,
  });

  final String title;
  final Widget? trailing;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Row(
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}
