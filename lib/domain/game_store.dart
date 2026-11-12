import 'package:flutter/foundation.dart';

import 'board.dart';
import 'game_result.dart';
import 'game_state.dart';
import 'move.dart';
import 'peg.dart';
import 'solver.dart';

/// Результат попытки хода для UI: либо ход прошёл, либо его надо вернуть
/// анимацией «отмены» на исходную клетку.
@immutable
final class MoveAttempt {
  const MoveAttempt._({this.move, this.rejectedPegId, this.rejectedCell});

  factory MoveAttempt.accepted(Move move) => MoveAttempt._(move: move);

  /// Ход запрещён: фишку `rejectedPegId` бросают в клетку `rejectedCell`.
  factory MoveAttempt.rejected({required int pegId, required int cell}) =>
      MoveAttempt._(rejectedPegId: pegId, rejectedCell: cell);

  factory MoveAttempt.none() => const MoveAttempt._();

  final Move? move;
  final int? rejectedPegId;
  final int? rejectedCell;

  bool get isAccepted => move != null;
  bool get isRejected => rejectedPegId != null && rejectedCell != null;
}

/// Стор игры на `ChangeNotifier` + immutable-состояние.
///
/// Стор — единственный источник правды: в нём состояние, история отмен и
/// повторов, подсказка и снимок поля для отрисовки.
class GameStore extends ChangeNotifier {
  /// [savedMoves] — партия, сохранённая как плоский список пар `from, to`.
  GameStore({List<int>? savedMoves, Board? board})
      : _startBoard = board ?? Board.initial() {
    state = _stateFor(_startBoard, const <HistoryEntry>[], 0);
    if (savedMoves != null && savedMoves.isNotEmpty) {
      _restore(savedMoves);
    }
    _recomputeViews();
  }

  final Board _startBoard;

  late GameState state;

  BoardSnapshot _snapshot = BoardSnapshot(
    pegCount: 0,
    pegByCell: const <int, Peg>{},
    emptyTargets: const <int>{},
    captureCells: const <int>{},
  );

  BoardSnapshot get snapshot => _snapshot;

  final List<Move> _redo = <Move>[];

  // ------------------------------------------------- события для анимаций ---

  Move? _lastMoveEvent;
  int _lastMoveTick = 0;
  int _lastRejectTick = 0;
  ({int pegId, int cell})? _lastRejectEvent;
  int _layoutTick = 0;
  bool _layoutAnimated = false;

  /// Монотонный счётчик любой смены состава поля: ход, отмена, повтор, рестарт.
  int get layoutTick => _layoutTick;

  /// True только для смены, вызванной ходом: её надо показать перелётом одной
  /// фишки. Отмена, повтор и рестарт меняют расстановку мгновенно.
  bool get layoutShouldAnimate => _layoutAnimated;

  /// Последний сыгранный ход вместе с монотонным тиком.
  ({Move move, int tick})? get lastMove =>
      _lastMoveTick == 0 ? null : (move: _lastMoveEvent!, tick: _lastMoveTick);

  /// Последний отвергнутый ход.
  ({int pegId, int cell, int tick})? get lastReject => _lastRejectTick == 0
      ? null
      : (
          pegId: _lastRejectEvent!.pegId,
          cell: _lastRejectEvent!.cell,
          tick: _lastRejectTick,
        );

  int get lastMoveTick => _lastMoveTick;
  int get lastRejectTick => _lastRejectTick;

  bool get isGameOver => state.phase == GamePhase.over;
  bool get canUndo => state.canUndo;
  bool get canRedo => _redo.isNotEmpty;

  /// Партия как плоский список пар `from, to` — для сохранения.
  List<int> get movesFlat => <int>[
        for (final HistoryEntry entry in state.history) ...<int>[
          entry.move.from,
          entry.move.to,
        ],
      ];

  // ------------------------------------------------------------ подсказка ---

  Move? _hint;
  HintStatus? _hintStatus;
  bool _hinting = false;
  int _hintToken = 0;

  Move? get hint => _hint;
  HintStatus? get hintStatus => _hintStatus;
  bool get isHinting => _hinting;

  /// Ищет подсказку (в фоне) и выставляет `hint`. Возвращает итог поиска.
  Future<HintResult?> requestHint() async {
    if (state.phase != GamePhase.playing || _hinting) {
      return null;
    }
    _hinting = true;
    final int token = ++_hintToken;
    notifyListeners();

    final Board board = state.board;
    final List<int> args = <int>[
      kIsWeb ? 150000 : 3000000,
      for (final int cell in board.pegByCell.keys) cell,
    ];
    final List<int> raw = await compute<List<int>, List<int>>(
      solveHintEntry,
      args,
    );
    if (token != _hintToken) {
      return null; // позиция успела измениться
    }
    final HintResult result = HintResult.fromList(raw);
    _hinting = false;
    _hint = result.move;
    _hintStatus = result.status;
    notifyListeners();
    return result;
  }

  void _clearHint() {
    _hintToken++;
    _hint = null;
    _hintStatus = null;
    _hinting = false;
  }

  // ---------------------------------------------------------------- выбор ---

  /// Тап по клетке: занятая — выбирает фишку, пустая — пытается прыгнуть.
  MoveAttempt tapCell(int index) {
    if (state.phase != GamePhase.playing) {
      return MoveAttempt.none();
    }
    final Board board = state.board;
    final int? selectedCell = state.selectedCell;

    if (board.isPlayable(index) && !board.isEmptyAt(index)) {
      if (selectedCell == index) {
        _select(null);
        return MoveAttempt.none();
      }
      _select(board.pegAt(index)!.id);
      return MoveAttempt.none();
    }

    if (selectedCell == null) {
      return MoveAttempt.none();
    }

    final int pegId = state.selectedPegId!;
    final Move? move = board.jumpTo(selectedCell, index);
    if (move == null) {
      _select(null);
      _noteReject(pegId, index);
      return MoveAttempt.rejected(pegId: pegId, cell: index);
    }
    return _play(move);
  }

