import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../core/game_feedback.dart';
import '../../domain/board_geometry.dart';
import '../../domain/game_state.dart';
import '../../domain/game_store.dart';
import '../../domain/move.dart';
import '../../domain/peg.dart';
import '../../l10n/app_strings.dart';
import '../../ui/board/board_metrics.dart';
import '../../ui/paint/peg_sprite.dart';
import '../../ui/paint/plate_painter.dart';
import 'board_painter.dart';
import 'board_scene.dart';

/// Доска: статичная пластина + один динамический слой (подсветки, фишки,
/// анимации) и жесты: тап, перетаскивание, клавиатура.
class BoardView extends StatefulWidget {
  const BoardView({
    super.key,
    required this.store,
    required this.feedback,
    required this.reduceMotion,
  });

  final GameStore store;
  final GameFeedback feedback;
  final bool reduceMotion;

  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView> with TickerProviderStateMixin {
  static const Duration _flightDuration = Duration(milliseconds: 260);
  static const Duration _returnDuration = Duration(milliseconds: 220);

  final BoardScene _scene = BoardScene();
  final PegSpriteCache _sprites = PegSpriteCache();
  final FocusNode _focus = FocusNode(debugLabel: 'board');

  late final AnimationController _flight;
  late final AnimationController _return;

  BoardMetrics _metrics = BoardMetrics(const Size(400, 400));
  int _tick = 0;
  bool _keyboardUsed = false;

  GameStore get _store => widget.store;

  @override
  void initState() {
    super.initState();
    _flight = AnimationController(vsync: this, duration: _flightDuration)
      ..addListener(() {
        _scene.flightT = Curves.easeOutCubic.transform(_flight.value);
        _scene.ghostT = _flight.value;
        _scene.repaint();
      })
      ..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          _clearFlight();
          _scene.repaint();
        }
      });
    _return = AnimationController(vsync: this, duration: _returnDuration)
      ..addListener(() {
        _scene.returnT = _return.value;
        _scene.repaint();
      })
      ..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          _scene
            ..dragPegId = null
            ..returnT = null
            ..repaint();
        }
      });
    _tick = _store.layoutTick;
    _store.addListener(_onStoreChanged);
  }

  @override
  void didUpdateWidget(BoardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store != widget.store) {
      oldWidget.store.removeListener(_onStoreChanged);
      widget.store.addListener(_onStoreChanged);
      _tick = widget.store.layoutTick;
      _clearFlight();
      _scene.dragPegId = null;
    }
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    _flight.dispose();
    _return.dispose();
    _focus.dispose();
    _sprites.dispose();
    _scene.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------- события ---

  void _onStoreChanged() {
    if (_store.layoutTick == _tick) {
      return; // выбор или подсказка: painter подписан на стор сам
    }
    _tick = _store.layoutTick;
    _clearFlight();
    _flight.stop();
    if (_store.layoutShouldAnimate && !widget.reduceMotion) {
      final ({Move move, int tick})? last = _store.lastMove;
      final Peg? landed =
          last == null ? null : _store.snapshot.pegByCell[last.move.to];
      if (last != null && landed != null) {
        _scene
          ..flyMove = last.move
          ..flyFrom = null
          ..flyPegId = landed.id
          ..ghostMove = last.move
          ..flightT = 0
          ..ghostT = 0;
        _flight.forward(from: 0);
      }
    }
    if (mounted) {
      setState(() {}); // новая версия семантики
    }
  }

  void _clearFlight() {
    _scene
      ..flyMove = null
      ..flyFrom = null
      ..flyPegId = 0
      ..ghostMove = null;
  }

  // ---------------------------------------------------------------- жесты ---

  void _tapCell(int index) {
    final int? before = _store.state.selectedPegId;
    final MoveAttempt attempt = _store.tapCell(index);
    if (attempt.isAccepted) {
      widget.feedback.move();
    } else if (attempt.isRejected) {
      widget.feedback.reject();
    } else if (_store.state.selectedPegId != null &&
        _store.state.selectedPegId != before) {
      widget.feedback.select();
    }
  }

  void _panStart(Offset local) {
    final int? cell = _metrics.cellAt(local);
    if (cell == null || _store.state.phase != GamePhase.playing) {
      return;
    }
    final Peg? peg = _store.state.board.pegAt(cell);
    if (peg == null) {
      return;
    }
    _return.stop();
    _scene
      ..returnT = null
      ..dragPegId = peg.id
      ..dragPos = local
      ..dragOrigin = _metrics.centerOf(cell)
      ..repaint();
    _store.selectPeg(peg.id);
    widget.feedback.select();
  }

  void _panUpdate(Offset local) {
    if (_scene.dragPegId == null) {
      return;
    }
    _scene
      ..dragPos = local
      ..repaint();
  }

  void _panEnd() {
    final int? id = _scene.dragPegId;
    if (id == null) {
      return;
    }
    final int target = _metrics.cellAt(_scene.dragPos) ?? -1;
    final MoveAttempt attempt = _store.dropPeg(pegId: id, toIndex: target);
    if (attempt.isRejected) {
      widget.feedback.reject();
      if (widget.reduceMotion) {
        _scene
          ..dragPegId = null
          ..repaint();
      } else {
        _return.forward(from: 0);
      }
      return;
    }
    if (attempt.isAccepted) {
      widget.feedback.move();
      if (_scene.flyMove == attempt.move) {
        // Полёт продолжается от точки броска, а не с прежней клетки.
        _scene.flyFrom = _scene.dragPos;
      }
    }
    _scene
      ..dragPegId = null
      ..repaint();
  }

  void _panCancel() {
    if (_scene.dragPegId != null) {
      _scene
        ..dragPegId = null
        ..returnT = null
        ..repaint();
    }
  }

  // ------------------------------------------------------------ клавиатура ---

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) {
      return KeyEventResult.ignored;
    }
    final LogicalKeyboardKey key = event.logicalKey;
    int dRow = 0;
    int dCol = 0;
    if (key == LogicalKeyboardKey.arrowUp) {
      dRow = -1;
    } else if (key == LogicalKeyboardKey.arrowDown) {
      dRow = 1;
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      dCol = -1;
    } else if (key == LogicalKeyboardKey.arrowRight) {
      dCol = 1;
    }
    if (dRow != 0 || dCol != 0) {
      _keyboardUsed = true;
      _moveCursor(dRow, dCol);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space) {
      final int? cursor = _scene.cursorCell;
      if (cursor != null) {
        _keyboardUsed = true;
        _tapCell(cursor);
        _scene.repaint();
        return KeyEventResult.handled;
      }
    }
    if (key == LogicalKeyboardKey.escape) {
      _store.clearSelection();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _moveCursor(int dRow, int dCol) {
    final int start = _scene.cursorCell ?? BoardGeometry.centerIndex;
    int row = BoardGeometry.rowOf(start);
    int col = BoardGeometry.colOf(start);
    if (_scene.cursorCell != null) {
      do {
        row += dRow;
        col += dCol;
      } while (BoardGeometry.inBounds(row, col) &&
          !BoardGeometry.isPlayable(row, col));
      if (!BoardGeometry.isPlayable(row, col)) {
        return;
      }
    }
    _scene
      ..cursorCell = BoardGeometry.index(row, col)
      ..repaint();
  }

  // ----------------------------------------------------------------- build ---

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double side =
            math.min(constraints.maxWidth, constraints.maxHeight);
        _metrics = BoardMetrics(Size(side, side));
        final Size size = Size(side, side);
        return Focus(
          focusNode: _focus,
          onKeyEvent: _onKey,
          onFocusChange: (bool _) => _scene.repaint(),
          child: SizedBox(
            width: side,
            height: side,
            child: Semantics(
              container: true,
              label: strings.semBoard(_store.snapshot.pegCount),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                dragStartBehavior: DragStartBehavior.down,
                onTapUp: (TapUpDetails d) {
                  _focus.requestFocus();
                  final int? cell = _metrics.cellAt(d.localPosition);
                  if (cell != null) {
                    _tapCell(cell);
                  }
                },
                onPanStart: (DragStartDetails d) => _panStart(d.localPosition),
                onPanUpdate: (DragUpdateDetails d) =>
                    _panUpdate(d.localPosition),
                onPanEnd: (DragEndDetails _) => _panEnd(),
                onPanCancel: _panCancel,
                child: Stack(
                  children: <Widget>[
                    RepaintBoundary(
                      child: CustomPaint(
                        size: size,
                        painter: BoardPlatePainter(_metrics),
                      ),
                    ),
                    RepaintBoundary(
                      child: CustomPaint(
                        size: size,
                        painter: BoardPainter(
                          store: _store,
                          scene: _scene,
                          metrics: _metrics,
                          sprites: _sprites,
                          strings: strings,
                          textDirection: Directionality.of(context),
                          onCellTap: _tapCell,
                          cursorVisible: () => _keyboardUsed && _focus.hasFocus,
                          layoutTick: _tick,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
