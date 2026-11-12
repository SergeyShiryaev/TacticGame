import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_controller.dart';
import '../../domain/game_result.dart';
import '../../domain/game_state.dart';
import '../../domain/game_store.dart';
import '../../domain/solver.dart';
import '../../l10n/app_strings.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import 'board_view.dart';

/// Экран партии: шапка со счётчиками, доска, действия.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.app});

  final AppController app;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _sheetShown = false;

  GameStore get _store => widget.app.game;

  @override
  void initState() {
    super.initState();
    _sheetShown = _store.isGameOver;
    _store.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (_store.isGameOver && !_sheetShown) {
      _sheetShown = true;
      // Даём доиграть анимацию последнего хода.
      Future<void>.delayed(const Duration(milliseconds: 450), () {
        if (mounted && _store.isGameOver) {
          _showGameOver();
        }
      });
    } else if (!_store.isGameOver) {
      _sheetShown = false;
    }
  }

  // --------------------------------------------------------------- действия ---

  Future<void> _restart() async {
    if (_store.state.movesMade > 0 && !_store.isGameOver) {
      final AppStrings s = AppStrings.of(context);
      final bool? ok = await showDialog<bool>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          title: Text(s.restartConfirmTitle),
          content: Text(s.restartConfirmBody),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(s.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(s.confirm),
            ),
          ],
        ),
      );
      if (ok != true) {
        return;
      }
    }
    _store.restart();
  }

  Future<void> _hint() async {
    final AppStrings s = AppStrings.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final HintResult? result = await _store.requestHint();
    if (!mounted || result == null) {
      return;
    }
    final String text = switch (result.status) {
      HintStatus.winning => s.hintWinning,
      HintStatus.noSolution => s.hintNoSolution,
      HintStatus.unknown => s.hintUnknown,
    };
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _showHelp() {
    final AppStrings s = AppStrings.of(context);
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(s.howToTitle),
        content: SingleChildScrollView(
          child: Text(s.howToBody, style: const TextStyle(height: 1.45)),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(s.howToClose),
          ),
        ],
      ),
    );
  }

  String _resultText(AppStrings s, GameResult result) => switch (result.grade) {
        GameGrade.perfectWin => s.resultPerfectWin,
        GameGrade.lonePegOffCenter => s.resultLonePeg,
        GameGrade.good => s.resultGood,
        GameGrade.deadEnd => s.resultDeadEnd,
      };

  void _showGameOver() {
    final AppStrings s = AppStrings.of(context);
    final GameState state = _store.state;
    final GameResult result = state.result!;
    final int? best = widget.app.stats.stats.bestPegsLeft;
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                s.gameOverTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              Text(
                _resultText(s, result),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, height: 1.35),
              ),
              const SizedBox(height: 12),
              Text(
                '${result.pegsLeft} ${s.pegCountLabel}   •   '
                '${s.moves}: ${result.movesMade}'
                '${best == null ? '' : '   •   ${s.statsBest}: $best'}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppPalette.accent),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  _store.restart();
                },
                child: Text(s.playAgain.toUpperCase()),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () async {
                  final ScaffoldMessengerState messenger =
                      ScaffoldMessenger.of(context);
                  await Clipboard.setData(ClipboardData(
                    text: s.shareText(result.pegsLeft, result.movesMade),
                  ));
                  messenger
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(content: Text(s.copied)));
                },
                child: Text(s.share),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).pop();
                },
                child: Text(s.backToMenu),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ build ---

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = widget.app.settings.reduceMotion ||
        MediaQuery.disableAnimationsOf(context);
    final Widget board = BoardView(
      store: _store,
      feedback: widget.app.feedback,
      reduceMotion: reduceMotion,
    );

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            final bool wide = c.maxWidth > c.maxHeight * 1.15;
            if (wide) {
              return Row(
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Center(
                        child: AspectRatio(aspectRatio: 1, child: board),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 320,
                    child: SingleChildScrollView(child: _controls(vertical: true)),
                  ),
                ],
              );
            }
            return Column(
              children: <Widget>[
                _controls(vertical: false),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: AspectRatio(aspectRatio: 1, child: board),
                      ),
                    ),
                  ),
                ),
                _hintLine(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _hintLine() {
    return ListenableBuilder(
      listenable: _store,
      builder: (BuildContext context, Widget? child) {
        final AppStrings s = AppStrings.of(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 2, 18, 14),
          child: Text(
            _store.isGameOver ? s.gameOverTitle : s.movesHint,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppPalette.textSoft,
              height: 1.35,
            ),
          ),
        );
      },
    );
  }

  Widget _controls({required bool vertical}) {
    return ListenableBuilder(
      listenable: _store,
      builder: (BuildContext context, Widget? child) {
        final AppStrings s = AppStrings.of(context);
        final GameState state = _store.state;
        final Widget title = Row(
          children: <Widget>[
            IconButton(
              tooltip: s.backToMenu,
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, color: AppPalette.accent),
            ),
            const Expanded(
              /*
              child: Text(
                s.appName.toUpperCase(),                
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                  color: AppPalette.accent,
                ),
              ),
              */
              child: SizedBox.shrink()
            ),
            StatChip(label: s.pegCountLabel, value: '${state.board.pegCount}'),
            const SizedBox(width: 8),
            StatChip(label: s.moves, value: '${state.movesMade}'),
          ],
        );
        final List<Widget> actions = <Widget>[
          ActionButton(
            icon: Icons.undo,
            label: s.undo,
            onPressed: _store.canUndo ? _store.undo : null,
          ),
          ActionButton(
            icon: Icons.redo,
            label: s.redo,
            onPressed: _store.canRedo ? _store.redo : null,
          ),
          ActionButton(
            icon: Icons.lightbulb_outline,
            label: s.hint,
            busy: _store.isHinting,
            onPressed: _store.isGameOver || _store.isHinting ? null : _hint,
          ),
          ActionButton(
            icon: Icons.restart_alt,
            label: s.restart,
            onPressed: _restart,
          ),
          ActionButton(
            icon: Icons.help_outline,
            label: s.help,
            onPressed: _showHelp,
          ),
        ];
        final Widget actionRow = Row(
          children: <Widget>[
            for (int i = 0; i < actions.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: 6),
              Expanded(child: actions[i]),
            ],
          ],
        );
        return Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              title,
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: actionRow,
              ),
              if (vertical) ...<Widget>[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    s.movesHint,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppPalette.textSoft,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
