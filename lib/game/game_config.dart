/// Modo de juego elegido desde el menu.
enum GameMode {
  /// Un jugador contra la computadora.
  vsAI,

  /// Dos personas en el mismo dispositivo.
  vsFriend,
}

/// Dificultad de la IA (solo aplica en [GameMode.vsAI]).
enum Difficulty {
  facil('Fácil'),
  medio('Media'),
  dificil('Difícil');

  const Difficulty(this.label);

  final String label;

  /// Cada cuanto decide la IA (en segundos). Menos tiempo = mas dificil.
  double get reactionInterval => switch (this) {
        Difficulty.facil => 0.30,
        Difficulty.medio => 0.17,
        Difficulty.dificil => 0.07,
      };

  /// Multiplicador de velocidad de la raqueta de la IA.
  double get speedFactor => switch (this) {
        Difficulty.facil => 0.42,
        Difficulty.medio => 0.62,
        Difficulty.dificil => 0.82,
      };

  /// Probabilidad de que la IA cometa un error de punteria.
  double get mistakeChance => switch (this) {
        Difficulty.facil => 0.40,
        Difficulty.medio => 0.14,
        Difficulty.dificil => 0.0,
      };

  /// Desvio maximo (en fraction de la altura del campo) al fallar.
  double get mistakeRange => switch (this) {
        Difficulty.facil => 0.10,
        Difficulty.medio => 0.04,
        Difficulty.dificil => 0.0,
      };

  /// Ruido siempre presente al predecir (fraccion de la altura del campo).
  /// Evita que la IA se vea mecanica.
  double get predictionJitter => switch (this) {
        Difficulty.facil => 0.05,
        Difficulty.medio => 0.02,
        Difficulty.dificil => 0.0,
      };
}

/// Ajuste global de la partida.
///
/// Las medidas de la cancha se calculan en tiempo de ejecucion a partir del
/// tamano real de la pantalla, para que el juego se vea igual en un movil
/// vertical, un movil horizontal o una pantalla de escritorio.
class GameConfig {
  GameConfig._();

  /// Puntos necesarios para ganar.
  static const int pointsToWin = 7;

  /// Altura de la raqueta como fraccion de la altura del campo.
  static const double paddleHeightRatio = 0.17;

  /// Limites de la raqueta en pixeles, para que se vea igual en cualquier
  /// pantalla y siga siendo comoda con el dedo.
  static const double paddleMinHeight = 74;
  static const double paddleMaxHeight = 150;

  /// Proporcion de la raqueta (ancho / alto).
  static const double paddleWidthRatio = 0.26;

  /// Radio de la pelota como fraccion de la altura del campo.
  static const double ballRadiusRatio = 0.021;
  static const double ballMinRadius = 7;
  static const double ballMaxRadius = 16;

  /// Velocidad inicial de la pelota en multiplos de la altura del campo/s.
  static const double ballSpeedRatio = 0.58;

  /// Velocidad de las raquetas en multiplos de la altura del campo/s.
  static const double paddleSpeedRatio = 0.85;

  /// Cuanto acelera la pelota en cada golpe (multiplicador acumulable).
  static const double ballSpeedUp = 1.045;

  /// Tope de aceleracion de la pelota.
  static const double ballMaxSpeedUp = 1.75;

  /// Distancia lateral de las raquetas respecto al borde (fraccion del ancho).
  static const double paddleMarginRatio = 0.055;

  /// Angle maximo (radianes) que puede tomar la pelota al salir de la raqueta.
  static const double maxBounceAngle = 0.85;

  /// Fraccion del semiancho de la raqueta considerada "zona dulce".
  static const double sweetSpotRatio = 0.18;

  /// Segundos que dura el aviso "Preparados" antes de sacar.
  static const double countdownSeconds = 2.4;

  /// Margen extra en X que suma al area tactil de la raqueta.
  static const double dragHitSlop = 26;
}