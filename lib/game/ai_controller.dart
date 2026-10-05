import 'dart:math' as math;


import '../estetica/pelota.dart';
import '../estetica/raqueta.dart';
import 'game_config.dart';

/// Controlador de la IA, portado del `IAPingPong` del juego de terminal.
///
/// A diferencia de la version original (que contaba fotogramas), aqui el
/// muestreo de decisiones es por tiempo, para que la dificultad se sienta igual
/// en un movil a 60 Hz y en un navegador a 120 Hz.
class AiController {
  AiController({
    required this.difficulty,
    math.Random? random,
  }) : _random = random ?? math.Random();

  final Difficulty difficulty;
  final math.Random _random;

  double _timer = 0;

  /// Decide hacia donde moverse en este `dt` y mueve la raqueta.
  ///
  /// [fieldHeight] es la altura util de la cancha y [speed] los pixeles por
  /// segundo que puede recorrer la raqueta.
  void update({
    required CutePaddle paddle,
    required CuteBall ball,
    required double fieldHeight,
    required double speed,
    required double dt,
  }) {
    // Muestreo de reaccion: solo decide cada cierto tiempo.
    _timer += dt;
    if (_timer < difficulty.reactionInterval) return;
    _timer = 0;

    final double targetY;
    if (ball.velocity.x > 0) {
      // La pelota viene hacia la IA: predecir donde va a tocar.
      targetY = predictContactY(
        ball: ball,
        targetX: paddle.position.x,
        fieldHeight: fieldHeight,
      );
    } else {
      // La pelota se aleja: volver al centro para estar preparado.
      targetY = fieldHeight / 2;
    }

    // En nivel facil (y algo en medio) la IA falla a veces.
    var jitteredTarget = targetY;
    if (_random.nextDouble() < difficulty.mistakeChance) {
      jitteredTarget += (_random.nextDouble() - 0.5) *
          2 *
          difficulty.mistakeRange *
          fieldHeight;
    }

    final paddleCenter = paddle.position.y + paddle.size.y / 2;
    final deadzone = fieldHeight * 0.004;
    final move = speed * dt;

    if ((jitteredTarget - paddleCenter).abs() < deadzone) return;

    final direction = jitteredTarget > paddleCenter ? 1.0 : -1.0;
    paddle.moveBy(direction * move);
  }

  /// Simula la trayectoria de la pelota (con sus rebotes verticales) hasta la
  /// columna de la raqueta y devuelve la Y donde impactara.
  double predictContactY({
    required CuteBall ball,
    required double targetX,
    required double fieldHeight,
  }) {
    var x = ball.position.x;
    var y = ball.position.y;
    var vy = ball.velocity.y;
    final vx = ball.velocity.x;
    final radius = ball.size.x / 2;

    // Si la pelota ya se dirige hacia la IA, se simula hacia adelante.
    if (vx <= 0) return fieldHeight / 2;

    var steps = 0;
    final maxSteps = 512;
    while (x < targetX && steps < maxSteps) {
      x += vx;
      y += vy;

      // Mismo criterio de rebote que el bucle del juego.
      if (y < radius || y > fieldHeight - radius) {
        y = y.clamp(radius, fieldHeight - radius);
        vy = -vy;
      }
      steps++;
    }

    final noise = (_random.nextDouble() - 0.5) * difficulty.predictionJitter;
    return (y + noise * fieldHeight).clamp(radius, fieldHeight - radius);
  }
}