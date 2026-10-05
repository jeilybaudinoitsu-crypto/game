import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class CutePaddle extends PositionComponent {
  final Color color;

  CutePaddle({
    required Vector2 position,
    required Vector2 size,
    required this.color,
  }) : super(position: position, size: size);

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()..color = color;
    
    // RRect permite crear rectángulos con bordes suavizados/redondeados
    final RRect rrect = RRect.fromRectAndRadius(
      size.toRect(),
      const Radius.circular(16), // Radio del redondeo
    );
    
    canvas.drawRRect(rrect, paint);
  }
}