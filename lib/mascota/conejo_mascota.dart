import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/services.dart';

import '../estetica/color.dart';

/// Poses disponibles del conejo, segun los PNG de `lib/assets/imagenes/`.
enum BunnyPose {
  /// Reposo, se usa en el menu.
  idle,

  /// Calentamiento antes de empezar la partida.
  warmup,

  /// Celebracion al anotar un punto.
  run,

  /// Reaccion al golpear la pelota con la raqueta.
  hit,

  /// Gano la partida.
  win,

  /// Perdio la partida.
  lose,
}

/// Secuencias de fotogramas por pose.
///
/// Cada PNG es una imagen independiente (no un spritesheet), asi que las
/// animaciones se arman alternando esos fotogramas.
const Map<BunnyPose, List<String>> kBunnyFrames = {
  BunnyPose.idle: ['estatico'],
  BunnyPose.warmup: ['calentamiento'],
  BunnyPose.run: ['corre', 'estatico', 'corre', 'golpea'],
  BunnyPose.hit: ['golpea', 'estatico'],
  BunnyPose.win: ['win', 'corre', 'win', 'golpea'],
  BunnyPose.lose: ['lose'],
};

/// Duracion de cada fotograma, por pose.
const Map<BunnyPose, double> kBunnyFrameDuration = {
  BunnyPose.idle: 0.6,
  BunnyPose.warmup: 0.35,
  BunnyPose.run: 0.11,
  BunnyPose.hit: 0.10,
  BunnyPose.win: 0.22,
  BunnyPose.lose: 0.6,
};

/// Cuantas veces se repite la pose antes de volver a `idle`.
const Map<BunnyPose, int> kBunnyLoops = {
  BunnyPose.idle: 0,
  BunnyPose.warmup: 3,
  BunnyPose.run: 2,
  BunnyPose.hit: 1,
  BunnyPose.win: 4,
  BunnyPose.lose: 0,
};

/// Ruta base de las imagenes dentro del bundle.
const String kBunnyAssetDir = 'lib/assets/imagenes/';

/// Biblioteca de sprites del conejo.
///
/// Se carga una sola vez y se comparte entre el menu y la partida.
class BunnySprites {
  BunnySprites._(this._sprites);

  /// Biblioteca vacia: el conejo se dibuja con el respaldo vectorial.
  factory BunnySprites.empty() => BunnySprites._(const {});

  final Map<String, Sprite> _sprites;

  Sprite? operator [](String name) => _sprites[name];

  bool get isEmpty => _sprites.isEmpty;

  /// Nombres de todos los fotogramas registrados, sin repetidos.
  static List<String> get allFrameNames => {
        for (final frames in kBunnyFrames.values) ...frames,
      }.toList(growable: false);

  /// Carga todas las imagenes del conejo desde el bundle.
  ///
  /// No lanza excepciones: si una imagen falta se omite y se usara el conejo
  /// dibujado a mano como respaldo.
  static Future<BunnySprites> load() async {
    final sprites = <String, Sprite>{};
    for (final name in allFrameNames) {
      try {
        final data = await rootBundle.load('$kBunnyAssetDir$name.png');
        final bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        sprites[name] = Sprite(frame.image);
      } catch (_) {
        // Sin la imagen, el juego sigue funcionando con el conejo vectorial.
        continue;
      }
    }
    return BunnySprites._(sprites);
  }
}

/// Mascota conejo: animaciones + globo de dialogo para anunciar el marcador.
class BunnyMascot extends PositionComponent {
  BunnyMascot({
    required super.position,
    required this.sprites,
    this.spriteHeight = 90,
    this.facingRight = false,
    super.anchor,
  }) : super(size: Vector2(spriteHeight * 1.6, spriteHeight));

  final BunnySprites sprites;

  /// Alto deseado del conejo en pixeles de juego.
  final double spriteHeight;

  /// `true` mira a la derecha, `false` a la izquierda.
  bool facingRight;

  /// `true` si hay al menos un fotograma de sprite disponible.
  bool get hasSprites => !sprites.isEmpty;

  BunnyPose _pose = BunnyPose.idle;
  int _frame = 0;
  double _frameTime = 0;
  int _loopsLeft = 0;
  double _time = 0;

  String? _message;
  double _messageTime = 0;
  bool _messageVisible = false;

  static const double _defaultFrameDuration = 0.12;
  static const double _messageDuration = 1.8;

  BunnyPose get pose => _pose;

  /// Cambia la animacion. Al terminar la secuencia vuelve a reposo, salvo que
  /// [returnToIdle] sea `false` (util para `win` y `lose`).
  void play(BunnyPose pose, {bool returnToIdle = true}) {
    if (_pose == pose && _loopsLeft > 0) return;
    _pose = pose;
    _frame = 0;
    _frameTime = 0;
    _loopsLeft = returnToIdle ? (kBunnyLoops[pose] ?? 1) : 0;
  }

  /// Muestra un texto en el globo (por ejemplo el punto anotado).
  void say(String text, {double seconds = _messageDuration}) {
    _message = text;
    _messageTime = seconds;
    _messageVisible = true;
  }

