import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'conejo_player.dart';

/// Muestra una animacion del conejo dentro de una pantalla de Flutter normal.
///
/// El menu y el panel de resultado no son juegos de Flame, asi que el
/// componente ([ConejoPlayer]) se aloja en un `FlameGame` minimo que solo
/// dibuja al conejo.
///
/// Tamano y centrado:
/// - El hueco reservado se calcula con `AspectRatio`, asi que el espacio que
///   ocupa en el layout es proporcional al sprite y nunca lo deforma.
/// - Dentro del juego el conejo se escala al mayor tamano que cabe y queda
///   anclado al centro, de modo que se ve igual en Android, iOS y web, tanto
///   en pantallas anchas como altas o con muesca.
class ConejoAnimationView extends StatefulWidget {
  const ConejoAnimationView({
    super.key,
    required this.animation,
    this.widthFraction = 0.62,
    this.heightFraction = 0.32,
  });

  /// Que animacion reproducir.
  final ConejoAnimation animation;

  /// Proporcion del ancho disponible que puede ocupar el conejo.
  final double widthFraction;

  /// Proporcion del alto disponible que puede ocupar el conejo.
  final double heightFraction;

  @override
  State<ConejoAnimationView> createState() => _ConejoAnimationViewState();
}

class _ConejoAnimationViewState extends State<ConejoAnimationView> {
  /// El juego se crea una sola vez y solo se cambia al pedir otra animacion.
  ///
  /// Si se construyera dentro de `build`, cada `setState` (por ejemplo al
  /// marcar un punto) crearia un juego nuevo: el conejo volveria al primer
  /// fotograma y las imagenes se cargarian otra vez.
  late _ConejoStageGame _game = _ConejoStageGame(widget.animation);

  @override
  void didUpdateWidget(covariant ConejoAnimationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      _game = _ConejoStageGame(widget.animation);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tamano de un fotograma: define la proporcion real del sprite.
    final frame = widget.animation.frameSize;
    final aspect = frame.x / frame.y;

    // Fallback cuando las restricciones son infinitas (por ejemplo dentro de
    // un `SingleChildScrollView`): se toma la pantalla como referencia.
    final media = MediaQuery.sizeOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : media.width;
        final maxH = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : media.height;

        // El `Center` de fuera mas el centrado interno garantizan que el
        // conejo queda centrado tambien sobra altura en el layout.
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: math.max(1, maxW * widget.widthFraction),
              maxHeight: math.max(1, maxH * widget.heightFraction),
            ),
            child: AspectRatio(
              aspectRatio: aspect,
              child: GameWidget<_ConejoStageGame>(game: _game),
            ),
          ),
        );
      },
    );
  }
}

/// Proporcion del hueco que ocupa el conejo.
///
/// A 1.0 el conejo tocaria los bordes del hueco reservado; con 0.85 queda
/// centrado con un pequeño margen alrededor, que es lo que se ve mejor junto
/// al texto del menu y del panel de resultado.
const double _fill = 0.85;

/// Juego minimo que solo pinta al conejo, centrado y ajustado al canvas.
class _ConejoStageGame extends FlameGame {
  _ConejoStageGame(this.animation);

  /// Animacion que reproduce este escenario.
  final ConejoAnimation animation;

  /// Sin fondo: el conejo se ve sobre el degradado de la pantalla, no sobre
  /// el rectangulo negro que Flame pone por defecto.
  @override
  Color backgroundColor() => const Color(0x00000000);

  ConejoPlayer? _bunny;

  /// Si el hueco ya tiene tamano y el conejo esta colocado.
  bool _colocado = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final bunny = ConejoPlayerFactory.build(animation);
    _bunny = bunny;

    // Sin `await`: la cola de ciclo de vida la procesa el bucle del juego, y
    // ese bucle no corre hasta que `onLoad` termina. Esperar aqui deja al
    // juego bloqueado y el conejo nunca llega a pintarse.
    world.add(bunny);
    _layout(size);
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    _layout(canvasSize);
  }

  @override
  void render(Canvas canvas) {
    // El redimensionado puede llegar antes de que termine de cargar el sprite:
    // al pintar se comprueba de nuevo y se coloca al conejo antes de dibujar
    // el primer fotograma. Si no, se quedaria en el origen.
    if (!_colocado && size.x > 0 && size.y > 0) {
      _layout(size);
    }
    super.render(canvas);
  }

  /// Escala el conejo al mayor tamano que cabe en el canvas y lo centra.
  void _layout(Vector2 canvasSize) {
    final bunny = _bunny;
    if (bunny == null || canvasSize.x <= 0 || canvasSize.y <= 0) return;

    final frame = bunny.frameSize;
    final scale = math.min(canvasSize.x / frame.x, canvasSize.y / frame.y);

    bunny
      // `SpriteAnimationComponent.render` dibuja el fotograma a `size`, asi
      // que cambiar `size` es lo que escala la imagen sin deformarla.
      //
      // Se deja un margen (`_fill`) para que el conejo no quede pegado al
      // borde del hueco reservado, que en el menu y en el panel queda justo
      // al lado del texto.
      ..size = Vector2(frame.x * scale * _fill, frame.y * scale * _fill)
      ..position = canvasSize / 2;

    _colocado = true;
  }
}
