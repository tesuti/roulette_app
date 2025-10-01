import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/models/roulette_item_model.dart';
import '../../../utils/color_utils.dart';

class RouletteWheel extends StatelessWidget {
  const RouletteWheel({
    super.key,
    required this.items,
    required this.rotation,
    this.selectedItemId,
  });

  final List<RouletteItemModel> items;
  final double rotation;
  final int? selectedItemId;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.shortestSide;
        final wheelSize = size == double.infinity ? 320.0 : size;
        return SizedBox(
          width: wheelSize,
          height: wheelSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: rotation,
                child: CustomPaint(
                  size: Size.square(wheelSize),
                  painter: _RouletteWheelPainter(
                    items: items,
                    selectedItemId: selectedItemId,
                  ),
                ),
              ),
              Positioned(
                top: wheelSize * 0.02,
                child: CustomPaint(
                  size: Size(wheelSize * 0.12, wheelSize * 0.12),
                  painter: _PointerPainter(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              Container(
                width: wheelSize * 0.2,
                height: wheelSize * 0.2,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.brightness_1, size: 12, color: Colors.black26),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RouletteWheelPainter extends CustomPainter {
  _RouletteWheelPainter({required this.items, required this.selectedItemId});

  final List<RouletteItemModel> items;
  final int? selectedItemId;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final totalWeight = items.fold<double>(0, (sum, item) => sum + _effectiveWeight(item));
    if (totalWeight == 0) {
      return;
    }

    final fillPaint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white
      ..strokeWidth = 2;

    double startAngle = -math.pi / 2;

    for (final item in items) {
      final sweep = (_effectiveWeight(item) / totalWeight) * math.pi * 2;
      fillPaint.color = hexToColor(item.colorHex);
      canvas.drawArc(rect, startAngle, sweep, true, fillPaint);

      if (selectedItemId != null && selectedItemId == item.id) {
        final highlight = Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.white.withOpacity(0.6)
          ..strokeWidth = 6;
        canvas.drawArc(rect.deflate(4), startAngle, sweep, false, highlight);
      }

      canvas.drawLine(
        center,
        Offset(
          center.dx + radius * math.cos(startAngle),
          center.dy + radius * math.sin(startAngle),
        ),
        borderPaint,
      );

      _drawLabel(canvas, center, radius, startAngle, sweep, item.label);

      startAngle += sweep;
    }

    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _RouletteWheelPainter oldDelegate) {
    return oldDelegate.items != items || oldDelegate.selectedItemId != selectedItemId;
  }

  double _effectiveWeight(RouletteItemModel item) {
    return item.weight <= 0 ? 1.0 : item.weight;
  }

  void _drawLabel(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double sweepAngle,
    String text,
  ) {
    if (text.isEmpty) {
      return;
    }

    final angle = startAngle + sweepAngle / 2;
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    );
    textPainter.layout(maxWidth: radius * 0.9);

    final offset = Offset(
      center.dx + math.cos(angle) * radius * 0.55,
      center.dy + math.sin(angle) * radius * 0.55,
    );

    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.rotate(angle + math.pi / 2);
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
    canvas.restore();
  }
}

class _PointerPainter extends CustomPainter {
  _PointerPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawShadow(path, Colors.black54, 4, false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PointerPainter oldDelegate) => oldDelegate.color != color;
}