  void hideMessage() {
    _messageVisible = false;
    _message = null;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    final frames = kBunnyFrames[_pose] ?? const ['estatico'];
    final duration = kBunnyFrameDuration[_pose] ?? _defaultFrameDuration;

    _frameTime += dt;
    if (_frameTime >= duration) {
      _frameTime -= duration;
      _frame++;
      if (_frame >= frames.length) {
        _frame = 0;
        if (_loopsLeft > 0) {
          _loopsLeft--;
        } else if (_pose != BunnyPose.idle) {
          _pose = BunnyPose.idle;
          _frame = 0;
        }
      }
    }

    if (_messageVisible) {
      _messageTime -= dt;
      if (_messageTime <= 0) hideMessage();
    }
  }

  /// Rebote vertical del conejo, mas marcado mientras corre o celebra.
  double get _bob {
    final amplitude = switch (_pose) {
      BunnyPose.run => spriteHeight * 0.10,
      BunnyPose.win => spriteHeight * 0.12,
      BunnyPose.hit => spriteHeight * 0.05,
      _ => spriteHeight * 0.025,
    };
    final speed = switch (_pose) {
      BunnyPose.run => 16.0,
      BunnyPose.win => 11.0,
      _ => 3.0,
    };
    return math.sin(_time * speed) * amplitude;
  }

  /// Inclinacion lateral segun la animacion.
  double get _tilt => switch (_pose) {
        BunnyPose.run => math.sin(_time * 14) * 0.10,
        BunnyPose.win => math.sin(_time * 8) * 0.08,
        _ => 0.0,
      };

  @override
  void render(Canvas canvas) {
    final frames = kBunnyFrames[_pose] ?? const ['estatico'];
    final sprite = sprites[frames[_frame % frames.length]];

    // El anchor es `center`, asi que el origen local ya esta en `position`.
    canvas.save();
    canvas.rotate(_tilt);

    if (sprite != null) {
      final aspect = sprite.srcSize.x / sprite.srcSize.y;
      final dst = Vector2(spriteHeight * aspect, spriteHeight);
      canvas.translate(0, _bob);
      canvas.scale(facingRight ? 1.0 : -1.0, 1.0);
      sprite.render(
        canvas,
        position: Vector2(-dst.x / 2, -dst.y / 2),
        size: dst,
      );
    } else {
      // Respaldo vectorial si no hay imagenes cargadas.
      canvas.translate(-size.x / 2, -size.y / 2);
      _drawFallbackBunny(canvas);
    }

    canvas.restore();

    if (_messageVisible && _message != null) {
      _renderMessage(canvas, _message!);
    }
  }

  void _renderMessage(Canvas canvas, String text) {
    // `toTextPainter` da un TextPainter de Flutter, util para medir y pintar.
    final painter = TextPaint(
      style: CuteTheme.font(
        size: spriteHeight * 0.30,
        weight: 7,
        color: CuteTheme.text,
      ),
    ).toTextPainter(text);

    final bubbleWidth = painter.width + spriteHeight * 0.44;
    final bubbleHeight = painter.height + spriteHeight * 0.26;
    final center = Offset(0, -spriteHeight * 0.72);
    final rect = Rect.fromCenter(
      center: center,
      width: bubbleWidth,
      height: bubbleHeight,
    );

    // Globo con "pop" de entrada.
    final t = (1 - (_messageTime / _messageDuration)).clamp(0.0, 1.0);
    final scale = 0.7 + 0.3 * Curves.easeOutBack.transform(t);

    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.scale(scale);
    canvas.translate(-rect.center.dx, -rect.center.dy);

    final rrect =
        RRect.fromRectAndRadius(rect, Radius.circular(bubbleHeight / 2));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.shift(const Offset(0, 3)),
        Radius.circular(bubbleHeight / 2),
      ),
      Paint()..color = CuteTheme.shadow,
    );
    canvas.drawRRect(rrect, Paint()..color = CuteTheme.white);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = CuteTheme.text.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Piquito de la burbuja.
    final tail = Path()
      ..moveTo(rect.center.dx - spriteHeight * 0.09, rect.bottom - 2)
      ..lineTo(rect.center.dx, rect.bottom + spriteHeight * 0.16)
      ..lineTo(rect.center.dx + spriteHeight * 0.09, rect.bottom - 2)
      ..close();
    canvas.drawPath(tail, Paint()..color = CuteTheme.white);

    painter.paint(
      canvas,
      Offset(
        rect.center.dx - painter.width / 2,
        rect.center.dy - painter.height / 2,
      ),
    );

    canvas.restore();
  }

  /// Conejo vectorial minimo, usado si falta el asset.
  void _drawFallbackBunny(Canvas canvas) {
    final w = size.x * 0.8;
    final h = size.y;
    final white = Paint()..color = CuteTheme.white;
    final pink = Paint()..color = CuteTheme.player1;
    final eye = Paint()..color = const Color(0xFF4A4A4A);

    canvas.drawOval(Rect.fromLTWH(w * 0.28, 0, w * 0.14, h * 0.42), white);
    canvas.drawOval(Rect.fromLTWH(w * 0.58, 0, w * 0.14, h * 0.42), white);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.1, h * 0.3, w * 0.8, h * 0.62),
        Radius.circular(w * 0.3),
      ),
      white,
    );
    canvas.drawCircle(Offset(w * 0.36, h * 0.55), w * 0.05, eye);
    canvas.drawCircle(Offset(w * 0.64, h * 0.55), w * 0.05, eye);
    canvas.drawCircle(Offset(w * 0.5, h * 0.66), w * 0.045, pink);
  }

}