import 'package:flame/components.dart';
import 'package:flame/game.dart';

/// Cual de las tres animaciones del conejo se reproduce.
///
/// Los tres sprite sheets viven en `assets/images/` y son tiras
/// horizontales: el ancho del PNG es `frames x frameWidth`.
///
/// Las rutas son relativas porque Flame antepone su prefijo por defecto
/// (`assets/images/`) al pedir las imagenes.
enum ConejoAnimation {
  /// Menu de inicio, con el conejo presentando el juego.
  inicio('inicio.png', frames: 4, stepTime: 0.15),

  /// El usuario perdio contra la IA.
  loss('losse.png', frames: 3, stepTime: 0.18),

  /// El usuario gano.
  win('win.png', frames: 3, stepTime: 0.14);

  const ConejoAnimation(
    this.asset, {
    required this.frames,
    required this.stepTime,
  });

  /// Nombre del PNG dentro de `assets/images/`.
  final String asset;

  /// Numero de fotogramas de la tira.
  final int frames;

  /// Duracion de cada fotograma, en segundos.
  final double stepTime;

  /// Tamano exacto de un solo fotograma.
  Vector2 get frameSize => switch (this) {
    ConejoAnimation.inicio => Vector2(
      ConejoInicio.frameWidth,
      ConejoInicio.frameHeight,
    ),
    ConejoAnimation.loss => Vector2(
      ConejoLoss.frameWidth,
      ConejoLoss.frameHeight,
    ),
    ConejoAnimation.win => Vector2(ConejoWin.frameWidth, ConejoWin.frameHeight),
  };
}

/// Conejo del juego, animado a partir de un sprite sheet.
///
/// Cada clase concreta ([ConejoInicio], [ConejoLoss], [ConejoWin]) fija el
/// tamano exacto de un fotograma; el numero de fotogramas, el tiempo y la
/// carga salen de [kind], para no repetir datos.
///
/// Se puede usar como componente de Flame dentro de `PongGame` o aislarlo en
/// un juego propio con `ConejoAnimationView` para mostrarlo en una pantalla
/// de Flutter normal (menu, panel de resultado).
abstract class ConejoPlayer extends SpriteAnimationComponent
    with HasGameReference<FlameGame> {
  /// Nace anclado al centro, para poder centrarlo cambiando solo la posicion.
  ConejoPlayer({required this.kind, required Vector2 frameSize, super.position})
    : _frameSize = frameSize,
      super(size: frameSize, anchor: Anchor.center);

  /// Que animacion reproduce este componente.
  final ConejoAnimation kind;

  /// Tamano intrinseco del fotograma, guardado aparte de [size] a proposito:
  /// `size` cambia al escalar el componente para ajustarlo a la pantalla, y
  /// las medidas del sprite sheet no deben cambiar con el zoom de la pantalla.
  final Vector2 _frameSize;

  /// Tamano exacto de un solo fotograma, util para calcular el espacio que
  /// ocupa el conejo en pantalla sin deformarlo.
  Vector2 get frameSize => _frameSize;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Se usa `HasGameReference` en vez del `HasGameRef` deprecado: la API es
    // la misma pero con `game` en lugar de `gameRef`.
    final spriteSheet = await game.images.load(kind.asset);

    animation = SpriteAnimation.fromFrameData(
      spriteSheet,
      SpriteAnimationData.sequenced(
        amount: kind.frames,
        stepTime: kind.stepTime,
        textureSize: _frameSize,
        loop: true,
      ),
    );
  }
}

/// Crea el componente de Flame de la animacion pedida.
abstract final class ConejoPlayerFactory {
  static ConejoPlayer build(ConejoAnimation kind) => switch (kind) {
    ConejoAnimation.inicio => ConejoInicio(),
    ConejoAnimation.loss => ConejoLoss(),
    ConejoAnimation.win => ConejoWin(),
  };
}

/// Conejo del menu de inicio.
///
/// Tira horizontal de 4 fotogramas de 202 x 184 (`808 x 184`).
class ConejoInicio extends ConejoPlayer {
  /// Ancho exacto de un solo fotograma.
  static const double frameWidth = 202.0;

  /// Alto exacto de un solo fotograma.
  static const double frameHeight = 184.0;

  ConejoInicio({super.position})
    : super(
        kind: ConejoAnimation.inicio,
        frameSize: Vector2(frameWidth, frameHeight),
      );
}

/// Conejo de derrota: aparece cuando el usuario pierde contra la IA.
///
/// Tira horizontal de 3 fotogramas de 178.6 x 176 (`536 x 176`).
class ConejoLoss extends ConejoPlayer {
  /// Ancho exacto de un solo fotograma.
  static const double frameWidth = 178.6;

  /// Alto exacto de un solo fotograma.
  static const double frameHeight = 176.0;

  ConejoLoss({super.position})
    : super(
        kind: ConejoAnimation.loss,
        frameSize: Vector2(frameWidth, frameHeight),
      );
}

/// Conejo de victoria: aparece cada vez que el usuario gana un punto.
///
/// Tira horizontal de 3 fotogramas de 188.6 x 190 (`566 x 190`).
class ConejoWin extends ConejoPlayer {
  /// Ancho exacto de un solo fotograma.
  static const double frameWidth = 188.6;

  /// Alto exacto de un solo fotograma.
  static const double frameHeight = 190.0;

  ConejoWin({super.position})
    : super(
        kind: ConejoAnimation.win,
        frameSize: Vector2(frameWidth, frameHeight),
      );
}
