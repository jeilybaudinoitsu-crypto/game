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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ScorePill(
          label: 'Jugador 1',
          score: player1Score,
          color: CuteTheme.player1,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            '·',
            style: CuteTheme.title(22).copyWith(color: CuteTheme.lilac),
          ),
        ),
        _ScorePill(
          label: player2Label,
          score: player2Score,
          color: CuteTheme.player2,
          alignEnd: true,
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
  });

  final String label;
  final int score;
  final Color color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            _Dot(color: color),
            const SizedBox(width: 10),
          ],
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: CuteTheme.font(size: 11, weight: 6, color: CuteTheme.ink),
              ),
              Text(
                '$score',
                style: CuteTheme.font(
                  size: 26,
                  weight: 7,
                  color: CuteTheme.text,
                ),
              ),
            ],
          ),
          if (alignEnd) ...[
            const SizedBox(width: 10),
            _Dot(color: color),
          ],
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: CuteTheme.white, width: 2),
      ),
    );
  }
}