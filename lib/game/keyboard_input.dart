import 'package:flame/components.dart';
import 'package:flutter/services.dart';

/// Acciones de control que el jugador puede mantener pulsadas.
enum MoveAction {
  player1Up,
  player1Down,
  player2Up,
  player2Down,
}

/// Lectura del teclado para Web y escritorio.
///
/// - Jugador A: `W` (arriba) y `S` (abajo).
/// - Jugador B: secuencia ANSI de flecha: `\x1b[A` (arriba) y `\x1b[B` (abajo).
///
/// En Web el navegador entrega la flecha como tecla logica, asi que tambien se
/// acepta [LogicalKeyboardKey.arrowUp] / [LogicalKeyboardKey.arrowDown] para que
/// el control funcione de verdad en el navegador y en escritorio.
class KeyboardInput extends Component with KeyboardHandler {
  final Set<MoveAction> _active = {};

  /// Acciones que estan siendo mantenidas en este momento.
  Set<MoveAction> get active => Set.unmodifiable(_active);

  bool isHeld(MoveAction action) => _active.contains(action);

  @override
  bool onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    final actions = _actionsFor(event);
    if (actions.isEmpty) return false;

    if (event is KeyUpEvent) {
      for (final a in actions) {
        _active.remove(a);
      }
    } else {
      // KeyDownEvent y KeyRepeatEvent: se mantiene pulsado.
      for (final a in actions) {
        _active.add(a);
      }
    }
    // `true` marca el evento como consumido.
    return true;
  }

  /// Traduce un evento de teclado al conjunto de acciones que representa.
  Set<MoveAction> _actionsFor(KeyEvent event) {
    final key = event.logicalKey;
    final char = event.character;

    // Jugador A: W / S.
    if (key == LogicalKeyboardKey.keyW || char == 'w' || char == 'W') {
      return {MoveAction.player1Up};
    }
    if (key == LogicalKeyboardKey.keyS || char == 's' || char == 'S') {
      return {MoveAction.player1Down};
    }

    // Jugador B: secuencias ANSI de las flechas del teclado.
    // '\x1b[A' = arriba, '\x1b[B' = abajo.
    if (char == '\x1b[A' ||
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.numpad8) {
      return {MoveAction.player2Up};
    }
    if (char == '\x1b[B' ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.numpad2) {
      return {MoveAction.player2Down};
    }

    return const {};
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _active.clear();
  }
}