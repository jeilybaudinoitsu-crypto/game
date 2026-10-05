import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../estetica/color.dart';
import '../game/game_config.dart';
import '../game/pong_game.dart';
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

  void _onGameOver(GameResult result) {
    if (!mounted) return;
    setState(() => _result = result);
  }

  /// El marcador del HUD se lee del juego, asi que hay que repintar cuando
  /// cambia. Sin esto el tablero se queda congelado en el marcador inicial.
  void _onScoreChanged(Score _) {
    if (!mounted) return;
    setState(() {});
  }

  void _restart() {
    setState(() => _result = null);
    _game.resetMatch();
  }

  @override
  Widget build(BuildContext context) {
    final finished = _result != null;

    return Scaffold(
      body: Stack(
        children: [
          // --- Juego ------------------------------------------------------
          Positioned.fill(
            child: GameWidget<PongGame>(
              game: _game,
              autofocus: true,
              // El canvas es transparente para que se vea el degradado pastel.
              backgroundBuilder: (context) => const ColoredBox(
                color: CuteTheme.background,
              ),
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
                        player2Label:
                            widget.mode == GameMode.vsAI ? 'IA' : 'Jugador 2',
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
    );
  }

  Widget _controlsHint() {
    if (usesKeyboard) {
      return widget.mode == GameMode.vsAI
          ? const CuteChip(label: 'W / S  ·  moverte', icon: Icons.keyboard_rounded)
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
                      Icon(
                        won
                            ? Icons.celebration_rounded
                            : Icons.sports_tennis_rounded,
                        size: compact ? 54 : 68,
                        color: CuteTheme.player1,
                      ),
                      const SizedBox(height: 6),
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