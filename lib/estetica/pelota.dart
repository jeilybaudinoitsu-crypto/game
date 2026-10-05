import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class CuteBall extends CircleComponent {
  CuteBall({required Vector2 position, required double radius, required Color color})
      : super(
          position: position,
          radius: radius,
          paint: Paint()..color = color,
        );
}