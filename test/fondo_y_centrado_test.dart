import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game/estetica/color.dart';
import 'package:game/game/game_config.dart';
import 'package:game/game/pong_game.dart';
import 'package:game/personajes/conejo_animation_view.dart';
import 'package:game/personajes/conejo_player.dart';
import 'package:game/ui/game_screen.dart';

/// `find.byType(GameWidget)` no encuentra nada: el tipo concreto es
/// `GameWidget<_ConejoStageGame>` o `GameWidget<PongGame>`.
Finder _canvas() => find.byWidgetPredicate((w) => w is GameWidget);

/// Extrae el juego que hay dentro del `GameWidget` que se esta pintando.
FlameGame _juego(WidgetTester tester) {
  final widget = tester.widget(_canvas());
  return (widget as dynamic).game as FlameGame;
}

/// Espera a que el juego termine de cargar las imagenes.
Future<void> _listo(WidgetTester tester) async {
  await tester.runAsync<void>(() => _juego(tester).ready());
  await tester.pump();
}

/// Busca el conejo dentro del juego minimo.
ConejoPlayer _conejo(FlameGame game) =>
    game.world.children.query().whereType<ConejoPlayer>().single;

/// Rectangulo que ocupa el conejo dibujado dentro del lienzo.
///
/// `PositionComponent.x`/`y` son el centro cuando el anclaje es
/// `Anchor.center`, asi que el rectangulo hay que calcularlo a partir del
/// centro y del tamano.
Rect _recto(ConejoPlayer conejo) => Rect.fromCenter(
  center: Offset(conejo.position.x, conejo.position.y),
  width: conejo.size.x,
  height: conejo.size.y,
);

void main() {
  group('el fondo de Flame es transparente', () {
    test('PongGame no pinta fondo opaco', () {
      final game = PongGame(
        mode: GameMode.vsAI,
        difficulty: Difficulty.medio,
      );

      // Sin esto se ve el rectangulo negro que Flame pone por defecto.
      expect(game.backgroundColor().a, 0.0);
    });

    testWidgets('el juego de la partida declara fondo transparente', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            mode: GameMode.vsAI,
            difficulty: Difficulty.medio,
            onExit: () {},
          ),
        ),
      );

      final game = _juego(tester);
      expect(game, isA<PongGame>());
      expect(game.backgroundColor().a, 0.0);
    });

    testWidgets('el GameWidget de la partida no pinta fondo', (tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            mode: GameMode.vsAI,
            difficulty: Difficulty.medio,
            onExit: () {},
          ),
        ),
      );

      // `backgroundBuilder` pinta detras del canvas. Con `SizedBox.shrink()`
      // no se anade ninguna superficie opaca.
      final builder =
          (tester.widget(_canvas()) as dynamic).backgroundBuilder
              as WidgetBuilder?;
      expect(builder, isNotNull);

      final fondo = builder!(tester.element(find.byType(GameScreen)));
      expect(fondo, isA<SizedBox>());
      final caja = fondo as SizedBox;
      expect(caja.width ?? 0, 0);
      expect(caja.height ?? 0, 0);
    });

    testWidgets('detras de la partida se ve el degradado pastel', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            mode: GameMode.vsAI,
            difficulty: Difficulty.medio,
            onExit: () {},
          ),
        ),
      );

      final degradados = tester
          .widgetList<Container>(find.byType(Container))
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .where((d) => d.gradient == CuteTheme.backdrop)
          .toList();

      expect(degradados, isNotEmpty, reason: 'la partida no tiene degradado');
    });
  });

  group('el conejo queda centrado y con margen', () {
    Future<FlameGame> monta(WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: const SizedBox(
            width: 400,
            height: 400,
            child: ConejoAnimationView(
              animation: ConejoAnimation.inicio,
              widthFraction: 1,
              heightFraction: 1,
            ),
          ),
        ),
      );

      await _listo(tester);
      return _juego(tester);
    }

    testWidgets('el mini juego del conejo no tiene fondo negro', (
      tester,
    ) async {
      final game = await monta(tester);
      expect(game.backgroundColor().a, 0.0);
    });

    testWidgets('el conejo esta anclado al centro del lienzo', (tester) async {
      final game = await monta(tester);
      final conejo = _conejo(game);
      final canvas = game.canvasSize;

      // Anclado al centro y colocado en el centro: no hay desplazamiento.
      expect(conejo.anchor, Anchor.center);
      expect(conejo.position.x, closeTo(canvas.x / 2, 0.01));
      expect(conejo.position.y, closeTo(canvas.y / 2, 0.01));
    });

    testWidgets('el conejo no toca los bordes del hueco', (tester) async {
      final game = await monta(tester);
      final conejo = _conejo(game);
      final canvas = game.canvasSize;
      final rect = _recto(conejo);

      // Sobra margen por los cuatro lados.
      expect(rect.width, lessThan(canvas.x));
      expect(rect.height, lessThan(canvas.y));
      expect(rect.left, greaterThan(0));
      expect(rect.top, greaterThan(0));
      expect(rect.right, lessThan(canvas.x));
      expect(rect.bottom, lessThan(canvas.y));
    });

    testWidgets('el margen es una proporcion del hueco', (tester) async {
      final game = await monta(tester);
      final conejo = _conejo(game);
      final canvas = game.canvasSize;
      final rect = _recto(conejo);

      // Ocupa la mayor parte del hueco sin pegarse al borde: es lo que evita
      // que el conejo choque visualmente con el texto de al lado.
      expect(rect.width / canvas.x, greaterThan(0.7));
      expect(rect.height / canvas.y, greaterThan(0.7));
      expect(rect.width / canvas.x, lessThan(0.95));
      expect(rect.height / canvas.y, lessThan(0.95));

      // Los margenes horizontales y verticales son iguales.
      expect(rect.left, closeTo((canvas.x - rect.width) / 2, 0.01));
      expect(rect.top, closeTo((canvas.y - rect.height) / 2, 0.01));
    });

    testWidgets('escalar no deforma el fotograma', (tester) async {
      final game = await monta(tester);
      final conejo = _conejo(game);
      final esperado = conejo.frameSize.x / conejo.frameSize.y;

      expect(conejo.width / conejo.height, closeTo(esperado, 0.001));
    });

    testWidgets('las tres animaciones se comportan igual', (tester) async {
      for (final animacion in ConejoAnimation.values) {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            home: SizedBox(
              width: 360,
              height: 640,
              child: ConejoAnimationView(
                animation: animacion,
                widthFraction: 1,
                heightFraction: 1,
              ),
            ),
          ),
        );

        await _listo(tester);

        final game = _juego(tester);
        final conejo = _conejo(game);
        final canvas = game.canvasSize;
        final rect = _recto(conejo);

        expect(
          conejo.position.x,
          closeTo(canvas.x / 2, 0.01),
          reason: animacion.name,
        );
        expect(
          conejo.position.y,
          closeTo(canvas.y / 2, 0.01),
          reason: animacion.name,
        );
        expect(rect.left, greaterThan(0), reason: animacion.name);
        expect(rect.top, greaterThan(0), reason: animacion.name);
        expect(rect.right, lessThan(canvas.x), reason: animacion.name);
        expect(rect.bottom, lessThan(canvas.y), reason: animacion.name);
      }

      tester.view.reset();
    });
  });
}