  /// Выбор фишки для подсветки доступных ходов. `id == null` снимает выбор.
  void selectPeg(int? id) {
    if (state.selectedPegId == id) {
      return;
    }
    _select(id);
  }

  void _select(int? pegId) {
    if (state.selectedPegId == pegId) {
      return;
    }
    state = pegId == null
        ? state.copyWith(clearSelection: true)
        : state.copyWith(selectedPegId: pegId);
    _recomputeViews();
    notifyListeners();
  }

  void clearSelection() => _select(null);

  // ------------------------------------------------------- drag-and-drop ---

  /// Фишку `pegId` отпустили над клеткой `toIndex`.
  MoveAttempt dropPeg({required int pegId, required int toIndex}) {
    if (state.phase != GamePhase.playing) {
      return MoveAttempt.none();
    }
    final int? fromCell = state.board.cellOf(pegId);
    if (fromCell == null) {
      return MoveAttempt.none();
    }
    final Move? move = state.board.jumpTo(fromCell, toIndex);
    if (move == null) {
      _noteReject(pegId, toIndex);
      notifyListeners();
      return MoveAttempt.rejected(pegId: pegId, cell: toIndex);
    }
    return _play(move);
  }

  void _noteReject(int pegId, int cell) {
    _lastRejectEvent = (pegId: pegId, cell: cell);
    _lastRejectTick++;
  }

  // ---------------------------------------------------------------- ходы ---

  GameState _stateFor(
    Board board,
    List<HistoryEntry> history,
    int movesMade,
  ) {
    final bool finished = !board.hasLegalMoves;
    return GameState(
      board: board,
      selectedPegId: null,
      history: List<HistoryEntry>.unmodifiable(history),
      movesMade: movesMade,
      phase: finished ? GamePhase.over : GamePhase.playing,
      result: finished
          ? GameResult(
              pegsLeft: board.pegCount,
              movesMade: movesMade,
              lonePegIndex: board.lonePegIndex,
            )
          : null,
    );
  }

  MoveAttempt _play(Move move, {bool fromRedo = false}) {
    if (!state.board.isLegalMove(move)) {
      return MoveAttempt.none();
    }
    final Board before = state.board;
    final Board after = before.applyJump(move);
    state = _stateFor(
      after,
      <HistoryEntry>[...state.history, HistoryEntry(before: before, move: move)],
      state.movesMade + 1,
    );
    if (!fromRedo) {
      _redo.clear();
    }
    _clearHint();
    _lastMoveEvent = move;
    _lastMoveTick++;
    _noteLayout(animated: true);
    _recomputeViews();
    notifyListeners();
    return MoveAttempt.accepted(move);
  }

  /// Отмена последнего хода.
  bool undo() {
    if (state.history.isEmpty) {
      return false;
    }
    final HistoryEntry entry = state.history.last;
    _redo.add(entry.move);
    state = _stateFor(
      entry.before,
      state.history.sublist(0, state.history.length - 1),
      state.movesMade - 1,
    );
    _clearHint();
    _noteLayout(animated: false);
    _recomputeViews();
    notifyListeners();
    return true;
  }

  /// Повтор отменённого хода.
  bool redo() {
    if (_redo.isEmpty || state.phase != GamePhase.playing) {
      return false;
    }
    final Move move = _redo.removeLast();
    return _play(move, fromRedo: true).isAccepted;
  }

  /// Полный сброс к стартовой позиции.
  void restart() {
    _lastMoveTick = 0;
    _lastRejectTick = 0;
    _lastMoveEvent = null;
    _lastRejectEvent = null;
    _redo.clear();
    state = _stateFor(_startBoard, const <HistoryEntry>[], 0);
    _clearHint();
    _noteLayout(animated: false);
    _recomputeViews();
    notifyListeners();
  }

  void _restore(List<int> flat) {
    for (int i = 0; i + 1 < flat.length; i += 2) {
      final Move? move = state.board.jumpTo(flat[i], flat[i + 1]);
      if (move == null || state.phase != GamePhase.playing) {
        // Повреждённое сохранение: начинаем заново.
        state = _stateFor(_startBoard, const <HistoryEntry>[], 0);
        return;
      }
      final Board before = state.board;
      state = _stateFor(
        before.applyJump(move),
        <HistoryEntry>[
          ...state.history,
          HistoryEntry(before: before, move: move),
        ],
        state.movesMade + 1,
      );
    }
  }

  void _noteLayout({required bool animated}) {
    _layoutTick++;
    _layoutAnimated = animated;
  }

  // ------------------------------------------------------ производные данные ---

  void _recomputeViews() {
    final Board board = state.board;
    final Set<int> targets = <int>{};
    final Set<int> captures = <int>{};
    final int? selectedCell = state.selectedCell;
    if (selectedCell != null && state.phase == GamePhase.playing) {
      for (final Move move in board.movesFrom(selectedCell)) {
        targets.add(move.to);
        captures.add(move.through);
      }
    }
    _snapshot = BoardSnapshot(
      pegCount: board.pegCount,
      pegByCell: board.pegByCell,
      emptyTargets: targets,
      captureCells: captures,
    );
  }
}
