import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
@override
Color backgroundColor() => CuteTheme.background;
// Definición de los modos de juego
enum GameMode { vsAI, vsPlayer }

class PongGame extends FlameGame with HasKeyboardHandlerComponents, HasCollisionDetection {
  final GameMode gameMode;

  PongGame({required this.gameMode});

  @override
  Color backgroundColor() => const Color(0xFF000000); // Fondo negro estilo arcade

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Aquí agregaremos la pelota, las raquetas y la puntuación
  }
} 