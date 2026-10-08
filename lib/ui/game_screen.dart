import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../estetica/color.dart';
import '../game/game_config.dart';
import '../game/pong_game.dart';
import '../personajes/conejo_animation_view.dart';
import '../personajes/conejo_player.dart';
import 'menu_screen.dart';
import 'widgets/cute_button.dart';
import 'widgets/score_board.dart';

/// Pantalla de partida: contiene el juego de Flame y la interfaz encima.
///
/// - Android/iOS: se arrastra la raqueta con el dedo.
/// - Web/escritorio: jugador 1 con `W`/`S`, jugador 2 con las flechas
///   (`\x1b[A` arriba, `\x1b[B` abajo).
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.mode,
    required this.difficulty,
    required this.onExit,
  });

  final GameMode mode;
  final Difficulty difficulty;

  /// Vuelve al menu.
  final VoidCallback onExit;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final PongGame _game;
  GameResult? _result;

  /// Animacion de reaction que se muestra al puntuar, o `null` si no hay
  /// ninguna activa. Ver [_celebrate].
  ConejoAnimation? _reaction;

  /// Marcador anterior, para detectar quien acaba de anotar.
  Score _lastScore = Score();

  /// Oculta la animacion de reaction pasado un momento.
  Timer? _reactionTimer;

  /// Tiempo que la animacion de reaction queda en pantalla.
  static const _reactionDuration = Duration(milliseconds: 1400);

  @override
  void initState() {
    super.initState();
    _game = PongGame(
      mode: widget.mode,
      difficulty: widget.difficulty,
      onGameOver: _onGameOver,
      onScoreChanged: _onScoreChanged,
    );
  }

  @override
  void dispose() {
    _reactionTimer?.cancel();
    super.dispose();
  }

  void _onGameOver(GameResult result) {
    if (!mounted) return;
    setState(() => _result = result);
  }

  /// El marcador del HUD se lee del juego, asi que hay que repintar cuando
  /// cambia. Sin esto el tablero se queda congelado en el marcador inicial.
  ///
  /// De paso detecta quien acaba de puntuar para lanzar la animacion del
  /// conejo: `win.png` si gana el jugador 1, `losse.png` si gana el 2.
  void _onScoreChanged(Score score) {
    if (!mounted) return;

    final wonPoint = score.player1 > _lastScore.player1;
    final lostPoint = score.player2 > _lastScore.player2;
    _lastScore = Score()
      ..player1 = score.player1
      ..player2 = score.player2;

    setState(() {
      // Al terminar la partida manda el panel de resultado, asi que aqui solo
      // se muestra mientras la partida sigue viva.
      if (wonPoint || lostPoint) {
        _celebrate(won: wonPoint);
      }
    });
  }

  /// Muestra la animacion del conejo durante [_reactionDuration].
  void _celebrate({required bool won}) {
    _reaction = won ? ConejoAnimation.win : ConejoAnimation.loss;
    _reactionTimer?.cancel();
    _reactionTimer = Timer(_reactionDuration, () {
      if (mounted) setState(() => _reaction = null);
    });
  }

  void _restart() {
    _reactionTimer?.cancel();
    setState(() {
      _result = null;
      _reaction = null;
      _lastScore = Score();
    });
    _game.resetMatch();
  }

  @override
  Widget build(BuildContext context) {
    final finished = _result != null;

    return Scaffold(
      // El degradado va aqui para que se vea a traves del canvas de Flame,
      // que es transparente: es el mismo fondo que el menu.
      body: Container(
        decoration: const BoxDecoration(gradient: CuteTheme.backdrop),
        child: Stack(
          children: [
            // --- Juego --------------------------------------------------
            Positioned.fill(
              child: GameWidget<PongGame>(
                game: _game,
                autofocus: true,
                // Sin fondo: el `GameWidget` no pinta nada, para que se vea el
                // degradado pastel del `Container` de abajo. Flame ya pinta
                // transparente por `backgroundColor()` en `PongGame`.
                backgroundBuilder: (context) => const SizedBox.shrink(),
              ),
            ),

            // --- Marcador (se oculta al terminar) ---------------------------
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              left: 0,
              right: 0,
              child: IgnorePointer(
                // Aparece y desaparece de golpe, sin fundido.
                child: finished
                    ? const SizedBox.shrink()
                    : Center(
                        child: ScoreBoard(
                          player1Score: _game.score.player1,
                          player2Score: _game.score.player2,
                          pointsToWin: GameConfig.pointsToWin,
                          player2Label: widget.mode == GameMode.vsAI
                              ? 'IA'
                              : 'Jugador 2',
                        ),
                      ),
              ),
            ),

            // --- Boton de menu ----------------------------------------------
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              left: 10,
              child: _CircleIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Volver al menu',
                onPressed: widget.onExit,
              ),
            ),

            // --- Pista de controles -----------------------------------------
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.paddingOf(context).bottom + 12,
              child: IgnorePointer(
                // Aparece y desaparece de golpe, sin fundido.
                child: finished
                    ? const SizedBox.shrink()
                    : Center(child: _controlsHint()),
              ),
            ),

            // --- Reaccion al puntuar (win / losse) --------------------------
            // Va en el centro y no bloquea los toques (`IgnorePointer`) para no
            // estorbar mientras la partida continua.
            if (!finished && _reaction != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.3,
                      width: double.infinity,
                      child: Transform.translate(
                        offset: const Offset(-80, -70),//posicion del conejo de reaccion al puntuar, se puede ajustar para que quede centrado
                        child: ConejoAnimationView(
                          animation: _reaction!,
                          widthFraction: 0.66,
                          heightFraction: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // --- Panel de resultado -----------------------------------------
            if (finished)
              _ResultOverlay(
                result: _result!,
                mode: widget.mode,
                onRestart: _restart,
                onExit: widget.onExit,
              ),
          ],
        ),
      ),
    );
  }

  Widget _controlsHint() {
    if (usesKeyboard) {
      return widget.mode == GameMode.vsAI
          ? const CuteChip(
              label: 'W / S  ·  moverte',
              icon: Icons.keyboard_rounded,
            )
          : const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CuteChip(label: 'W / S', icon: Icons.keyboard_rounded),
                SizedBox(width: 8),
                CuteChip(label: '↑ / ↓', icon: Icons.swap_vert_rounded),
              ],
            );
    }
    return const CuteChip(
      label: 'Arrastra tu raqueta',
      icon: Icons.touch_app_rounded,
    );
  }
}

