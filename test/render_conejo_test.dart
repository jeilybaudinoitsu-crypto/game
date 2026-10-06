import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game/personajes/conejo_animation_view.dart';
import 'package:game/personajes/conejo_player.dart';

/// Busca el tamano real del lienzo de Flame.
///
/// `find.byType(GameWidget)` no sirve: el tipo concreto es
/// `GameWidget<_ConejoStageGame>`.
Finder _canvas() => find.byWidgetPredicate((w) => w is GameWidget);

Future<void> _monta(
  WidgetTester tester,
  Size pantalla,
  ConejoAnimation kind, {
  double widthFraction = 0.62,
  double heightFraction = 0.32,
}) async {
  tester.view.physicalSize = pantalla;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: pantalla.width,
        height: pantalla.height,
        child: ConejoAnimationView(
          animation: kind,
          widthFraction: widthFraction,
          heightFraction: heightFraction,
        ),
      ),
    ),
  );
}

void main() {
  group('las tres animaciones se dibujan y avanzan', () {
    for (final kind in ConejoAnimation.values) {
      testWidgets('${kind.name} dibuja pixeles y cambia de fotograma', (
        tester,
      ) async {
        const lado = 400.0;
        tester.view.physicalSize = const Size(lado, lado);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            home: SizedBox(
              width: lado,
              height: lado,
              child: ConejoAnimationView(
                animation: kind,
                widthFraction: 1,
                heightFraction: 1,
              ),
            ),
          ),
        );

        // `runAsync` para que la decodificacion del PNG termine.
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 500)),
        );
        await tester.runAsync<void>(
          () => (tester.widget(_canvas()) as GameWidget<FlameGame>).game!.ready(),
        );
        await tester.pump();

        final conejo = (tester.widget(_canvas()) as GameWidget<FlameGame>).game!
            .world
            .children
            .query()
            .whereType<ConejoPlayer>()
            .single;
        final ticker = conejo.animationTicker!;

        // Hay fotograma cargado y dibujable: sin esto el conejo no se veria.
        expect(ticker.currentFrame.sprite, isNotNull);
        expect(ticker.spriteAnimation.frames.length, kind.frames);
        expect(
          ticker.currentFrame.sprite.srcSize.x,
          closeTo(kind.frameSize.x, 0.01),
        );

        final indiceInicial = ticker.currentIndex;

        // El reloj de Flame lo mueve `pump`, no el tiempo real: hay que
        // avanzar mas de un `stepTime` para que cambie de fotograma.
        await tester.pump(
          Duration(milliseconds: (kind.stepTime * 1000).ceil() + 120),
        );

        expect(
          ticker.currentIndex,
          isNot(equals(indiceInicial)),
          reason: '${kind.name} no cambia de fotograma: esta quieta',
        );
      });
    }
  });

  group('tamano responsive', () {
    testWidgets('el hueco respeta la proporcion del sprite', (tester) async {
      final inicioAspecto =
          ConejoAnimation.inicio.frameSize.x /
          ConejoAnimation.inicio.frameSize.y;

      // Caso 1: manda el ancho (altura sin limite, ancho al 62 %).
      await _monta(
        tester,
        const Size(400, 400),
        ConejoAnimation.inicio,
        heightFraction: 1,
      );
      var hueco = tester.getSize(_canvas());
      expect(hueco.width, closeTo(400 * 0.62, 1));
      expect(hueco.width / hueco.height, closeTo(inicioAspecto, 0.02));

      // Caso 2: manda el alto (el ancho no limita).
      await _monta(
        tester,
        const Size(400, 400),
        ConejoAnimation.inicio,
        widthFraction: 1,
        heightFraction: 0.32,
      );
      hueco = tester.getSize(_canvas());
      expect(hueco.height, closeTo(400 * 0.32, 1));
      expect(hueco.width / hueco.height, closeTo(inicioAspecto, 0.02));

      // Caso 3: cada animacion usa su propia proporcion.
      for (final kind in [ConejoAnimation.loss, ConejoAnimation.win]) {
        await _monta(
          tester,
          const Size(600, 400),
          kind,
          widthFraction: 1,
          heightFraction: 1,
        );
        final medida = tester.getSize(_canvas());
        final esperado = kind.frameSize.x / kind.frameSize.y;
        expect(medida.width / medida.height, closeTo(esperado, 0.02));
      }
    });

    testWidgets('el hueco queda centrado en la pantalla', (tester) async {
      await _monta(tester, const Size(400, 400), ConejoAnimation.inicio);

      final hueco = tester.getRect(_canvas());

      // Margenes iguales a izquierda y derecha, y arriba y abajo.
      expect((400 - hueco.width) / 2, closeTo(hueco.left, 1));
      expect((400 - hueco.height) / 2, closeTo(hueco.top, 1));
    });
  });
}
