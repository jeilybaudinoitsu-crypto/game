import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class CuteBunnyCanvas extends PositionComponent {
  CuteBunnyCanvas({required Vector2 position})
      : super(position: position, size: Vector2(40, 50), anchor: Anchor.center);

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final whitePaint = Paint()..color = Colors.white;
    final pinkPaint = Paint()..color = const Color(0xFFFFB7B2);
    final eyePaint = Paint()..color = const Color(0xFF4A4A4A);

    // 1. Orejas (dos óvalos verticales)
    canvas.drawOval(
      Rect.fromLTWH(8, 0, 8, 22),
      whitePaint,
    );
    canvas.drawOval(
      Rect.fromLTWH(24, 0, 8, 22),
      whitePaint,
    );
    // Centro de las orejas en rosa pastel
    canvas.drawOval(
      Rect.fromLTWH(10, 4, 4, 14),
      pinkPaint,
    );
    canvas.drawOval(
      Rect.fromLTWH(26, 4, 4, 14),
      pinkPaint,
    );

    // 2. Cabeza (círculo / óvalo)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 18, 32, 28),
        const Radius.circular(16),
      ),
      whitePaint,
    );

    // 3. Ojos (dos círculos pequeños)
    canvas.drawCircle(const Offset(13, 30), 2.5, eyePaint);
    canvas.drawCircle(const Offset(27, 30), 2.5, eyePaint);

    // 4. Nariz (pequeño círculo rosa)
    canvas.drawCircle(const Offset(20, 34), 2, pinkPaint);

    // 5. Mejillas sonrosadas
    final blushPaint = Paint()..color = const Color(0xFFFFB7B2).withOpacity(0.5);
    canvas.drawCircle(const Offset(10, 34), 3, blushPaint);
    canvas.drawCircle(const Offset(30, 34), 3, blushPaint);
  }
}