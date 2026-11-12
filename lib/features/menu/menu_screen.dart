import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../domain/board.dart';
import '../../domain/board_geometry.dart';
import '../../l10n/app_strings.dart';
import '../../ui/board/board_metrics.dart';
import '../../ui/paint/peg_sprite.dart';
import '../../ui/paint/plate_painter.dart';
import '../../ui/theme.dart';
import '../game/game_screen.dart';
import '../settings/settings_screen.dart';
import '../stats/stats_screen.dart';

/// Главное меню: продолжить, новая игра, статистика, настройки.
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key, required this.app});

  final AppController app;

  Future<void> _play(BuildContext context, {required bool resume}) async {
    app.openGame(resume: resume);
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => GameScreen(app: app)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: app,
          builder: (BuildContext context, Widget? child) {
            final AppStrings s = AppStrings.of(context);
            final int savedMoves = (app.hasSavedGame ? app.savedMovesCount : 0);
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        s.appName.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 8,
                          color: AppPalette.accent,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        s.tagline,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppPalette.textSoft),
                      ),
                      const SizedBox(height: 24),
                      ExcludeSemantics(
                        child: SizedBox(
                          height: 220,
                          child: CustomPaint(painter: _PreviewPainter()),
                        ),
                      ),
                      const SizedBox(height: 28),
                      if (app.hasSavedGame) ...<Widget>[
                        FilledButton(
                          onPressed: () => _play(context, resume: true),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(s.menuContinue.toUpperCase()),
                              Text(
                                s.continueInfo(32 - savedMoves, savedMoves),
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: () => _play(context, resume: false),
                          child: Text(s.menuNewGame),
                        ),
                      ] else
                        FilledButton(
                          onPressed: () => _play(context, resume: false),
                          child: Text(s.menuNewGame.toUpperCase()),
                        ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => StatsScreen(controller: app.stats),
                          ),
                        ),
                        child: Text(s.menuStats),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                SettingsScreen(controller: app.settings),
                          ),
                        ),
                        child: Text(s.menuSettings),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Декоративное стартовое поле для меню.
class _PreviewPainter extends CustomPainter {
  final PegSpriteCache _sprites = PegSpriteCache();
  final Board _board = Board.initial();

  @override
  void paint(Canvas canvas, Size size) {
    final double side = size.shortestSide;
    final BoardMetrics metrics = BoardMetrics(Size(side, side));
    canvas.save();
    canvas.translate((size.width - side) / 2, 0);
    BoardPlatePainter(metrics).paint(canvas, Size(side, side));
    for (final int index in BoardGeometry.playableIndexes) {
      if (!_board.isEmptyAt(index)) {
        _sprites.paint(canvas, metrics.centerOf(index), metrics.pegDiameter);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PreviewPainter oldDelegate) => false;
}
