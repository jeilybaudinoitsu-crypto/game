import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game/estetica/color.dart';
import 'package:game/game/game_config.dart';
import 'package:game/ui/menu_screen.dart';

/// Avanza el tiempo un numero fijo de pasos.
///
/// Usa un numero fijo de pasos para completar las transiciones de la interfaz.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

/// Recoge lo que el menu pasa a `onStart`, para poder comprobarlo.
class Picked {
  GameMode? mode;
  Difficulty? difficulty;
  int calls = 0;
}

void main() {
  /// Monta el menu con un tamano de pantalla concreto.
  Future<Picked> pumpMenu(
    WidgetTester tester, {
    Size size = const Size(420, 900),
  }) async {
    final picked = Picked();

    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: CuteTheme.fontFamily),
        home: MenuScreen(
          onStart: (mode, difficulty) {
            picked
              ..mode = mode
              ..difficulty = difficulty;
            picked.calls++;
          },
        ),
      ),
    );
    await settle(tester);

    return picked;
  }

  testWidgets('muestra el titulo y las dos opciones', (tester) async {
    await pumpMenu(tester);

    expect(find.text('Pin Pon Cute'), findsOneWidget);
    expect(find.text('Jugar con la IA'), findsOneWidget);
    expect(find.text('Jugar con un amigo'), findsOneWidget);
  });

  testWidgets('anuncia cuantos puntos hay que ganar', (tester) async {
    await pumpMenu(tester);

    expect(find.text('Gana ${GameConfig.pointsToWin} puntos para ganar'),
        findsOneWidget);
  });

  testWidgets('contra un amigo arranca directo, sin elegir dificultad',
      (tester) async {
    final picked = await pumpMenu(tester);

    await tester.tap(find.text('Jugar con un amigo'));
    await settle(tester);

    expect(picked.calls, 1);
    expect(picked.mode, GameMode.vsFriend);

    // No se pide nivel en este camino.
    expect(find.text('Nivel de la IA'), findsNothing);
  });

  testWidgets('contra la IA pide primero el nivel y no arranca todavia',
      (tester) async {
    final picked = await pumpMenu(tester);

    await tester.tap(find.text('Jugar con la IA'));
    await settle(tester);

    // Se abre la hoja con las tres dificultades, pero aun no hay partida.
    expect(find.text('Nivel de la IA'), findsOneWidget);
    for (final d in Difficulty.values) {
      expect(find.text(d.label), findsOneWidget);
    }
    expect(picked.calls, 0);
  });

  testWidgets('se puede cancelar la hoja de dificultad sin empezar',
      (tester) async {
    final picked = await pumpMenu(tester);

    await tester.tap(find.text('Jugar con la IA'));
    await settle(tester);
    await tester.tap(find.text('Cancelar'));
    await settle(tester);

    expect(find.text('Nivel de la IA'), findsNothing);
    expect(find.text('Pin Pon Cute'), findsOneWidget);
    expect(picked.calls, 0);
  });

  testWidgets('elegir nivel arranca la partida contra la IA', (tester) async {
    final picked = await pumpMenu(tester);

    await tester.tap(find.text('Jugar con la IA'));
    await settle(tester);

    await tester.tap(find.text(Difficulty.dificil.label));
    await settle(tester);

    expect(find.text('Nivel de la IA'), findsNothing);
    expect(picked.calls, 1);
    expect(picked.mode, GameMode.vsAI);
    expect(picked.difficulty, Difficulty.dificil);
  });

  testWidgets('el menu cabe en una pantalla pequeña', (tester) async {
    await pumpMenu(tester, size: const Size(320, 480));

    // No debe haber desbordamiento: todo se ve sin scroll infinito.
    await settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Pin Pon Cute'), findsOneWidget);
  });
}