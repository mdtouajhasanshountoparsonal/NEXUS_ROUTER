import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class NetworkSparkline extends StatelessWidget {
  const NetworkSparkline({
    super.key,
    required this.values,
    required this.color,
    this.height = 88,
    this.fill = true,
  });

  final List<double> values;
  final Color color;
  final double height;
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparklinePainter(
          values: values,
          color: color,
          fill: fill,
          gridColor: (dark ? Colors.white : Colors.black).withValues(
            alpha: 0.055,
          ),
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.color,
    required this.fill,
    required this.gridColor,
  });

  final List<double> values;
  final Color color;
  final bool fill;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (values.length < 2) return;

    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final span = (maxValue - minValue).abs() < 0.001
        ? 1.0
        : maxValue - minValue;
    const topPadding = 7.0;
    final usableHeight = size.height - topPadding;

    Offset pointAt(int index) {
      final x = size.width * index / (values.length - 1);
      final normalized = (values[index] - minValue) / span;
      final y = topPadding + usableHeight * (1 - normalized);
      return Offset(x, y);
    }

    final line = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 1; i < values.length; i++) {
      final previous = pointAt(i - 1);
      final current = pointAt(i);
      final midX = (previous.dx + current.dx) / 2;
      line.cubicTo(midX, previous.dy, midX, current.dy, current.dx, current.dy);
    }

    if (fill) {
      final area = Path.from(line)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      final shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.26), color.withValues(alpha: 0)],
      ).createShader(Offset.zero & size);
      canvas.drawPath(area, Paint()..shader = shader);
    }

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(line, stroke);

    final last = pointAt(values.length - 1);
    canvas.drawCircle(last, 6, Paint()..color = color.withValues(alpha: 0.18));
    canvas.drawCircle(last, 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.fill != fill ||
        oldDelegate.gridColor != gridColor ||
        !listEquals(oldDelegate.values, values);
  }
}
