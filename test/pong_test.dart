import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game/estetica/color.dart';
import 'package:game/estetica/raqueta.dart';
import 'package:game/game/game_config.dart';
import 'package:game/game/keyboard_input.dart';
import 'package:game/game/pong_game.dart';

// Los eventos de teclado de Flutter exigen `physicalKey` (de tipo
// `PhysicalKeyboardKey`) y `timeStamp`, asi que se pasan los dos.
KeyDownEvent keyDown(
  PhysicalKeyboardKey physical,
  LogicalKeyboardKey logical, [
  String? character,
]) =>
    KeyDownEvent(
      physicalKey: physical,
      logicalKey: logical,
      timeStamp: Duration.zero,
      character: character,
    );

KeyUpEvent keyUp(
  PhysicalKeyboardKey physical,
  LogicalKeyboardKey logical,
) =>
    KeyUpEvent(
      physicalKey: physical,
      logicalKey: logical,
      timeStamp: Duration.zero,
    );

KeyRepeatEvent keyRepeat(
  PhysicalKeyboardKey physical,
  LogicalKeyboardKey logical,
) =>
    KeyRepeatEvent(
      physicalKey: physical,
      logicalKey: logical,
      timeStamp: Duration.zero,
    );

void main() {
  group('GameConfig', () {
    test('se gana al llegar a pointsToWin', () {
      expect(GameConfig.pointsToWin, 7);
    });

    test('cuanto mas dificil la IA, mas rapida y menos se equivoca', () {
      final facil = Difficulty.facil;
      final dificil = Difficulty.dificil;

      expect(facil.reactionInterval, greaterThan(dificil.reactionInterval));
      expect(facil.speedFactor, lessThan(dificil.speedFactor));
      expect(facil.mistakeChance, greaterThan(dificil.mistakeChance));
      expect(facil.mistakeRange, greaterThan(dificil.mistakeRange));
      expect(facil.predictionJitter, greaterThan(dificil.predictionJitter));
    });

    test('las tres dificultades tienen etiqueta en espanol', () {
      for (final d in Difficulty.values) {
        expect(d.label, isNotEmpty);
      }
    });
  });

  group('CutePaddle', () {
    late CutePaddle paddle;

    setUp(() {
      paddle = CutePaddle(
        position: Vector2(10, 100),
        size: Vector2(18, 110),
        color: CuteTheme.player1,
        side: PaddleSide.left,
      )..boundsHeight = 400;
    });

    test('se mantiene dentro del campo', () {
      paddle.position.y = 900;
      paddle.clampToBounds();
      expect(paddle.position.y, 400 - paddle.size.y);

      paddle.position.y = -50;
      paddle.clampToBounds();
      expect(paddle.position.y, 0);
    });

    test('moveBy aplica el desplazamiento y luego acota', () {
      paddle.position.y = 100;
      paddle.moveBy(30);
      expect(paddle.position.y, 130);

      // No puede salirse por abajo, aunque el delta sea enorme.
      paddle.moveBy(10_000);
      expect(paddle.position.y, 400 - paddle.size.y);
    });

    test('un campo mas pequeno que la raqueta la deja arriba del todo', () {
      paddle.boundsHeight = 20;
      paddle.position.y = 15;
      paddle.clampToBounds();
      expect(paddle.position.y, 0);
    });

    test('el area tactil es mas ancha que el dibujo', () {
      // Slop por debajo y por encima del ancho real de la raqueta.
      expect(paddle.containsLocalPoint(Vector2(8, 20)), isTrue);
      expect(paddle.containsLocalPoint(Vector2(10, 40)), isTrue);
    });
  });

  group('KeyboardInput', () {
    late KeyboardInput input;

    setUp(() {
      input = KeyboardInput();
      input.onMount();
    });

    void press(KeyEvent event) => input.onKeyEvent(event, {event.logicalKey});

    test('W activa subir del jugador 1 y S bajar', () {
      press(keyDown(PhysicalKeyboardKey.keyW, LogicalKeyboardKey.keyW));
      expect(input.isHeld(MoveAction.player1Up), isTrue);
      expect(input.isHeld(MoveAction.player2Up), isFalse);

      press(keyUp(PhysicalKeyboardKey.keyW, LogicalKeyboardKey.keyW));
      expect(input.isHeld(MoveAction.player1Up), isFalse);

      press(keyDown(PhysicalKeyboardKey.keyS, LogicalKeyboardKey.keyS));
      expect(input.isHeld(MoveAction.player1Down), isTrue);
    });

    test('el caracter W tambien sirve, por si llega el caracter', () {
      press(keyDown(PhysicalKeyboardKey.keyW, LogicalKeyboardKey.keyW, 'w'));
      expect(input.isHeld(MoveAction.player1Up), isTrue);
    });

    test('las flechas logicas controlan al jugador 2', () {
      press(keyDown(PhysicalKeyboardKey.arrowDown, LogicalKeyboardKey.arrowDown));
      expect(input.isHeld(MoveAction.player2Down), isTrue);
      expect(input.isHeld(MoveAction.player1Down), isFalse);

      press(keyDown(PhysicalKeyboardKey.arrowUp, LogicalKeyboardKey.arrowUp));
      expect(input.isHeld(MoveAction.player2Up), isTrue);
    });

    test('las secuencias ANSI controlan al jugador 2', () {
      // '\x1b[A' arriba y '\x1b[B' abajo.
      press(keyDown(PhysicalKeyboardKey.arrowUp, LogicalKeyboardKey.arrowUp, '\x1b[A'));
      expect(input.isHeld(MoveAction.player2Up), isTrue);

      press(keyUp(PhysicalKeyboardKey.arrowUp, LogicalKeyboardKey.arrowUp));
      press(keyDown(PhysicalKeyboardKey.arrowDown, LogicalKeyboardKey.arrowDown, '\x1b[B'));
      expect(input.isHeld(MoveAction.player2Down), isTrue);
    });

    test('el numpad tambien mueve al jugador 2', () {
      press(keyDown(PhysicalKeyboardKey.numpad8, LogicalKeyboardKey.numpad8));
      expect(input.isHeld(MoveAction.player2Up), isTrue);

      press(keyUp(PhysicalKeyboardKey.numpad8, LogicalKeyboardKey.numpad8));
      press(keyDown(PhysicalKeyboardKey.numpad2, LogicalKeyboardKey.numpad2));
      expect(input.isHeld(MoveAction.player2Down), isTrue);
    });

    test('la repeticion de tecla mantiene la accion pulsada', () {
      press(keyDown(PhysicalKeyboardKey.keyS, LogicalKeyboardKey.keyS));
      press(keyRepeat(PhysicalKeyboardKey.keyS, LogicalKeyboardKey.keyS));

      expect(input.isHeld(MoveAction.player1Down), isTrue);
    });

    test('una tecla no relacionada no se consume', () {
      final handled = input.onKeyEvent(
        keyDown(PhysicalKeyboardKey.keyQ, LogicalKeyboardKey.keyQ),
        const {},
      );

      expect(handled, isFalse);
      expect(input.active, isEmpty);
    });

    test('redimensionar la partida suelta las teclas pulsadas', () {
      press(keyDown(PhysicalKeyboardKey.keyW, LogicalKeyboardKey.keyW));
      expect(input.isHeld(MoveAction.player1Up), isTrue);

      input.onGameResize(Vector2(320, 480));
      expect(input.active, isEmpty);
    });
  });

  group('PongGame', () {
    // Atajos para simular una tecla mantenida y soltada.
    void pressKey(KeyboardInput input, PhysicalKeyboardKey p, LogicalKeyboardKey l) =>
        input.onKeyEvent(keyDown(p, l), {l});

    void releaseKey(KeyboardInput input, PhysicalKeyboardKey p, LogicalKeyboardKey l) =>
        input.onKeyEvent(keyUp(p, l), {l});

    // Registro del ultimo resultado emitido por el juego.
    GameResult? onGameOverSpy;

    // `flame_test` monta el juego en un `GameWidget`, de modo que el viewport
    // tiene un tamano real y `game.size` ya funciona.
    GameTester<PongGame> testerFor({Difficulty? difficulty, GameMode? mode}) =>
        FlameTester<PongGame>(
          () => PongGame(
            mode: mode ?? GameMode.vsAI,
            difficulty: difficulty ?? Difficulty.medio,
          ),
          gameSize: Vector2(800, 600),
        );

    GameTester<PongGame> withSpy(GameResult Function(GameResult) capture) =>
        FlameTester<PongGame>(
          () => PongGame(
            mode: GameMode.vsAI,
            difficulty: Difficulty.medio,
            onGameOver: capture,
          ),
          gameSize: Vector2(800, 600),
        );

    testerFor(difficulty: Difficulty.facil).testGameWidget(
      'empieza en la cuenta atras y con el marcador a cero',
      verify: (game, tester) async {
        await tester.runAsync(game.ready);
        expect(game.currentScore.player1, 0);
        expect(game.currentScore.player2, 0);
        expect(game.currentPhase, MatchPhase.countdown);

        // Durante el aviso la pelota esta quieta en el centro.
        expect(game.ball.velocity, Vector2.zero());
        expect(game.ball.position, Vector2(400, 300));
      },
    );

    testerFor().testGameWidget(
      'la cuenta atras termina y la pelota sale en horizontal',
      verify: (game, tester) async {
        await tester.runAsync(game.ready);
        game.update(GameConfig.countdownSeconds + 0.1);
        expect(game.currentPhase, MatchPhase.playing);

        game.update(1 / 60);
        expect(game.ball.velocity.x.abs(), greaterThan(0));
      },
    );

    testerFor().testGameWidget(
      'resetMatch devuelve el marcador a cero',
      verify: (game, tester) async {
        await tester.runAsync(game.ready);
        game.score
          ..player1 = 5
          ..player2 = 6;
        game.resetMatch();

        expect(game.currentScore.player1, 0);
        expect(game.currentScore.player2, 0);
        expect(game.currentPhase, MatchPhase.countdown);
      },
    );

    testerFor().testGameWidget(
      'el jugador 1 controla su raqueta con el teclado',
      verify: (game, tester) async {
        await tester.runAsync(game.ready);
        game.update(GameConfig.countdownSeconds + 0.1);

        final paddle = game.player1Paddle;
        final before = paddle.position.y;

        pressKey(game.input, PhysicalKeyboardKey.keyS, LogicalKeyboardKey.keyS);
        game.update(0.2);

        expect(paddle.position.y, greaterThan(before));

        releaseKey(game.input, PhysicalKeyboardKey.keyS, LogicalKeyboardKey.keyS);
      },
    );

    testerFor(difficulty: Difficulty.facil).testGameWidget(
      'la IA vuelve al centro cuando la pelota se aleja',
      verify: (game, tester) async {
        await tester.runAsync(game.ready);
        game.update(GameConfig.countdownSeconds + 0.1);

        final paddle = game.player2Paddle;

        // Se la coloca en una esquina: el saque va hacia el jugador 1, asi que
        // la IA debe Recolocarse sola.
        paddle.position.y = 0;

        game.update(0.6);
        expect(paddle.position.y, greaterThan(0));
      },
    );

    testerFor(difficulty: Difficulty.dificil).testGameWidget(
      'la IA persigue la pelota que se acerca',
      verify: (game, tester) async {
        await tester.runAsync(game.ready);
        game.update(GameConfig.countdownSeconds + 0.1);

        final paddle = game.player2Paddle;

        // Pelota dirijida a la IA y muy arriba: la raqueta debe bajar a por ella.
        game.ball
          ..position = Vector2(300, 80)
          ..velocity = Vector2(400, 0);
        paddle.position.y = 400;

        game.update(0.3);
        expect(paddle.position.y, lessThan(400));
      },
    );

    withSpy((r) => onGameOverSpy = r).testGameWidget(
      'se avisa a la UI cuando el jugador 1 gana',
      verify: (game, tester) async {
        await tester.runAsync(game.ready);
        game.update(GameConfig.countdownSeconds + 0.1);

        game.score
          ..player1 = GameConfig.pointsToWin - 1
          ..player2 = 3;
        game.awardPoint(PaddleSide.left);
        expect(game.currentPhase, MatchPhase.pointScored);

        // El panel del punto dura 1.6 s antes de cerrar la partida.
        game.update(2.0);

        expect(onGameOverSpy, isNotNull);
        expect(onGameOverSpy!.player1Won, isTrue);
        expect(onGameOverSpy!.player1Score, GameConfig.pointsToWin);
        expect(game.currentPhase, MatchPhase.finished);
      },
    );

    withSpy((r) => onGameOverSpy = r).testGameWidget(
      'el resultado solo se emite una vez',
      verify: (game, tester) async {
        await tester.runAsync(game.ready);
        game.update(GameConfig.countdownSeconds + 0.1);

        game.score
          ..player1 = GameConfig.pointsToWin - 1
          ..player2 = 0;
        game.awardPoint(PaddleSide.left);
        game.update(2.0);

        final first = onGameOverSpy;
        game.update(1.0);
        expect(onGameOverSpy, same(first));
      },
    );

    testerFor(mode: GameMode.vsFriend).testGameWidget(
      'contra un amigo no hay IA: la raqueta 2 espera al teclado',
      verify: (game, tester) async {
        await tester.runAsync(game.ready);
        game.update(GameConfig.countdownSeconds + 0.1);

        final paddle = game.player2Paddle;
        final before = paddle.position.y;

        game.update(0.5);
        expect(paddle.position.y, equals(before));

        pressKey(game.input, PhysicalKeyboardKey.arrowUp, LogicalKeyboardKey.arrowUp);
        game.update(0.2);
        expect(paddle.position.y, lessThan(before));
      },
    );

    testerFor().testGameWidget(
      'redimensionar deja las raquetas dentro del campo',
      verify: (game, tester) async {
        await tester.runAsync(game.ready);
        await tester.pumpWidget(
          GameWidget<PongGame>(game: game),
        );
        await tester.pump();

        game.onGameResize(Vector2(400, 800));

        for (final paddle in [game.player1Paddle, game.player2Paddle]) {
          expect(paddle.position.y, greaterThanOrEqualTo(0));
          expect(paddle.position.y + paddle.size.y, lessThanOrEqualTo(800));
        }
      },
    );
  });
}
