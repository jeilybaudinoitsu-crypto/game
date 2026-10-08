import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../estetica/color.dart';
import '../game/game_config.dart';
import '../personajes/conejo_animation_view.dart';
import '../personajes/conejo_player.dart';
import 'widgets/cute_button.dart';

/// Pantalla de inicio: elige entre jugar contra la IA o contra un amigo.
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key, required this.onStart});

  /// Se invoca con el modo y la dificultad elegidos.
  final void Function(GameMode mode, Difficulty difficulty) onStart;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  /// Desplazamiento propio del menu, para no depender del
  /// `PrimaryScrollController` (ver `build`).
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.height < 620;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: CuteTheme.backdrop),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                // `primary: false` + controlador propio: sin esto el
                // `SingleChildScrollView` se engancha al
                // `PrimaryScrollController`, que Flutter desplaza al dar
                // autofocus o al saltar entre pantallas. Ese salto es el
                // "la pantalla se mueve" al entrar en la partida.
                controller: _scroll,
                primary: false,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 16 : 28,
                      vertical: compact ? 10 : 24,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: compact ? 18 : 36),

                        // --- Titulo --------------------------------------
                        Text(
                          'Pin Pon Game',
                          textAlign: TextAlign.center,
                          style: CuteTheme.title(compact ? 34 : 44),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gana ${GameConfig.pointsToWin} puntos para ganar',
                          textAlign: TextAlign.center,
                          style: CuteTheme.font(
                            size: compact ? 13 : 15,
                            weight: 5,
                            color: CuteTheme.ink,
                          ),
                        ),

                        SizedBox(height: compact ? 18 : 34),

                        // --- Conejo de bienvenida (Centrado) -----------------
                        Transform.translate(
                          offset: const Offset(-100,-50), //desplaza el conejo hacia la izquierda derecha y hacia arriba o abajo
                          child: SizedBox(
                            height: (constraints.maxHeight * 0.26).clamp(
                              120.0,
                              240.0,
                            ),
                            width: double.infinity,
                            child: const ConejoAnimationView(
                              animation: ConejoAnimation.inicio,
                              widthFraction: 0.90, //ancho del conejo respecto al ancho de la pantalla
                              heightFraction: 0.90, //alto del conejo respecto al alto de la pantalla
                            ),
                          ),
                        ),

                        SizedBox(height: compact ? 14 : 24),

                        // --- Botones -------------------------------------
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Column(
                            children: [
                              CuteButton(
                                label: 'Jugar con la IA',
                                icon: Icons.smart_toy_rounded,
                                fontSize: compact ? 18 : 20,
                                onPressed: () => _pickDifficulty(),
                              ),
                              const SizedBox(height: 14),
                              CuteButton(
                                label: 'Jugar con un amigo',
                                icon: Icons.group_rounded,
                                gradient: CuteTheme.buttonGradientAlt,
                                fontSize: compact ? 18 : 20,
                                onPressed: () => widget.onStart(
                                  GameMode.vsFriend,
                                  Difficulty.medio,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: compact ? 18 : 34),

                        // --- Controles -----------------------------------
                        Text(
                          usesKeyboard
                              ? 'Jugador 1:  W / S      Jugador 2:  ↑ / ↓'
                              : 'Arrastra tu raqueta con el dedo',
                          textAlign: TextAlign.center,
                          style: CuteTheme.font(
                            size: 12,
                            weight: 5,
                            color: CuteTheme.ink.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Selector de dificultad (solo tiene sentido contra la IA).
  Future<void> _pickDifficulty() async {
    final difficulty = await showModalBottomSheet<Difficulty>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const _DifficultySheet(),
    );

    // Si el usuario cierra la hoja sin elegir, no se inicia la partida.
    if (difficulty != null && mounted) {
      widget.onStart(GameMode.vsAI, difficulty);
    }
  }
}

/// Hoja inferior con los tres niveles de dificultad.
class _DifficultySheet extends StatelessWidget {
  const _DifficultySheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
        decoration: BoxDecoration(
          gradient: CuteTheme.backdrop,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: CuteTheme.white, width: 3),
          boxShadow: const [
            BoxShadow(
              color: CuteTheme.shadow,
              offset: Offset(0, 6),
              blurRadius: 18,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Nivel de la IA', style: CuteTheme.title(24)),
            const SizedBox(height: 4),
            Text(
              'Elige cuánto difícil le va a ser a la IA',
              textAlign: TextAlign.center,
              style: CuteTheme.font(size: 13, weight: 5, color: CuteTheme.ink),
            ),
            const SizedBox(height: 18),
            for (final d in Difficulty.values) ...[
              _DifficultyOption(
                difficulty: d,
                onTap: () => Navigator.of(context).pop(d),
              ),
              const SizedBox(height: 10),
            ],
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: CuteTheme.font(
                  size: 14,
                  weight: 6,
                  color: CuteTheme.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DifficultyOption extends StatelessWidget {
  const _DifficultyOption({required this.difficulty, required this.onTap});

  final Difficulty difficulty;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CuteButton(
      label: difficulty.label,
      icon: _iconFor(difficulty),
      gradient: _gradientFor(difficulty),
      height: 52,
      fontSize: 18,
      onPressed: onTap,
    );
  }

  static IconData _iconFor(Difficulty d) => switch (d) {
    Difficulty.facil => Icons.emoji_emotions_rounded,
    Difficulty.medio => Icons.local_fire_department_rounded,
    Difficulty.dificil => Icons.whatshot_rounded,
  };

  static Gradient _gradientFor(Difficulty d) => switch (d) {
    Difficulty.facil => CuteTheme.buttonGradientAlt,
    Difficulty.medio => CuteTheme.buttonGradient,
    Difficulty.dificil => const LinearGradient(
      colors: [Color(0xFFE0BBE4), Color(0xFFC7CEEA)],
    ),
  };
}

/// `true` en Web y escritorio, donde las raquetas se controlan con el teclado.
bool get usesKeyboard =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.linux ||
    defaultTargetPlatform == TargetPlatform.macOS ||
    defaultTargetPlatform == TargetPlatform.windows;
