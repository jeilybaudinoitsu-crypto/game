import 'package:flutter/material.dart';

import '../../estetica/color.dart';

/// Marcador superior: muestra los puntos de cada jugador.
///
/// El conejo de la partida es quien canta el marcador; aqui solo se ve el
/// numero, junto al color de cada raqueta.
class ScoreBoard extends StatelessWidget {
  const ScoreBoard({
    super.key,
    required this.player1Score,
    required this.player2Score,
    required this.pointsToWin,
    this.player2Label = 'Jugador 2',
  });

  final int player1Score;
  final int player2Score;
  final int pointsToWin;
  final String player2Label;

  @override
  Widget build(BuildContext context) {
    // En pantallas estrechas los dos lados no caben con la tipografia completa,
    // asi que el separador y el padding se encogen. Sin esto el `Row` se pasa
    // de ancho y Flutter pinta la franja de "overflowed by N pixels".
    final anchoEstrecho = MediaQuery.sizeOf(context).width < 400;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ScorePill(
          label: 'Jugador 1',
          score: player1Score,
          color: CuteTheme.player1,
          compact: anchoEstrecho,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: anchoEstrecho ? 4 : 10),
          child: Text(
            '·',
            style: CuteTheme.title(anchoEstrecho ? 18 : 22)
                .copyWith(color: CuteTheme.lilac),
          ),
        ),
        _ScorePill(
          label: player2Label,
          score: player2Score,
          color: CuteTheme.player2,
          alignEnd: true,
          compact: anchoEstrecho,
        ),
      ],
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({
    required this.label,
    required this.score,
    required this.color,
    this.alignEnd = false,
    this.compact = false,
  });

  final String label;
  final int score;
  final Color color;
  final bool alignEnd;

  /// Reduce margenes y numero cuando el marcador no cabe en pantalla.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 16,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: CuteTheme.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color, width: 2.5),
        boxShadow: const [
          BoxShadow(color: CuteTheme.shadow, offset: Offset(0, 3), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!alignEnd) ...[
            _Dot(color: color, small: compact),
            SizedBox(width: compact ? 6 : 10),
          ],
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CuteTheme.font(
                  size: compact ? 9 : 11,
                  weight: 6,
                  color: CuteTheme.ink,
                ),
              ),
              Text(
                '$score',
                maxLines: 1,
                style: CuteTheme.font(
                  size: compact ? 20 : 26,
                  weight: 7,
                  color: CuteTheme.text,
                ),
              ),
            ],
          ),
          if (alignEnd) ...[
            SizedBox(width: compact ? 6 : 10),
            _Dot(color: color, small: compact),
          ],
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, this.small = false});

  final Color color;

  /// Version reducida para pantallas estrechas.
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: small ? 10 : 14,
      height: small ? 10 : 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: CuteTheme.white, width: 2),
      ),
    );
  }
}