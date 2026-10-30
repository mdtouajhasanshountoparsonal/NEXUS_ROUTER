import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 22,
    this.glow,
    this.onTap,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? glow;
  final VoidCallback? onTap;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final resolvedBorder =
        borderColor ??
        (dark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.05));
    final gradient = dark
        ? const [Color(0xFF171F2A), Color(0xFF101720)]
        : const [Colors.white, Color(0xFFF7F9FD)];

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        border: Border.all(color: resolvedBorder),
        boxShadow: [
          if (glow != null)
            BoxShadow(
              color: glow!.withValues(alpha: dark ? 0.16 : 0.12),
              blurRadius: 36,
              spreadRadius: -8,
              offset: const Offset(0, 14),
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.28 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