/// Lado del marcador al que pertenece una puntuacion.
enum PlayerSlot { player1, player2 }

/// Panel modal con el resultado de la partida.
class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay({
    required this.result,
    required this.mode,
    required this.onRestart,
    required this.onExit,
  });

  final GameResult result;
  final GameMode mode;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  /// Titulo del panel segun quien gane y el modo de juego.
  ///
  /// En [GameMode.vsAI] el jugador 1 siempre es el usuario, asi que "ganaste"
  /// depende de el. En [GameMode.vsFriend] hay que nombrar al ganador.
  String _titleFor({required bool won}) {
    if (mode == GameMode.vsAI) {
      return won ? '¡Ganaste!' : '¡Buen intento!';
    }
    return won ? '¡Ganó Jugador 1!' : '¡Ganó Jugador 2!';
  }

  /// Nombre que se muestra sobre la puntuacion de [slot].
  String _labelFor(PlayerSlot slot) {
    final isPlayer1 = slot == PlayerSlot.player1;
    if (mode == GameMode.vsAI) return isPlayer1 ? 'Tú' : 'IA';
    return isPlayer1 ? 'Jugador 1' : 'Jugador 2';
  }

  @override
  Widget build(BuildContext context) {
    final won = result.player1Won;
    final compact = MediaQuery.sizeOf(context).height < 620;

    return Positioned.fill(
      child: Container(
        color: CuteTheme.background.withValues(alpha: 0.86),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  decoration: BoxDecoration(
                    color: CuteTheme.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: CuteTheme.white, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: CuteTheme.shadow,
                        offset: Offset(0, 8),
                        blurRadius: 22,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Conejo de victoria o derrota: el mismo criterio que
                      // el titulo, con la animacion de `win.png` cuando gana
                      // el jugador 1 y `losse.png` cuando gana el jugador 2.
                      SizedBox(
                        height: compact ? 150 : 210,
                        width: double.infinity,
                        child: Transform.translate(
                          offset: const Offset(-80, -70),
                          child: ConejoAnimationView(
                            animation: won
                                ? ConejoAnimation.win
                                : ConejoAnimation.loss,
                            widthFraction: 0.72,
                            heightFraction: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _titleFor(won: won),
                        style: CuteTheme.title(compact ? 26 : 32),
                      ),
                      const SizedBox(height: 8),
                      // Etiquetas sobre la linea: deja claro a quien pertenece
                      // cada numero, sobre todo en modo dos jugadores.
                      Text(
                        '${_labelFor(PlayerSlot.player1)}  ·  ${_labelFor(PlayerSlot.player2)}',
                        style: CuteTheme.font(
                          size: 13,
                          weight: 6,
                          color: CuteTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${result.player1Score}  —  ${result.player2Score}',
                        style: CuteTheme.font(
                          size: compact ? 26 : 32,
                          weight: 7,
                          color: CuteTheme.text,
                        ),
                      ),
                      const SizedBox(height: 18),
                      CuteButton(
                        label: 'Otra vez',
                        icon: Icons.replay_rounded,
                        onPressed: onRestart,
                      ),
                      const SizedBox(height: 10),
                      CuteButton(
                        label: 'Menu',
                        icon: Icons.home_rounded,
                        gradient: CuteTheme.buttonGradientAlt,
                        onPressed: onExit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Boton circular translucido para las esquinas.
class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: CuteTheme.white.withValues(alpha: 0.85),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: CuteTheme.text, size: 22),
          ),
        ),
      ),
    );
  }
}
