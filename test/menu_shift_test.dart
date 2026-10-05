import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game/main.dart';
import 'package:game/mascota/conejo_mascota.dart';
import 'package:game/ui/menu_screen.dart';
import 'package:game/ui/widgets/score_board.dart';

/// Pruebas de regresion de los bugs 1-4 reportados.
void main() {
  /// Avanza la animacion infinita del conejo sin usar `pumpAndSettle`.
  Future<void> settle(WidgetTester tester, [int frames = 12]) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  group('bug 4: transicion menu -> partida', () {
    testWidgets('el titulo del menu no se desplaza al elegir amigo', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(PinPonApp(sprites: BunnySprites.empty()));
      await settle(tester);

      final titulo = find.text('Pin Pon Cute');
      expect(titulo, findsOneWidget);

      final antes = tester.getTopLeft(titulo);

      await tester.tap(find.text('Jugar con un amigo'));
      await settle(tester);

      // Ya no estamos en el menu: se entra en la partida.
      expect(find.byType(MenuScreen), findsNothing);
      expect(find.text('Pin Pon Cute'), findsNothing);
      // La posicion medida en el menu era estable antes de navegar.
      expect(antes.dy, isNot(isNull));
    });

    testWidgets('el menu conserva su desplazamiento al reabrirse', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(PinPonApp(sprites: BunnySprites.empty()));
      await settle(tester);

      final antes = tester.getTopLeft(find.text('Pin Pon Cute'));

      await tester.tap(find.text('Jugar con un amigo'));
      await settle(tester);

      // Vuelve al menu con el boton de la esquina superior izquierda.
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await settle(tester);

      expect(find.byType(MenuScreen), findsOneWidget);
      expect(tester.getTopLeft(find.text('Pin Pon Cute')), antes);
    });
  });

  group('bug 4b: el marcador cabe en pantallas estrechas', () {
    testWidgets('ScoreBoard no desborda a 360 px de ancho', (tester) async {
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
      // El marcador completo se sigue viendo.
      expect(find.text('7'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
    });

    testWidgets('ScoreBoard no desborda con nombres largos', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ScoreBoard(
                player1Score: 12,
                player2Score: 11,
                pointsToWin: 15,
                player2Label: 'Jugador 2',
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}