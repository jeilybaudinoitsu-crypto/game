
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';

import 'color.dart';
import '../game/game_config.dart';

/// Lado de la pantalla en el que se coloca la raqueta.
enum PaddleSide { left, right }

/// Raqueta con estetica "capsula pastel".
///
/// En Android/iOS se controla arrastrando con el dedo ([DragCallbacks]);
/// en Web y escritorio la mueve el juego segun el teclado.
class CutePaddle extends RectangleComponent with DragCallbacks {
  CutePaddle({
    required super.position,
    required super.size,
    required this.color,
    required this.side,
    super.anchor,
  }) : super(paint: Paint());

  final Color color;
  final PaddleSide side;

  /// Color oscuro usado para el degradado y el contorno.
  Color get _shadeColor => Color.lerp(color, const Color(0xFF6B5E86), 0.22)!;

  /// Altura del campo de juego. La asigna el juego en `onGameResize`.
  double boundsHeight = 0;

  bool _flash = false;
  double _flashTime = 0;

  /// Hitbox de colision, added as child para seguir el movimiento de la raqueta.
  RectangleHitbox? _hitbox;

  bool get isDraggable => true;

  @override
  Future<void> onLoad() async {
    await add(RectangleHitbox(size: size.clone()));
    _hitbox = children.whereType<RectangleHitbox>().firstOrNull;
  }

  /// Mantiene el hitbox alineado despues de un cambio de tamano.
  void syncHitbox() => _hitbox?.size.setFrom(size);

  /// Radio de la capsula: media anchura produce el efecto "pildora".
  double get _radius => size.x / 2;

  /// Zona de contacto dulce (centro de la raqueta), 0..1 desde arriba.
  static const double _sweetSpotHalf = 0.18;

  void flash() {
    _flash = true;
    _flashTime = 0.16;
  }

  /// Limita la raqueta dentro del campo, sin dejar que se salga.
  void clampToBounds() {
    final maxY = boundsHeight - size.y;
    if (maxY <= 0) {
      position.y = 0;
      return;
    }
    position.y = position.y.clamp(0.0, maxY);
  }

  /// Desplazamiento vertical en pixels, ya acotado al campo.
  void moveBy(double deltaY) {
    position.y += deltaY;
    clampToBounds();
  }

  // --- Control tactil ------------------------------------------------------

  @override
  void onDragUpdate(DragUpdateEvent event) {
    // Incrementa o decrementa la posicion Y segun el movimiento del dedo.
    position.y += event.localDelta.y;

    // Limitar la raqueta para que no se salga de los bordes de la pantalla.
    clampToBounds();
  }

  /// Amplia el area tactil en horizontal para que sea facil de agarrar con el
  /// dedo en pantallas pequenas, sin alterar el dibujo.
  @override
  bool containsLocalPoint(Vector2 point) {
    final extra = GameConfig.dragHitSlop;
    return point.x >= -extra &&
        point.x <= size.x + extra &&
        point.y >= -extra &&
        point.y <= size.y + extra;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_flash) {
      _flashTime -= dt;
      if (_flashTime <= 0) _flash = false;
    }
  }

  @override
  void render(Canvas canvas) {
    final rect = size.toRect();
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(_radius));

    // Sombra difusa bajo la raqueta.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.shift(Offset(0, size.y * 0.10)).deflate(2),
        Radius.circular(_radius),
      ),
      Paint()..color = CuteTheme.shadow,
    );

    // Cuerpo: degradado vertical pastel.
    final body = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color.lerp(color, CuteTheme.white, 0.35)!, _shadeColor],
      ).createShader(rect);
    canvas.drawRRect(rrect, body);

    // Brillo superior.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left + 2, rect.top + 2, rect.width - 4, rect.height * 0.34),
        Radius.circular(_radius * 0.7),
      ),
      Paint()..color = const Color(0x40FFFFFF),
    );

    // Zona dulce: banda central mas clara.
    final sweetHeight = size.y * _sweetSpotHalf * 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: rect.center,
          width: rect.width * 0.62,
          height: sweetHeight,
        ),
        Radius.circular(sweetHeight / 2),
      ),
      Paint()..color = const Color(0x59FFFFFF),
    );

    // Contorno.
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = _flash ? CuteTheme.white : _shadeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = _flash ? 3.5 : 2.0,
    );
  }

}