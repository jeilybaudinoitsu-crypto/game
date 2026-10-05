import 'package:flutter/material.dart';

/// Paleta y estilos compartidos del look "Cute & Pastel".
///
/// Se toma como referencia el resumen visual pedido:
/// fondo rosa pastel, raquetas en capsula (salmon / lila), pelota durazno,
/// red verde menta y tipografia redondeada (Fredoka).
class CuteTheme {
  CuteTheme._();

  // --- Paleta basica -------------------------------------------------------
  static const Color background = Color(0xFFFFF0F5); // Rosa pastel muy suave
  static const Color player1 = Color(0xFFFFB7B2); // Coral / Salmon pastel
  static const Color player2 = Color(0xFFC7CEEA); // Azul / Lila pastel
  static const Color ball = Color(0xFFFFDAC1); // Durazno pastel
  static const Color net = Color(0xFFE2F0CB); // Verde menta claro
  static const Color text = Color(0xFF8274EB); // Morado suave para textos

  // --- Paleta extendida ----------------------------------------------------
  static const Color player1Dark = Color(0xFFE8918C);
  static const Color player2Dark = Color(0xFF97A2D8);
  static const Color ballDark = Color(0xFFE8B394);
  static const Color white = Color(0xFFFFFFFF);
  static const Color cream = Color(0xFFFFF8F2);
  static const Color ink = Color(0xFF6B5E86); // Texto secundario
  static const Color mint = Color(0xFFB5E3B0);
  static const Color sky = Color(0xFFBDE0FE);
  static const Color lilac = Color(0xFFE0BBE4);
  static const Color shadow = Color(0x1A8274EB); // Sombra suave

  /// Degradado de fondo del menu / pantallas.
  static const LinearGradient backdrop = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFF6FA), Color(0xFFFFEAF3), Color(0xFFF3F0FF)],
  );

  /// Degradado de los botones primarios.
  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFC9C4), Color(0xFFFFB7B2)],
  );

  static const LinearGradient buttonGradientAlt = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD5DAF3), Color(0xFFC7CEEA)],
  );

  // --- Tipografia ----------------------------------------------------------
  static const String fontFamily = 'Fredoka';

  /// Estilo base redondeado. [weight] va de 1 a 7 y mapea al peso de Fredoka.
  static TextStyle font({
    double size = 16,
    int weight = 5,
    Color color = text,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: _fontWeight(weight),
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// Titulo grande del menu, con sombra suave para que "flote".
  static TextStyle title(double size) => font(
    size: size,
    weight: 7,
    color: text,
    letterSpacing: 1.2,
  ).copyWith(
    shadows: const [
      Shadow(color: Color(0x33FFFFFF), offset: Offset(0, 3), blurRadius: 0),
    ],
  );

  static FontWeight _fontWeight(int weight) => switch (weight) {
    <= 3 => FontWeight.w400,
    4 => FontWeight.w500,
    5 => FontWeight.w600,
    _ => FontWeight.w700,
  };
}