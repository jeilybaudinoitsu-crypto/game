import 'package:flutter/widgets.dart';

import 'conejo_mascota.dart';

/// Comparte los sprites del conejo por todo el arbol de widgets.
///
/// Se cargan una sola vez al arrancar la app (ver `main.dart`) para no volver a
/// leer las imagenes del bundle en cada partida.
class BunnySpritesScope extends InheritedWidget {
  const BunnySpritesScope({
    super.key,
    required this.sprites,
    required super.child,
  });

  final BunnySprites sprites;

  /// Sprites compartidos. Si no hay ningun `BunnySpritesScope` arriba, devuelve
  /// una biblioteca vacia (el conejo se dibujara de forma vectorial).
  static BunnySprites of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<BunnySpritesScope>()
            ?.sprites ??
        BunnySprites.empty();
  }

  @override
  bool updateShouldNotify(BunnySpritesScope oldWidget) =>
      oldWidget.sprites != sprites;
}