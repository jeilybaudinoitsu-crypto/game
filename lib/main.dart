import 'package:flutter/material.dart';

import 'estetica/color.dart';
import 'game/game_config.dart';
import 'ui/game_screen.dart';
import 'ui/menu_screen.dart';

void main() => runApp(const PinPonApp());

class PinPonApp extends StatelessWidget {
  const PinPonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pin Pon Cute',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const MenuScreenHost(),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: CuteTheme.fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: CuteTheme.player1,
        surface: CuteTheme.background,
      ),
      scaffoldBackgroundColor: CuteTheme.background,
      textTheme: Typography.material2021().black.apply(
        fontFamily: CuteTheme.fontFamily,
        bodyColor: CuteTheme.text,
        displayColor: CuteTheme.text,
      ),
    );
  }
}

/// Aloja la navegacion entre el menu y la partida.
class MenuScreenHost extends StatefulWidget {
  const MenuScreenHost({super.key});

  @override
  State<MenuScreenHost> createState() => _MenuScreenHostState();
}

class _MenuScreenHostState extends State<MenuScreenHost> {
  ({GameMode mode, Difficulty difficulty})? _match;

  void _start(GameMode mode, Difficulty difficulty) {
    setState(() => _match = (mode: mode, difficulty: difficulty));
  }

  void _backToMenu() {
    setState(() => _match = null);
  }

  @override
  Widget build(BuildContext context) {
    final match = _match;

    if (match == null) {
      return MenuScreen(onStart: _start);
    }

    return GameScreen(
      key: ValueKey('${match.mode}-${match.difficulty}'),
      mode: match.mode,
      difficulty: match.difficulty,
      onExit: _backToMenu,
    );
  }
}
