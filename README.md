# Pin Pon Cute

Minijuego de Pin Pong hecho con **Flutter** y **Flame**, con estetica pastel,
mascota conejo y soporte para Android, iOS y Web.

Gana **7 puntos** para llevarte la partida. Puedes jugar contra la computadora
(en tres niveles de dificultad) o contra un amigo en el mismo dispositivo.

## Como se juega

| Plataforma | Jugador 1 | Jugador 2 |
| --- | --- | --- |
| Android / iOS | Arrastra la raqueta con el dedo | — (solo IA) |
| Web / escritorio | Teclas `W` / `S` | Flechas `↑` / `↓` |

Reglas basics:

- La pelota rebota en las raquetas y en los bordes superior e inferior.
- Donde golpea la raqueta cambia el angulo: cuanto mas lejos del centro, mas
  abierto sale. El centro de la raqueta es la "zona dulce" y devuelve la
  pelota casi recta.
- Cada rebote acelera un poco la pelota.
- El punto es para el jugador **contrario** al que dejo pasar la pelota: si
  se escapa por la izquierda suma el jugador 2, y al reves.
- Tras un punto hay una pausa breve y la pelota se saca hacia el lado del
  ultimo que puntuo.

## Estructura del proyecto

```
lib/
├── main.dart                  # Punto de entrada, tema y navegacion menu <-> partida
├── estetica/
│   ├── color.dart             # Paleta pastel (CuteTheme)
│   ├── extra.dart             # Fondo, red y marco de la cancha
│   ├── pelota.dart            # CuteBall: circulo durazno con brillo y estela
│   ├── raqueta.dart           # CutePaddle: capsula pastel con control tactil
│   └── conejo.dart            # Utiles de dibujo del conejo
├── game/
│   ├── pong_game.dart         # Lógica de la partida: fases, saque, rebotes y marcador
│   ├── game_config.dart       # Constantes de reglas y dificultades
│   ├── ai_controller.dart     # Dificultad y error de la computadora
│   └── keyboard_input.dart    # Mapeo de teclas (W/S y flechas)
├── mascota/
│   ├── bunny_sprites_scope.dart   # Carga y comparte los PNG del conejo
│   ├── conejo_mascota.dart        # Componente Flame: poses y animaciones
│   └── conejo_widget.dart         # Version como widget normal para la UI
├── ui/
│   ├── menu_screen.dart       # Menu, selector de dificultad
│   ├── game_screen.dart       # Pantalla de partida: HUD y panel de resultado
│   └── widgets/
│       ├── cute_button.dart   # Boton pastel
│       └── score_board.dart   # Marcador superior
└── assets/imagenes/           # 6 PNG del conejo (idle, warmup, run, hit, win, lose)

assets/fonts/                  # Fredoka (Regular, Medium, SemiBold, Bold)
test/                          # Pruebas unitarias, de widgets y de regresión
```

## Como se ejecuta

```bash
flutter pub get

# Web
flutter run -d chrome
flutter build web --release

# Android (necesita el SDK de Android instalado)
flutter run -d <android-device>
flutter build apk --release

# iOS (solo en macOS)
flutter run -d <ios-device>
```

## Pruebas y analisis

```bash
flutter analyze
flutter test
```

## Notas tecnicas

- La deteccion de colisiones usa el sistema de hitboxes de Flame: la pelota
  lleva un `CircleHitbox` hijo y las raquetas un `RectangleHitbox`. El callback
  de la pelota recibe el **hitbox** con el que choco, asi que hay que desenrollar
  `hitboxParent` para recuperar la raqueta.
- El HUD no se repinta solo: `PongGame.onScoreChanged` notifica cada cambio y
  `GameScreen` llama a `setState`.
- El menu usa su propio `ScrollController` con `primary: false` para no
  engancharse al `PrimaryScrollController`, que hacia saltar la pantalla al
  entrar en la partida.