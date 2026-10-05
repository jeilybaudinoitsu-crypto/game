
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:flame/extensions.dart';

import 'color.dart';
import 'raqueta.dart';

/// Pelota del juego: esfera durazno con brillo, sombra y estela.
///
/// Se dibuja como un circulo perfecto (no un cuadrado) para el look pastel.
///
/// Flame exige que un `ShapeHitbox` cuelgue de un `PositionComponent`, asi que
/// la pelota es un componente normal que lleva dentro su [CircleHitbox]; las
/// colisiones se reciben en el hitbox y se reenvian a [onHitPaddle].
class CuteBall extends PositionComponent {
  CuteBall({
    required super.position,
    required double radius,
    Vector2? velocity,
  })  : radius = radius,
        velocity = velocity ?? Vector2.zero(),
        super(size: Vector2.all(radius * 2), anchor: Anchor.center);

  /// Radio de la pelota en pixeles.
  final double radius;

  late final CircleHitbox _hitbox = CircleHitbox(
    radius: radius,
    anchor: Anchor.center,
    position: size / 2,
  );

  /// Velocidad actual en pixeles por segundo.
  Vector2 velocity;

  /// Se invoca cuando la pelota golpea una raqueta.
  void Function(CutePaddle paddle)? onHitPaddle;

  /// Historial de posiciones para dibujar la estela.
  final List<Vector2> _trail = [];

  static const int _maxTrail = 12;

  double get speed => velocity.length;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _hitbox
      ..onCollisionCallback = _onHitboxCollision
      ..onCollisionStartCallback = _onHitboxCollision;

    await add(_hitbox);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.add(velocity * dt);

    _trail.add(position.clone());
    if (_trail.length > _maxTrail) _trail.removeAt(0);
  }

  /// Limpia la estela (usado al reiniciar el punto).
  void resetTrail() {
    _trail.clear();
  }

  /// Traduce una colision del hitbox a un evento de "he dado a una raqueta".
  void _onHitboxCollision(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    // `other` es la raqueta (el padre del hitbox con el que choco la pelota).
    if (other is CutePaddle) onHitPaddle?.call(other);
  }

  @override
  void render(Canvas canvas) {
    final center = (size / 2).toOffset();
    final r = size.x / 2;

    // --- Estela: circulos que se desvanecen hacia atras -------------------
    for (var i = 0; i < _trail.length; i++) {
      final progress = (i + 1) / _trail.length; // 0..1, 1 = mas reciente
      final t = _trail[i];
      final alpha = (progress * progress * 0.30).clamp(0.0, 0.30);
      canvas.drawCircle(
        t.toOffset(),
        r * (0.35 + 0.55 * progress),
        Paint()..color = CuteTheme.ball.withValues(alpha: alpha),
      );
    }

    // --- Resplandor exterior ----------------------------------------------
    canvas.drawCircle(
      center,
      r * 1.7,
      Paint()
        ..color = CuteTheme.ball.withValues(alpha: 0.20)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // --- Sombra proyectada (debajo-derecha) -------------------------------
    canvas.drawCircle(
      center.translate(r * 0.16, r * 0.20),
      r * 0.92,
      Paint()..color = CuteTheme.shadow,
    );

    // --- Esfera durazno ---------------------------------------------------
    final bodyRect = Rect.fromCircle(center: center, radius: r);
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 1.05,
          colors: [
            Color.lerp(CuteTheme.ball, CuteTheme.white, 0.55)!,
            CuteTheme.ball,
            CuteTheme.ballDark,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(bodyRect),
    );

    // --- Brillo especular --------------------------------------------------
    canvas.drawCircle(
      center.translate(-r * 0.32, -r * 0.36),
      r * 0.26,
      Paint()..color = const Color(0xB3FFFFFF),
    );

    // --- Contorno suave ----------------------------------------------------
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = CuteTheme.ballDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = (r * 0.10).clamp(1.2, 3.0),
    );
  }

}