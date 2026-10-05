import 'package:flutter/material.dart';

import 'estetica/color.dart';
import 'game/game_config.dart';
import 'mascota/bunny_sprites_scope.dart';
import 'mascota/conejo_mascota.dart';
import 'ui/game_screen.dart';
import 'ui/menu_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Los sprites del conejo se cargan una sola vez y se comparten con el menu y
  // las partidas mediante `BunnySpritesScope`.
  final sprites = await BunnySprites.load();

  runApp(PinPonApp(sprites: sprites));
}

class PinPonApp extends StatelessWidget {
  const PinPonApp({super.key, required this.sprites});

  final BunnySprites sprites;

  @override
  Widget build(BuildContext context) {
    return BunnySpritesScope(
      sprites: sprites,
      child: MaterialApp(
        title: 'Pin Pon Cute',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: const MenuScreenHost(),
      ),
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
