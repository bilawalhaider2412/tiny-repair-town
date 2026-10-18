/// Programmatic tile/part art for Stage 3 (development assets).
///
/// Real illustration assets are still missing (docs/ASSET_LIST.md); these
/// painters give every tile a shape AND a pattern marking in addition to
/// colour (spec §7: never colour-only). Shapes: star, circle, triangle,
/// diamond, heart, square, rounded_square. Patterns: stripes, dots, waves,
/// checks, plain.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_theme.dart';

/// Soft fill colours per shape (decoration only — identity is shape+pattern).
const Map<String, Color> shapeColors = {
  'star': Color(0xFFF28C7A), // coral
  'circle': Color(0xFF63B8E8), // blue
  'triangle': Color(0xFF7BCB8B), // green
  'diamond': Color(0xFFF5CF63), // yellow
  'heart': Color(0xFFB983D6), // soft purple
  'square': Color(0xFF63B8E8),
  'rounded_square': Color(0xFF63B8E8),
};

class TileArt extends StatelessWidget {
  final String shape;
  final String pattern;
  final double size;

  const TileArt({
    super.key,
    required this.shape,
    required this.pattern,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _TilePainter(shape: shape, pattern: pattern)),
    );
  }
}

class _TilePainter extends CustomPainter {
  final String shape;
  final String pattern;

  _TilePainter({required this.shape, required this.pattern});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(size.width, size.height) / 2 - 4;
    final path = _shapePath(shape, cx, cy, r);

    final fill = Paint()
      ..color = (shapeColors[shape] ?? TownTheme.yellow).withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fill);

    final outline = Paint()
      ..color = TownTheme.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawPath(path, outline);

    // Pattern marking (darker tone) inside the shape.
    final mark = Paint()
      ..color = TownTheme.ink.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final dot = Paint()..color = TownTheme.ink.withValues(alpha: 0.55);
    switch (pattern) {
      case 'stripes':
        for (var i = -2; i <= 2; i++) {
          canvas.drawLine(
            Offset(cx + i * r / 3, cy - r * 0.55),
            Offset(cx + i * r / 3, cy + r * 0.55),
            mark,
          );
        }
      case 'dots':
        for (final o in [const Offset(-0.3, -0.25), const Offset(0.3, -0.25),
            const Offset(0, 0.1), const Offset(-0.3, 0.35), const Offset(0.3, 0.35)]) {
          canvas.drawCircle(Offset(cx + o.dx * r, cy + o.dy * r), 3.2, dot);
        }
      case 'waves':
        for (var row = -1; row <= 1; row++) {
          final p = Path();
          final y0 = cy + row * r * 0.4;
          p.moveTo(cx - r * 0.55, y0);
          for (var x = -0.55; x < 0.55; x += 0.1) {
            p.lineTo(cx + x * r, y0 + math.sin(x * 12) * 3);
          }
          canvas.drawPath(p, mark);
        }
      case 'checks':
        canvas.drawLine(Offset(cx - r * 0.5, cy), Offset(cx + r * 0.5, cy), mark);
        canvas.drawLine(Offset(cx, cy - r * 0.5), Offset(cx, cy + r * 0.5), mark);
      case 'plain':
        break;
    }
  }

  Path _shapePath(String shape, double cx, double cy, double r) {
    switch (shape) {
      case 'circle':
        return Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
      case 'square':
        return Path()
          ..addRect(Rect.fromCenter(center: Offset(cx, cy), width: 2 * r, height: 2 * r));
      case 'rounded_square':
        return Path()
          ..addRRect(RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(cx, cy), width: 2 * r, height: 2 * r),
              const Radius.circular(10)));
      case 'triangle':
        return Path()
          ..moveTo(cx, cy - r)
          ..lineTo(cx + r, cy + r * 0.85)
          ..lineTo(cx - r, cy + r * 0.85)
          ..close();
      case 'diamond':
        return Path()
          ..moveTo(cx, cy - r)
          ..lineTo(cx + r * 0.8, cy)
          ..lineTo(cx, cy + r)
          ..lineTo(cx - r * 0.8, cy)
          ..close();
      case 'heart':
        final p = Path();
        p.moveTo(cx, cy + r * 0.85);
        p.cubicTo(cx - r * 1.4, cy + r * 0.1, cx - r * 0.7, cy - r, cx, cy - r * 0.35);
        p.cubicTo(cx + r * 0.7, cy - r, cx + r * 1.4, cy + r * 0.1, cx, cy + r * 0.85);
        return p;
      case 'star':
        final p = Path();
        for (var i = 0; i < 10; i++) {
          final rr = i.isEven ? r : r * 0.45;
          final a = -math.pi / 2 + i * math.pi / 5;
          final x = cx + rr * math.cos(a);
          final y = cy + rr * math.sin(a);
          if (i == 0) {
            p.moveTo(x, y);
          } else {
            p.lineTo(x, y);
          }
        }
        p.close();
        return p;
      default:
        return Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    }
  }

  @override
  bool shouldRepaint(covariant _TilePainter old) =>
      old.shape != shape || old.pattern != pattern;
}

/// Dashed outline slot for system A (empty drop target with shape hint).
class SlotOutline extends StatelessWidget {
  final String shapeHint;

  const SlotOutline({super.key, required this.shapeHint});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SlotPainter(shapeHint: shapeHint),
      child: const SizedBox.expand(),
    );
  }
}

class _SlotPainter extends CustomPainter {
  final String shapeHint;
  _SlotPainter({required this.shapeHint});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(size.width, size.height) / 2 - 6;
    final paint = Paint()
      ..color = TownTheme.ink.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    // Dashed effect via short segments: draw the outline path twice, once as
    // a dashed approximation using path metrics.
    final base = _TilePainter(shape: shapeHint, pattern: 'plain')
        ._shapePath(shapeHint, cx, cy, r);
    final dashed = Path();
    for (final metric in base.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        dashed.addPath(metric.extractPath(dist, dist + 8), Offset.zero);
        dist += 14;
      }
    }
    canvas.drawPath(dashed, paint);
  }

  @override
  bool shouldRepaint(covariant _SlotPainter old) =>
      old.shapeHint != shapeHint;
}
