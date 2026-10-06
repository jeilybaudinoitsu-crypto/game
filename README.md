# Pin Pon Cute

Minijuego de Pin Pong hecho con **Flutter** y **Flame**, con estetica pastel,
soporte para Android, iOS y Web.

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
│   └── raqueta.dart           # CutePaddle: capsula pastel con control tactil
├── game/
│   ├── pong_game.dart         # Lógica de la partida: fases, saque, rebotes y marcador
│   ├── game_config.dart       # Constantes de reglas y dificultades
│   ├── ai_controller.dart     # Dificultad y error de la computadora
│   └── keyboard_input.dart    # Mapeo de teclas (W/S y flechas)
├── personajes/
│   ├── conejo_player.dart     # SpriteAnimationComponent del conejo (inicio/losse/win)
│   └── conejo_animation_view.dart  # Widget que lo centra y escala en pantallas Flutter
├── ui/
│   ├── menu_screen.dart       # Menu, selector de dificultad, conejo de bienvenida
│   ├── game_screen.dart       # Partida: HUD, reaccion al puntuar y panel de resultado
│   └── widgets/
│       ├── cute_button.dart   # Boton pastel
│       └── score_board.dart   # Marcador superior
assets/
├── fonts/                     # Fredoka (Regular, Medium, SemiBold, Bold)
└── images/                    # Sprite sheets del conejo
    ├── inicio.png             # 4 fotogramas de 202x184 (808x184)
    ├── losse.png              # 3 fotogramas de 178.6x176 (536x176)
    └── win.png                # 3 fotogramas de 188.6x190 (566x190)
test/
├── personajes_test.dart       # Dimensiones y troceado de los sprite sheets
├── render_conejo_test.dart    # Avance de fotograma y hueco reservado
├── fondo_y_centrado_test.dart # Fondo transparente y centrado con margen
├── animaciones_pantalla_test.dart  # Que animacion aparece en cada pantalla
├── bugfix_test.dart           # Regresiones de rebote, marcador y HUD
├── menu_test.dart             # Menu y ajuste a pantallas pequenas
├── menu_shift_test.dart       # El menu no se desplaza al abrir la partida
└── pong_test.dart             # Reglas, saque, colisiones y fin de partida
```

### Los personajes

El conejo se anima con `SpriteAnimationComponent`. Cada clase fija el tamano
exacto de un fotograma y el enum `ConejoAnimation` el numero de fotogramas y
la velocidad:

| Clase | PNG | Fotograma | Fotogramas |
| --- | --- | --- | --- |
| `ConejoInicio` | `inicio.png` | 202 x 184 | 4 |
| `ConejoLoss` | `losse.png` | 178.6 x 176 | 3 |
| `ConejoWin` | `win.png` | 188.6 x 190 | 3 |

Donde aparece cada uno:

- `inicio`: en el menu, entre el titulo y los botones.
- `win`: cada vez que anotas el usuario, y en el panel si ganas la partida.
- `losse`: cuando anota la IA, y en el panel si pierdes.

`ConejoAnimationView` los muestra dentro de una pantalla de Flutter normal
(que no son juegos de Flame) alojando el componente en un `FlameGame` minimo.
El hueco se reserva con `AspectRatio` y dentro el conejo se escala al mayor
tamano que cabe, dejando un margen del 15 % para que quede centrado sin tocar
los bordes. El mini juego tambien declara el fondo transparente, para que se
vea el degradado de la pantalla y no el rectangulo negro de Flame.

En los tests no se comparan pixeles: `toImage` sobre un `RepaintBoundary` que
contiene un `GameWidget` no captura el lienzo de Flame de forma fiable. Se
comprueba el estado del componente (posicion, tamano, fotograma activo) y el
alpha del fondo.

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
- El canvas de Flame es transparente: `PongGame.backgroundColor()` devuelve
  `0x00000000` y el `GameWidget` usa un `backgroundBuilder` vacio. El degradado
  pastel se pinta en el `Container` de `GameScreen`, igual que en el menu. Sin
  esto se ve el fondo negro que Flame pone por defecto.
- Las rutas de los sprite sheets son relativas (`inicio.png`, no
  `assets/images/inicio.png`) porque Flame antepone su prefijo por defecto
  `assets/images/` al pedir las imagenes.
- `ConejoPlayer` guarda el tamano intrinseco del fotograma aparte de `size`:
  `size` cambia al escalar el componente para ajustarlo a la pantalla y las
  medidas del sprite sheet no deben depender del zoom.
- El mini juego del conejo no espera a `world.add(bunny)`. La cola de ciclo de
  vida lavaciela el bucle del juego, y ese bucle no arranca hasta que `onLoad`
  termina: si se espera, el juego se queda bloqueado y el conejo nunca se
  pinta.
- `ConejoAnimationView` es un `StatefulWidget` que crea el juego una sola vez.
  Si el juego se construyera dentro de `build`, cada `setState` (al marcar un
  punto, por ejemplo) crearia uno nuevo y el conejo volveria al primer
  fotograma.
- El tamano del lienzo puede llegar antes de que termine de cargar el sprite,
  asi que la colocacion se repite en `render`: si no, el conejo se queda en el
  origen (0, 0) hasta el siguiente redimensionado.