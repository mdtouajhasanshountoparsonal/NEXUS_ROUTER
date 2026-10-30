import 'package:flutter/material.dart';

class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.mono = false,
    this.trailing,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final bool mono;
  final Widget? trailing;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 112,
                child: Text(label, style: theme.textTheme.bodyMedium),
              ),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    fontFamily: mono ? 'monospace' : null,
                    letterSpacing: mono ? 0.2 : null,
                  ),
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 6), trailing!],
            ],
          ),
        ),
        if (showDivider) const Divider(),
      ],
    );
  }
}
