import 'dart:ui';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:flame/extensions.dart';

import 'color.dart';

/// Red central punteada, color verde menta.
class CuteNet extends PositionComponent {
  CuteNet({required Vector2 position, required this.courtHeight})
      : super(
          position: position,
          size: Vector2(8, courtHeight),
          anchor: Anchor.topLeft,
        );

  /// Altura del dibujo punteado (normalmente la altura de la cancha).
  final double courtHeight;

  static const double _dashHeight = 12;
  static const double _dashGap = 10;

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = CuteTheme.net;
    final rect = size.toRect();

    // Dibuja la linea punteada a lo largo de toda la altura del campo.
    for (var y = 0.0; y < courtHeight; y += _dashHeight + _dashGap) {
      final dash = Rect.fromLTWH(rect.left, y, rect.width, _dashHeight);
      canvas.drawRRect(
        RRect.fromRectAndRadius(dash, const Radius.circular(4)),
        paint,
      );
    }
  }

}

/// Marco redondeado que delimita la cancha.
class CourtFrame extends PositionComponent {
  CourtFrame({required Vector2 position, required Vector2 size})
      : super(position: position, size: size, anchor: Anchor.topLeft);

  @override
  void render(Canvas canvas) {
    final rect = size.toRect().deflate(6);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(34));

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = CuteTheme.white.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0x33C9A7D4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

}

/// Un corazon dibujado con curvas, centrado en el origen.
Path heartPath(double size) {
  final h = size / 2;
  final w = size / 2;
  return Path()
    ..moveTo(0, h)
    ..cubicTo(-w * 1.6, -h * 0.05, -w * 0.75, -h * 1.55, 0, -h * 0.55)
    ..cubicTo(w * 0.75, -h * 1.55, w * 1.6, -h * 0.05, 0, h)
    ..close();
}

/// Nube puffy formada por circulos solapados.
void drawCloud(Canvas canvas, Offset center, double width, Color color) {
  final paint = Paint()..color = color;
  final r = width / 5;
  canvas.drawCircle(center.translate(-width * 0.28, r * 0.25), r, paint);
  canvas.drawCircle(center.translate(0, -r * 0.15), r * 1.35, paint);
  canvas.drawCircle(center.translate(width * 0.30, r * 0.25), r * 0.95, paint);
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center.translate(0, r * 0.35),
        width: width * 0.92,
        height: r * 1.5,
      ),
      Radius.circular(r),
    ),
    paint,
  );
}

/// Fondo decorativo pastel: nubes y corazoncitos a la deriva.
///
/// Usa una semilla fija para que el decorado sea siempre el mismo.
class PastelBackdrop extends PositionComponent {
  PastelBackdrop({required Vector2 position, required Vector2 size})
      : super(position: position, size: size, anchor: Anchor.topLeft);

  final List<_Drifter> _drifters = [];
  final math.Random _random = math.Random(2024);

  @override
  void onMount() {
    super.onMount();
    final area = size.x * size.y;
    final count = math.max(6, (area / 90000).round().clamp(6, 26));
    for (var i = 0; i < count; i++) {
      _drifters.add(
        _Drifter(
          x: _random.nextDouble() * size.x,
          y: _random.nextDouble() * size.y,
          scale: 0.5 + _random.nextDouble() * 0.9,
          speed: 4 + _random.nextDouble() * 10,
          phase: _random.nextDouble() * math.pi * 2,
          isHeart: _random.nextBool(),
          color: _pickColor(),
        ),
      );
    }
  }

  Color _pickColor() {
    const palette = [
      CuteTheme.player1,
      CuteTheme.player2,
      CuteTheme.lilac,
      CuteTheme.sky,
      CuteTheme.mint,
    ];
    return palette[_random.nextInt(palette.length)];
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (final d in _drifters) {
      d.y -= d.speed * dt;
      d.phase += dt * 0.8;
      if (d.y < -40) {
        d.y = size.y + 40;
        d.x = _random.nextDouble() * size.x;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // Nubes grandes al fondo.
    drawCloud(
      canvas,
      Offset(size.x * 0.18, size.y * 0.22),
      size.x * 0.42,
      const Color(0xFFFFFFFF),
    );
    drawCloud(
      canvas,
      Offset(size.x * 0.84, size.y * 0.74),
      size.x * 0.36,
      const Color(0xFFFFFFFF),
    );

    final base = math.min(size.x, size.y);
    for (final d in _drifters) {
      final bob = math.sin(d.phase) * 6;
      final p = Offset(
        d.x + math.cos(d.phase * 0.6) * 5,
        d.y + bob,
      );
      final s = base * 0.045 * d.scale;
      final paint = Paint()..color = d.color.withValues(alpha: 0.32);

      if (d.isHeart) {
        canvas.save();
        canvas.translate(p.dx, p.dy);
        canvas.rotate(math.sin(d.phase * 0.4) * 0.25);
        canvas.drawPath(heartPath(s), paint);
        canvas.restore();
      } else {
        canvas.drawCircle(p, s * 0.45, paint);
        canvas.drawCircle(
          p.translate(s * 0.35, s * 0.2),
          s * 0.22,
          paint..color = d.color.withValues(alpha: 0.22),
        );
      }
    }
  }

}

class _Drifter {
  _Drifter({
    required this.x,
    required this.y,
    required this.scale,
    required this.speed,
    required this.phase,
    required this.isHeart,
    required this.color,
  });

  double x;
  double y;
  final double scale;
  final double speed;
  double phase;
  final bool isHeart;
  final Color color;
}