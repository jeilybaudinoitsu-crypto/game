import 'package:flame/extensions.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game/estetica/raqueta.dart';
import 'package:game/game/game_config.dart';
import 'package:game/game/pong_game.dart';
import 'package:game/mascota/conejo_mascota.dart';
import 'package:game/ui/widgets/score_board.dart';

/// Regresiones de los bugs reportados en partida.
void main() {
  GameTester<PongGame> testerFor({
    GameMode mode = GameMode.vsFriend,
    ValueChanged<Score>? onScoreChanged,
  }) =>
      FlameTester<PongGame>(
        () => PongGame(
          mode: mode,
          difficulty: Difficulty.medio,
          sprites: BunnySprites.empty(),
          onScoreChanged: onScoreChanged,
        ),
        gameSize: Vector2(800, 600),
      );

  group('bug 2: la pelota no atraviesa la raqueta', () {
    testerFor().testGameWidget(
      'la pelota rebota y sale hacia el otro lado',
      verify: (game, tester) async {
      await tester.runAsync(game.ready);
      game.debugStartPlaying(direction: 1);

      // Se encadena el manejador original: si se sustituye, la pelota rebota
      // pero nadie aplica la fisica del rebote.
      var rebotes = 0;
      final original = game.ball.onHitPaddle!;
      game.ball.onHitPaddle = (paddle) {
        rebotes++;
        original(paddle);
      };

      // Trayectoria horizontal a la altura exacta de la raqueta 2, que se
      // queda quieta: si la deteccion falla la pelota se escapa por la derecha.
      game.ball
        ..position.y = game.player2Paddle.position.y +
            game.player2Paddle.size.y / 2
        ..velocity = Vector2(game.ball.velocity.length, 0);

      const dt = 1 / 60;
      for (var i = 0; i < 180 && rebotes == 0; i++) {
        game.update(dt);
      }

      expect(rebotes, greaterThan(0),
          reason: 'la pelota debe rebotar al llegar a la raqueta');
      expect(game.ball.velocity.x, lessThan(0),
          reason: 'tras rebotar en la raqueta derecha vuelve hacia la izquierda');
    });

    testerFor().testGameWidget(
      'el rebote no deja la pelota dentro de la raqueta',
      verify: (game, tester) async {
      await tester.runAsync(game.ready);
      game.debugStartPlaying(direction: 1);
      game.ball
        ..position.y = game.player2Paddle.position.y +
            game.player2Paddle.size.y / 2
        ..velocity = Vector2(game.ball.velocity.length, 0);

      const dt = 1 / 60;
      for (var i = 0; i < 60; i++) {
        game.update(dt);
      }

      // La pelota nunca puede quedar a la derecha del borde de la raqueta 2.
      final bordePaddle = game.player2Paddle.position.x;
      expect(game.ball.position.x, lessThan(bordePaddle + 1));
    });
  });

  group('bug 3: el marcador refleja quien fallo', () {
    testerFor().testGameWidget(
      'si la pelota sale por la izquierda puntua el jugador 2',
      verify: (game, tester) async {
      await tester.runAsync(game.ready);
      game.debugStartPlaying(direction: 1);

      // Se saca la pelota al borde izquierdo, detras de la raqueta 1.
      // El centro de la pelota tiene que quedar fuera del borde: la regla es
      // `posicion + radio < 0`.
      final r = game.ball.size.x / 2;
      game.ball
        ..position = Vector2(-r - 1, game.size.y / 2)
        ..velocity = Vector2(-400, 0);

      game.update(1 / 60);

      expect(game.currentScore.player1, 0,
          reason: 'el jugador 1 fallo, no debe puntuar');
      expect(game.currentScore.player2, 1,
          reason: 'el punto es del jugador 2, el que no fallo');
    });

    testerFor().testGameWidget(
      'si la pelota sale por la derecha puntua el jugador 1',
      verify: (game, tester) async {
      await tester.runAsync(game.ready);
      game.debugStartPlaying(direction: -1);

      final r = game.ball.size.x / 2;
      game.ball
        ..position = Vector2(game.size.x + r + 1, game.size.y / 2)
        ..velocity = Vector2(400, 0);

      game.update(1 / 60);

      expect(game.currentScore.player2, 0,
          reason: 'el jugador 2 fallo, no debe puntuar');
      expect(game.currentScore.player1, 1,
          reason: 'el punto es del jugador 1, el que no fallo');
    });

    testerFor().testGameWidget(
      'el resultado no siempre es 7-6',
      verify: (game, tester) async {
      await tester.runAsync(game.ready);

      // El jugador 2 gana 7 y el 1 no puntua: el resultado tiene que ser 7-0,
      // no el 7-6 que salia siempre antes.
      game.debugStartPlaying(direction: 1);
      final r = game.ball.size.x / 2;
      for (var i = 0; i < 7; i++) {
        game.ball
          ..position = Vector2(-r - 1, game.size.y / 2)
          ..velocity = Vector2(-400, 0);
        game.update(1 / 60);
        // Deja terminar el panel del punto.
        game.update(2.0);
      }

      expect(game.currentScore.player2, GameConfig.pointsToWin);
      expect(game.currentScore.player1, 0,
          reason: 'el jugador 1 nunca fallo, no debe tener puntos');
    });
  });

  group('bug 1: la UI refleja el marcador', () {
    Score? ultimo;
    var avisos = 0;

    testerFor(onScoreChanged: (score) {
      ultimo = score;
      avisos++;
    }).testGameWidget(
      'el HUD se actualiza cuando cambia el marcador',
      verify: (game, tester) async {
        await tester.runAsync(game.ready);

        expect(avisos, 0, reason: 'sin puntos no hay avisos');

        game.awardPoint(PaddleSide.right);
        expect(avisos, 1);
        expect(ultimo!.player2, 1);
        expect(ultimo!.player1, 0);

        game.awardPoint(PaddleSide.left);
        expect(avisos, 2);
        expect(ultimo!.player1, 1);
        expect(ultimo!.player2, 1);
      },
    );
  });

  group('el marcador cabe en pantallas pequenas', () {
    testWidgets('no desborda con el ancho minimo', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ScoreBoard(
                player1Score: 7,
                player2Score: 6,
                pointsToWin: 7,
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}