import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../estetica/color.dart';
import '../estetica/extra.dart';
import '../estetica/pelota.dart';
import '../estetica/raqueta.dart';
import '../mascota/conejo_mascota.dart';
import 'ai_controller.dart';
import 'game_config.dart';
import 'keyboard_input.dart';

/// Marcador de la partida.
class Score {
  int player1 = 0;
  int player2 = 0;

  void reset() {
    player1 = 0;
    player2 = 0;
  }
}

/// Resultado al terminar la partida.
class GameResult {
  const GameResult({
    required this.player1Won,
    required this.player1Score,
    required this.player2Score,
  });

  final bool player1Won;
  final int player1Score;
  final int player2Score;
}

/// Estados de la partida.
enum MatchPhase {
  /// Aviso "Preparados" con el conejo calentandose.
  countdown,

  /// Pelota en juego.
  playing,

  /// Punto anotado: pausa breve antes de sacar de nuevo.
  pointScored,

  /// Partida terminada.
  finished,
}

/// Juego de Pin Pon con estetica pastel.
///
/// Controles:
/// - Android/iOS: arrastrar la raqueta con el dedo ([DragCallbacks]).
/// - Web / escritorio: jugador 1 con `W`/`S`, jugador 2 con las flechas
///   (`\x1b[A` arriba, `\x1b[B` abajo).
class PongGame extends FlameGame
    with HasCollisionDetection, HasKeyboardHandlerComponents {
  PongGame({
    required this.mode,
    required this.sprites,
    this.difficulty = Difficulty.medio,
    this.onGameOver,
    this.onScoreChanged,
  });

  /// Modo elegido en el menu.
  final GameMode mode;

  /// Sprites de la mascota conejo.
  final BunnySprites sprites;

  /// Dificultad de la IA (solo en [GameMode.vsAI]).
  final Difficulty difficulty;

  /// Se invoca una sola vez cuando alguien gana.
  final ValueChanged<GameResult>? onGameOver;

  /// Se invoca cada vez que el marcador cambia, para que el HUD se refresque.
  final ValueChanged<Score>? onScoreChanged;

  final Score score = Score();
  final math.Random _random = math.Random();

  late final KeyboardInput _input;
  late final AiController _ai;
  late final CuteBall _ball;
  late final CutePaddle _paddle1;
  late final CutePaddle _paddle2;
  late final PastelBackdrop _backdrop;
  late final BunnyMascot _mascot;

  MatchPhase phase = MatchPhase.countdown;
  double _phaseTimer = 0;
  double _baseBallSpeed = 0;
  double _paddleSpeed = 0;
  bool _resultSent = false;

  /// Ultimo lado que scored (para orientar al conejo y decidir el saque).
  PaddleSide? _lastScorer;

  /// `true` cuando [onLoad] ya creo la cancha. El primer `onGameResize` puede
  /// llegar antes, y entonces no hay componentes todavia que ajustar.
  bool _sceneBuilt = false;

  CuteBall get ball => _ball;
  Score get currentScore => score;
  MatchPhase get currentPhase => phase;

  /// Estado del teclado. Expuesto para poder simular pulsaciones.
  KeyboardInput get input => _input;

  /// Raqueta del jugador 1 (lado izquierdo).
  CutePaddle get player1Paddle => _paddle1;

  /// Raqueta del jugador 2 o de la IA (lado derecho).
  CutePaddle get player2Paddle => _paddle2;

  /// Anota un punto a favor de [scorer] y reinicia la pelota.
  ///
  /// Es publico para poder ejecutar la puntuacion desde las pruebas.
  void awardPoint(PaddleSide scorer) => _scorePoint(scorer);

  /// Salta la cuenta atras y saca la pelota hacia [direction].
  ///
  /// Solo para pruebas: evita tener que simular los 3 s del aviso.
  @visibleForTesting
  void debugStartPlaying({int direction = 1}) {
    phase = MatchPhase.playing;
    _serve(direction: direction);
  }

  @override
  Color backgroundColor() => CuteTheme.background;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _paddleSpeed = size.y * GameConfig.paddleSpeedRatio;
    _baseBallSpeed = size.y * GameConfig.ballSpeedRatio;

    _backdrop = PastelBackdrop(position: Vector2.zero(), size: size);
    await add(_backdrop);

    // Red central.
    await add(
      CuteNet(
        position: Vector2(size.x / 2 - 4, 0),
        courtHeight: size.y,
      ),
    );

    // Marco de la cancha.
    await add(CourtFrame(position: Vector2.zero(), size: size));

    // Mascota: arriba, entre las dos zonas de juego.
    _mascot = BunnyMascot(
      position: Vector2(size.x / 2, size.y * 0.10),
      sprites: sprites,
      spriteHeight: _mascotHeightFor(size),
      anchor: Anchor.center,
    );
    await add(_mascot);

    final paddleSize = _paddleSizeFor(size.y);
    final margin = size.x * GameConfig.paddleMarginRatio;

    _paddle1 = CutePaddle(
      position: Vector2(margin, (size.y - paddleSize.y) / 2),
      size: paddleSize,
      color: CuteTheme.player1,
      side: PaddleSide.left,
      anchor: Anchor.topLeft,
    )..boundsHeight = size.y;

    _paddle2 = CutePaddle(
      position: Vector2(size.x - margin - paddleSize.x, (size.y - paddleSize.y) / 2),
      size: paddleSize,
      color: CuteTheme.player2,
      side: PaddleSide.right,
      anchor: Anchor.topLeft,
    )..boundsHeight = size.y;

    await addAll([_paddle1, _paddle2]);

    final radius = _ballRadiusFor(size.y);
    _ball = CuteBall(
      position: Vector2(size.x / 2, size.y / 2),
      radius: radius,
    )..onHitPaddle = _onPaddleHit;
    await add(_ball);

    _input = KeyboardInput();
    await add(_input);

    _ai = AiController(difficulty: difficulty);

    _startCountdown();

    // A partir de aqui la cancha existe y los redimensionados ya pueden
    // ajustar sus medidas.
    _sceneBuilt = true;
  }

  /// Alto de la mascota en funcion del tamano de la cancha.
  static double _mascotHeightFor(Vector2 field) =>
      math.min(field.y * 0.15, math.min(field.x * 0.16, 108.0));

  Vector2 _paddleSizeFor(double fieldHeight) {
    final h = math.min(
      math.max(
        fieldHeight * GameConfig.paddleHeightRatio,
        GameConfig.paddleMinHeight,
      ),
      GameConfig.paddleMaxHeight,
    );
    return Vector2(h * GameConfig.paddleWidthRatio, h);
  }

  double _ballRadiusFor(double fieldHeight) => math.min(
        math.max(
          fieldHeight * GameConfig.ballRadiusRatio,
          GameConfig.ballMinRadius,
        ),
        GameConfig.ballMaxRadius,
      );

  @override
  void onGameResize(Vector2 size) {
    // `size` (el parametro) es el nuevo tamano; `this.size` el anterior.
    // En el primer resize todavia no hay layout, asi que se trata como 0 y no
    // hay escalado (`hasLayout` evita que `this.size` lance una asercion).
    final oldHeight = hasLayout ? this.size.y : 0.0;

    super.onGameResize(size);

    // Todavia no se han creado la cancha ni la pelota: `onLoad` usara este
    // mismo tamano, asi que no hay nada que reescalar todavia.
    if (!_sceneBuilt) return;

    _paddleSpeed = size.y * GameConfig.paddleSpeedRatio;
    _baseBallSpeed = size.y * GameConfig.ballSpeedRatio;

    final scaleY = oldHeight > 0 ? size.y / oldHeight : 1.0;

    _backdrop
      ..position = Vector2.zero()
      ..size = size.clone();

    // Mantiene las raquetas dentro del campo tras el redimensionado.
    final paddleSize = _paddleSizeFor(size.y);
    final margin = size.x * GameConfig.paddleMarginRatio;

    for (final paddle in [_paddle1, _paddle2]) {
      paddle
        ..boundsHeight = size.y
        ..size = paddleSize.clone()
        ..position.y = (paddle.position.y * scaleY)
            .clamp(0.0, math.max(0.0, size.y - paddleSize.y))
        ..clampToBounds()
        ..syncHitbox();
    }

    _paddle1.position.x = margin;
    _paddle2.position.x = size.x - margin - paddleSize.x;

    final mascotHeight = _mascotHeightFor(size);
    _mascot
      ..position = Vector2(size.x / 2, size.y * 0.10)
      ..size = Vector2(mascotHeight * 1.6, mascotHeight);

    _ball.position = Vector2(size.x / 2, size.y / 2);
    _ball.resetTrail();
  }

  void _startCountdown() {
    phase = MatchPhase.countdown;
    _phaseTimer = GameConfig.countdownSeconds;
    _holdBallInCenter();
    _mascot
      ..play(BunnyPose.warmup, returnToIdle: false)
      ..say('¡Prepárense!');
  }

  /// Congela la pelota en el centro durante el aviso y entre puntos.
  void _holdBallInCenter() {
    _ball
      ..position = Vector2(size.x / 2, size.y / 2)
      ..velocity = Vector2.zero()
      ..resetTrail();
  }

  /// Coloca la pelota en el centro y la lanza hacia [direction]
  /// (`1` hacia la derecha / jugador 2, `-1` hacia la izquierda).
  void _serve({required int direction}) {
    _holdBallInCenter();

    // Angulo inicial aleatorio para que las partidas no sean identicas.
    final angle = _random.nextDouble() * 0.7 - 0.35;
    final v = Vector2(math.cos(angle), math.sin(angle))
        .normalized()
        .scaled(_baseBallSpeed * direction);
    _ball.velocity = v;
  }

  @override
  void update(double dt) {
    // El juego puede recibir updates mientras `onLoad` aun no ha terminado
    // (el widget ya esta montado pero la escena no). Sin este margen, se
    // tocarian campos `late` todavia sin inicializar.
    if (!_sceneBuilt) return;

    super.update(dt);

    // `super.update` ya movio la pelota y resolvio las colisiones.
    _updatePhase(dt);

    if (phase == MatchPhase.playing) {
      _updatePaddles(dt);
      _bounceOffWalls();
      _checkScore();
    }
  }

  void _updatePhase(double dt) {
    if (phase == MatchPhase.countdown) {
      _phaseTimer -= dt;
      if (_phaseTimer <= 0) {
        phase = MatchPhase.playing;
        _mascot
          ..play(BunnyPose.idle)
          ..hideMessage();
        // Al terminar el aviso hay que sacar: sin esto la pelota se queda
        // congelada en el centro y la partida nunca arranca.
        _serve(direction: _lastScorer == PaddleSide.left ? 1 : -1);
      }
      return;
    }

    if (phase == MatchPhase.pointScored) {
      _phaseTimer -= dt;
      if (_phaseTimer <= 0) {
        if (score.player1 >= GameConfig.pointsToWin ||
            score.player2 >= GameConfig.pointsToWin) {
          _finish();
        } else {
          phase = MatchPhase.playing;
          _mascot
            ..play(BunnyPose.idle)
            ..hideMessage();
          // Saca hacia el lado del ultimo que scored.
          _serve(direction: _lastScorer == PaddleSide.left ? 1 : -1);
        }
      }
    }
  }

  void _updatePaddles(double dt) {
    final move = _paddleSpeed * dt;

    // Jugador 1: teclado (W / S).
    if (_input.isHeld(MoveAction.player1Up)) _paddle1.moveBy(-move);
    if (_input.isHeld(MoveAction.player1Down)) _paddle1.moveBy(move);

    if (mode == GameMode.vsFriend) {
      // Jugador 2: flechas del teclado (secuencia ANSI \x1b[A / \x1b[B).
      if (_input.isHeld(MoveAction.player2Up)) _paddle2.moveBy(-move);
      if (_input.isHeld(MoveAction.player2Down)) _paddle2.moveBy(move);
    } else {
      // En contra IA la segunda raqueta la lleva el controlador.
      _ai.update(
        paddle: _paddle2,
        ball: _ball,
        fieldHeight: size.y,
        speed: _paddleSpeed * difficulty.speedFactor,
        dt: dt,
      );
    }

    _paddle1.clampToBounds();
    _paddle2.clampToBounds();
  }

  /// Rebotes de la pelota contra el borde superior e inferior.
  void _bounceOffWalls() {
    final r = _ball.size.x / 2;
    final pos = _ball.position;
    final vel = _ball.velocity;

    if (pos.y - r <= 0 && vel.y < 0) {
      pos.y = r;
      vel.y = -vel.y;
    } else if (pos.y + r >= size.y && vel.y > 0) {
      pos.y = size.y - r;
      vel.y = -vel.y;
    }
  }

  /// Detecta el punto cuando la pelota cruza detras de una raqueta.
  ///
  /// El punto es para el jugador **contrario** al que dejo pasar la pelota:
  /// si se escapa por la izquierda fallo el jugador 1 y puntua el 2, y al
  /// reves si se escapa por la derecha fallo el jugador 2 y puntua el 1.
  void _checkScore() {
    final r = _ball.size.x / 2;

    if (_ball.position.x + r < 0) {
      _scorePoint(PaddleSide.right);
    } else if (_ball.position.x - r > size.x) {
      _scorePoint(PaddleSide.left);
    }
  }

  // --- Colisiones ----------------------------------------------------------

  void _onPaddleHit(CutePaddle paddle) {
    final r = _ball.size.x / 2;
    final vel = _ball.velocity;

    // Separa la pelota de la raqueta para evitar colisiones repetidas.
    if (paddle.side == PaddleSide.left) {
      _ball.position.x = paddle.position.x + paddle.size.x + r + 0.5;
    } else {
      _ball.position.x = paddle.position.x - r - 0.5;
    }

    // Donde golpeo respecto al centro de la raqueta, de -1 a 1.
    final paddleCenter = paddle.position.y + paddle.size.y / 2;
    final offset = ((_ball.position.y - paddleCenter) / (paddle.size.y / 2))
        .clamp(-1.0, 1.0);

    // El "sweet spot" devuelve el angulo hacia el centro.
    final isSweet = offset.abs() <= GameConfig.sweetSpotRatio;
    final effective = isSweet ? offset * 0.35 : offset;
    final angle = effective * GameConfig.maxBounceAngle;

    final speed = math.min(
      vel.length * GameConfig.ballSpeedUp,
      _baseBallSpeed * GameConfig.ballMaxSpeedUp,
    );

    // La direccion horizontal la fija el lado de la raqueta golpeada.
    final horizontalSign = paddle.side == PaddleSide.left ? 1.0 : -1.0;
    _ball.velocity = Vector2(
      math.cos(angle).abs() * horizontalSign,
      math.sin(angle),
    ).normalized().scaled(speed);

    paddle.flash();
    _mascot.play(BunnyPose.hit);
  }

  /// Registra un punto para [scorer].
  void _scorePoint(PaddleSide scorer) {
    if (scorer == PaddleSide.left) {
      score.player1++;
    } else {
      score.player2++;
    }

    onScoreChanged?.call(score);

    _lastScorer = scorer;
    phase = MatchPhase.pointScored;
    _phaseTimer = 1.6;

    _holdBallInCenter();

    // El conejo da el marcador: anuncia el punto y lo celebra.
    final total = score.player1 + score.player2;
    _mascot
      ..facingRight = scorer == PaddleSide.left
      ..play(BunnyPose.run)
      ..say('+1  ·  $total en total');
  }

  void _finish() {
    phase = MatchPhase.finished;

    final player1Won = score.player1 >= GameConfig.pointsToWin;
    _mascot.play(
      player1Won ? BunnyPose.win : BunnyPose.lose,
      returnToIdle: false,
    );
    _mascot.say(
      player1Won ? '¡Ganaste!' : '¡Buen intento!',
      seconds: 4,
    );

    if (!_resultSent) {
      _resultSent = true;
      onGameOver?.call(
        GameResult(
          player1Won: player1Won,
          player1Score: score.player1,
          player2Score: score.player2,
        ),
      );
    }
  }

  /// Reinicia el marcador y vuelve a la fase de aviso.
  void resetMatch() {
    score.reset();
    _resultSent = false;
    _lastScorer = null;
    _mascot.hideMessage();
    _startCountdown();
  }
}