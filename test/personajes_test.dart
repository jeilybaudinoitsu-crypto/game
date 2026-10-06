import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game/personajes/conejo_player.dart';

/// Tamano real de los PNG de `assets/images/`, leido de los archivos.
const _sizes = {
  'inicio.png': (width: 808.0, height: 184.0),
  'losse.png': (width: 536.0, height: 176.0),
  'win.png': (width: 566.0, height: 190.0),
};

/// Juego minimo que solo carga un conejo, para poder inspeccionarlo.
class _BunnyGame extends FlameGame {
  _BunnyGame(this.kind);

  final ConejoAnimation kind;

  late final ConejoPlayer bunny;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    bunny = ConejoPlayerFactory.build(kind);
    await world.add(bunny);
  }
}

void main() {
  group('sprite sheets de los personajes', () {
    test('cada PNG encaja exacto en su numero de fotogramas', () {
      final cases = {
        ConejoAnimation.inicio: (
          frames: 4,
          size: ConejoAnimation.inicio.frameSize,
        ),
        ConejoAnimation.loss: (frames: 3, size: ConejoAnimation.loss.frameSize),
        ConejoAnimation.win: (frames: 3, size: ConejoAnimation.win.frameSize),
      };

      for (final entry in cases.entries) {
        final kind = entry.key;
        final data = entry.value;
        final png = _sizes[kind.asset]!;

        expect(
          data.size.x * data.frames,
          closeTo(png.width, 0.5),
          reason: '$kind: ${data.frames} fotogramas no cubren el ancho del PNG',
        );
        expect(
          data.size.y,
          png.height,
          reason: '$kind: el alto del fotograma no es el alto del PNG',
        );
      }
    });

    test('ningun fotograma se sale del PNG', () {
      // Con el ancho fraccionario (178.6) el ultimo fotograma de una tira no
      // acaba justo en el borde: si se saliera, al pintar se veria un trozo
      // del fotograma vecino.
      final cases = {
        ConejoAnimation.inicio: (
          size: ConejoAnimation.inicio.frameSize,
          frames: 4,
        ),
        ConejoAnimation.loss: (size: ConejoAnimation.loss.frameSize, frames: 3),
        ConejoAnimation.win: (size: ConejoAnimation.win.frameSize, frames: 3),
      };

      for (final entry in cases.entries) {
        final kind = entry.key;
        final data = entry.value;
        final png = _sizes[kind.asset]!;
        final ultimoDerecho = data.size.x * (data.frames - 1) + data.size.x;

        expect(
          ultimoDerecho,
          lessThanOrEqualTo(png.width),
          reason: '$kind: el ultimo fotograma se sale del PNG por la derecha',
        );
        expect(
          data.size.y,
          lessThanOrEqualTo(png.height),
          reason: '$kind: el alto del fotograma se sale del PNG',
        );
      }
    });

    test('el enum declara la ruta y el numero de fotogramas', () {
      expect(ConejoAnimation.inicio.asset, 'inicio.png');
      expect(ConejoAnimation.inicio.frames, 4);

      expect(ConejoAnimation.loss.asset, 'losse.png');
      expect(ConejoAnimation.loss.frames, 3);

      expect(ConejoAnimation.win.asset, 'win.png');
      expect(ConejoAnimation.win.frames, 3);
    });

    test('las dimensiones son las pedidas', () {
      expect(ConejoInicio.frameWidth, 202.0);
      expect(ConejoInicio.frameHeight, 184.0);
      expect(ConejoLoss.frameWidth, 178.6);
      expect(ConejoLoss.frameHeight, 176.0);
      expect(ConejoWin.frameWidth, 188.6);
      expect(ConejoWin.frameHeight, 190.0);
    });

    test('el enum expone el tamano de fotograma correcto', () {
      // `Vector2` guarda en float de 32 bits, asi que se compara con
      // tolerancia en lugar de igualdad exacta.
      expect(
        ConejoAnimation.inicio.frameSize.x,
        closeTo(ConejoInicio.frameWidth, 0.01),
      );
      expect(
        ConejoAnimation.inicio.frameSize.y,
        closeTo(ConejoInicio.frameHeight, 0.01),
      );
      expect(
        ConejoAnimation.loss.frameSize.x,
        closeTo(ConejoLoss.frameWidth, 0.01),
      );
      expect(
        ConejoAnimation.loss.frameSize.y,
        closeTo(ConejoLoss.frameHeight, 0.01),
      );
      expect(
        ConejoAnimation.win.frameSize.x,
        closeTo(ConejoWin.frameWidth, 0.01),
      );
      expect(
        ConejoAnimation.win.frameSize.y,
        closeTo(ConejoWin.frameHeight, 0.01),
      );
    });

    test('el ancho pedido cubre el PNG completo', () {
      // `frames x frameWidth` tiene que dar exactamente el ancho del PNG, si no
      // sobra fondo vacio o se corta el ultimo fotograma.
      expect(ConejoAnimation.inicio.frameSize.x * 4, closeTo(808, 0.5));
      expect(ConejoAnimation.loss.frameSize.x * 3, closeTo(536, 0.5));
      expect(ConejoAnimation.win.frameSize.x * 3, closeTo(566, 0.5));
    });

    test('el tamano del fotograma no cambia al escalar en pantalla', () {
      // `frameSize` guarda el tamano intrinseco, separado de `size` (que si
      // cambia al ajustar el componente al canvas). Si se mezclaran, al
      // rotar el dispositivo la escala se acumularia en cada ajuste.
      final bunny = ConejoWin();
      final intrinseco = bunny.frameSize.clone();

      bunny.size = Vector2(50, 50);
      expect(bunny.frameSize.x, closeTo(intrinseco.x, 0.01));
      expect(bunny.frameSize.y, closeTo(intrinseco.y, 0.01));

      bunny.size = Vector2(120, 110);
      expect(bunny.frameSize.x, closeTo(intrinseco.x, 0.01));
      expect(bunny.frameSize.y, closeTo(intrinseco.y, 0.01));
    });

    test('los conejos se anclan al centro', () {
      expect(ConejoInicio().anchor, Anchor.center);
      expect(ConejoLoss().anchor, Anchor.center);
      expect(ConejoWin().anchor, Anchor.center);
    });

    for (final kind in ConejoAnimation.values) {
      FlameTester<_BunnyGame>(
        () => _BunnyGame(kind),
        gameSize: Vector2(400, 300),
      ).testGameWidget(
        '${kind.name} carga su sprite sheet y lo trocea en ${kind.frames} fotogramas',
        verify: (game, tester) async {
          // `game.ready` espera al juego, pero el componente carga su PNG
          // despues: `loaded` es lo que espera a que `onLoad` termine.
          await tester.runAsync(game.ready);
          await tester.runAsync(() => game.bunny.loaded);

          final animation = game.bunny.animation;
          expect(animation, isNotNull, reason: '$kind no cargo animacion');
          expect(
            animation!.frames.length,
            kind.frames,
            reason: '$kind no se troceo en $kind.frames fotogramas',
          );
          expect(
            animation.frames.first.sprite.srcSize.x,
            closeTo(kind.frameSize.x, 0.01),
          );
          expect(
            animation.frames.first.sprite.srcSize.y,
            closeTo(kind.frameSize.y, 0.01),
          );
        },
      );
    }
  });
}
