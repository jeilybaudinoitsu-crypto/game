import 'dart:ui';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:flame/extensions.dart';

import 'color.dart';

/// Conejo dibujado a mano con Canvas.
///
/// Se usa como respaldo cuando las imagenes de `lib/assets/imagenes/` no estan
/// disponibles, y como elemento decorativo del menu.
class CuteBunny extends PositionComponent {
  CuteBunny({required super.position, double scale = 1.0, super.anchor})
      : super(size: Vector2(64 * scale, 80 * scale));

  double _time = 0;
  bool _blink = false;
  double _blinkTimer = 3;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    _blinkTimer -= dt;
    if (_blinkTimer <= 0) {
      _blink = !_blink;
      _blinkTimer = _blink ? 0.12 : 2.4 + math.Random().nextDouble() * 2.2;
    }
  }

  @override
  void render(Canvas canvas) {
    final s = size.x / 64;
    final bob = math.sin(_time * 2.2) * 2.0 * s;

    canvas.save();
    canvas.translate((size.x - 64 * s) / 2, (size.y - 80 * s) / 2 + bob);

    final white = Paint()..color = CuteTheme.white;
    final pink = Paint()..color = CuteTheme.player1;
    final earPink = Paint()..color = CuteTheme.player1Dark;
    final eye = Paint()..color = const Color(0xFF4A4A4A);
    final blush = Paint()..color = CuteTheme.player1.withValues(alpha: 0.5);

    // Sombra en el suelo.
    canvas.drawOval(
      Rect.fromLTWH(12 * s, 70 * s, 40 * s, 7 * s),
      Paint()..color = CuteTheme.shadow,
    );

    // 1. Orejas (dos Capsules verticales con inclinacion).
    final earTilt = math.sin(_time * 1.7) * 0.06;
    _drawEar(canvas, Offset(20 * s, 4 * s), earTilt, s, white, earPink);
    _drawEar(canvas, Offset(44 * s, 4 * s), -earTilt, s, white, earPink);

    // 2. Cuerpo.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(16 * s, 44 * s, 32 * s, 28 * s),
        Radius.circular(14 * s),
      ),
      white,
    );

    // 3. Patas.
    canvas.drawOval(Rect.fromLTWH(12 * s, 66 * s, 16 * s, 9 * s), white);
    canvas.drawOval(Rect.fromLTWH(36 * s, 66 * s, 16 * s, 9 * s), white);

    // 4. Cabeza.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(10 * s, 22 * s, 44 * s, 34 * s),
        Radius.circular(17 * s),
      ),
      white,
    );

    // 5. Ojos (parpadeo ocasional).
    if (_blink) {
      final lid = Paint()
        ..color = const Color(0xFF4A4A4A)
        ..strokeWidth = 1.6 * s
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(20 * s, 38 * s), Offset(25 * s, 38 * s), lid);
      canvas.drawLine(Offset(39 * s, 38 * s), Offset(44 * s, 38 * s), lid);
    } else {
      canvas.drawCircle(Offset(22.5 * s, 38 * s), 2.6 * s, eye);
      canvas.drawCircle(Offset(41.5 * s, 38 * s), 2.6 * s, eye);
      canvas.drawCircle(Offset(23.3 * s, 37.2 * s), 0.9 * s, white);
      canvas.drawCircle(Offset(42.3 * s, 37.2 * s), 0.9 * s, white);
    }

    // 6. Nariz y boca.
    canvas.drawCircle(Offset(32 * s, 44 * s), 2.2 * s, pink);
    canvas.drawArc(
      Rect.fromLTWH(28.5 * s, 44 * s, 7 * s, 6 * s),
      0,
      math.pi * 0.9,
      false,
      Paint()
        ..color = const Color(0xFF4A4A4A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * s
        ..strokeCap = StrokeCap.round,
    );

    // 7. Mejillas sonrosadas.
    canvas.drawCircle(Offset(17 * s, 44 * s), 3.4 * s, blush);
    canvas.drawCircle(Offset(47 * s, 44 * s), 3.4 * s, blush);

    canvas.restore();
  }

  void _drawEar(
    Canvas canvas,
    Offset origin,
    double tilt,
    double s,
    Paint white,
    Paint inner,
  ) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(tilt);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, 9 * s, 24 * s),
        Radius.circular(4.5 * s),
      ),
      white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2 * s, 4 * s, 5 * s, 15 * s),
        Radius.circular(2.5 * s),
      ),
      inner,
    );
    canvas.restore();
  }

}