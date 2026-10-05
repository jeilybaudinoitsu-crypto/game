import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'conejo_mascota.dart';

/// Vista del conejo hecha con widgets, para las pantallas de Flutter.
///
/// Reutiliza las mismas tablas de fotogramas que la version de Flame, de modo
/// que el menu y la partida muestran la misma animacion.
class BunnySpriteView extends StatefulWidget {
  const BunnySpriteView({
    super.key,
    this.pose = BunnyPose.idle,
    this.height = 130,
    this.facingRight = false,
    this.bobbing = true,
  });

  final BunnyPose pose;

  /// Alto del conejo en pixeles.
  final double height;

  final bool facingRight;

  /// Anima el rebote vertical.
  final bool bobbing;

  @override
  State<BunnySpriteView> createState() => _BunnySpriteViewState();
}

class _BunnySpriteViewState extends State<BunnySpriteView>
    with TickerProviderStateMixin {
  /// Ciclo de fotogramas de la animacion actual.
  late final AnimationController _frames;

  /// Ciclo lento y continuo usado solo para el rebote.
  late final AnimationController _bob;

  @override
  void initState() {
    super.initState();
    _frames = AnimationController(vsync: this);
    _bob = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _restartFrames();
  }

  void _restartFrames() {
    final frames = kBunnyFrames[widget.pose] ?? const ['estatico'];
    final duration = kBunnyFrameDuration[widget.pose] ?? 0.12;
    final total = Duration(
      milliseconds: (duration * frames.length * 1000).round().clamp(80, 4000),
    );
    _frames
      ..duration = total
      ..repeat();
  }

  @override
  void didUpdateWidget(covariant BunnySpriteView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pose != widget.pose) _restartFrames();
  }

  @override
  void dispose() {
    _frames.dispose();
    _bob.dispose();
    super.dispose();
  }

  /// Amplitud del rebote segun la animacion.
  double get _amplitude => switch (widget.pose) {
        BunnyPose.run => 10,
        BunnyPose.win => 12,
        BunnyPose.hit => 4,
        _ => 3.5,
      };

  @override
  Widget build(BuildContext context) {
    final frames = kBunnyFrames[widget.pose] ?? const ['estatico'];
    final bob = widget.bobbing
        ? math.sin(_bob.value * math.pi * 2) * _amplitude
        : 0.0;

    return AnimatedBuilder(
      animation: Listenable.merge([_frames, _bob]),
      builder: (context, _) {
        final current =
            frames[(_frames.value * frames.length).floor() % frames.length];

        return Transform.translate(
          offset: Offset(0, bob),
          child: Transform.scale(
            scaleX: widget.facingRight ? 1 : -1,
            child: Image.asset(
              '$kBunnyAssetDir$current.png',
              key: ValueKey(current),
              height: widget.height,
              fit: BoxFit.contain,
              // Evita el salto de layout al cambiar de fotograma.
              gaplessPlayback: true,
              errorBuilder: (context, error, stack) =>
                  const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}