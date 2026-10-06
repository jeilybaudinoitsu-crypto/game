import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game/estetica/color.dart';
import 'package:game/estetica/raqueta.dart';
import 'package:game/game/game_config.dart';
import 'package:game/game/pong_game.dart';
import 'package:game/personajes/conejo_animation_view.dart';
import 'package:game/personajes/conejo_player.dart';
import 'package:game/ui/game_screen.dart';
import 'package:game/ui/menu_screen.dart';

/// Tamaños representativos: movil pequeno, movil normal, tablet y apaisado.
const _screens = <String, Size>{
  'movil pequeno 360x640': Size(360, 640),
  'movil normal 420x900': Size(420, 900),
  'tablet 800x1280': Size(800, 1280),
  'apaisado 900x420': Size(900, 420),
};

/// Monta una pantalla con un tamano de pantalla concreto.
Future<void> pumpAtSize(WidgetTester tester, Size size, Widget home) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(fontFamily: CuteTheme.fontFamily),
      home: home,
    ),
  );
}

/// Devuelve la animacion del conejo que se esta mostrando.
ConejoAnimation? conejoVisible(WidgetTester tester) {
  final views = tester.widgetList<ConejoAnimationView>(
    find.byType(ConejoAnimationView),
  );
  return views.isEmpty ? null : views.first.animation;
}

/// Monta la pantalla de partida y devuelve el juego ya listo.
Future<PongGame> pumpGame(WidgetTester tester, Size size) async {
  await pumpAtSize(
    tester,
    size,
    GameScreen(
      mode: GameMode.vsAI,
      difficulty: Difficulty.medio,
      onExit: () {},
    ),
  );

  final game = tester
      .widget<GameWidget<PongGame>>(find.byType(GameWidget<PongGame>))
      .game!;
  expect(game, isNotNull, reason: 'GameWidget sin juego asignado');

  await tester.pump();
  await tester.runAsync(game.ready);
  game.debugStartPlaying();
  await tester.pump();

  return game;
}

/// Avanza el bucle del juego lo suficiente para que expire la pausa entre
/// puntos, que es cuando se comprueba si la partida ha terminado.
void advance(PongGame game, double seconds) {
  const dt = 1 / 60;
  for (var t = 0.0; t < seconds; t += dt) {
    game.update(dt);
  }
}

void main() {
  group('animacion del menu', () {
    for (final entry in _screens.entries) {
      testWidgets('el menu muestra la animacion de inicio en ${entry.key}', (
        tester,
      ) async {
        await pumpAtSize(tester, entry.value, MenuScreen(onStart: (_, _) {}));
        await tester.pump();

        expect(conejoVisible(tester), ConejoAnimation.inicio);
      });
    }
  });

  group('animacion al puntuar', () {
    testWidgets('muestra win cuando el usuario anota', (tester) async {
      final game = await pumpGame(tester, _screens['movil normal 420x900']!);

      expect(
        conejoVisible(tester),
        isNull,
        reason: 'no debe haber conejo al empezar',
      );

      game.awardPoint(PaddleSide.left);
      await tester.pump();

      expect(conejoVisible(tester), ConejoAnimation.win);
    });

    testWidgets('muestra losse cuando anota la IA', (tester) async {
      final game = await pumpGame(tester, _screens['movil normal 420x900']!);

      game.awardPoint(PaddleSide.right);
      await tester.pump();

      expect(conejoVisible(tester), ConejoAnimation.loss);
    });

    testWidgets('el conejo desaparece pasado un momento', (tester) async {
      final game = await pumpGame(tester, _screens['movil normal 420x900']!);

      game.awardPoint(PaddleSide.left);
      await tester.pump();
      expect(conejoVisible(tester), ConejoAnimation.win);

      // Se avanza mas alla de la duracion configurada (1400 ms).
      await tester.pump(const Duration(milliseconds: 2000));
      expect(conejoVisible(tester), isNull);
    });
  });

  group('animacion del panel de resultado', () {
    testWidgets('muestra win si gana el usuario', (tester) async {
      final game = await pumpGame(tester, _screens['movil normal 420x900']!);

      for (var i = 0; i < GameConfig.pointsToWin; i++) {
        game.awardPoint(PaddleSide.left);
      }
      advance(game, 2.0);
      await tester.pump();

      expect(find.text('¡Ganaste!'), findsOneWidget);
      expect(conejoVisible(tester), ConejoAnimation.win);
    });

    testWidgets('muestra losse si gana la IA', (tester) async {
      final game = await pumpGame(tester, _screens['movil normal 420x900']!);

      for (var i = 0; i < GameConfig.pointsToWin; i++) {
        game.awardPoint(PaddleSide.right);
      }
      advance(game, 2.0);
      await tester.pump();

      expect(find.text('¡Buen intento!'), findsOneWidget);
      expect(conejoVisible(tester), ConejoAnimation.loss);
    });

    testWidgets('no queda el conejo de reaction detras del panel', (
      tester,
    ) async {
      final game = await pumpGame(tester, _screens['movil normal 420x900']!);

      for (var i = 0; i < GameConfig.pointsToWin; i++) {
        game.awardPoint(PaddleSide.left);
      }
      advance(game, 2.0);
      await tester.pump();

      // El punto final dispara la reaccion, pero el panel manda: solo debe
      // verse el conejo del resultado.
      expect(
        tester.widgetList<ConejoAnimationView>(
          find.byType(ConejoAnimationView),
        ),
        hasLength(1),
      );
    });
  });
}
