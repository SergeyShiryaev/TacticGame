import 'package:flutter/foundation.dart';

import 'board.dart';
import 'game_result.dart';
import 'move.dart';
import 'peg.dart';

/// Снимок поля для отрисовки. Пересоздаётся только при реальном изменении
/// состава поля или выбора, поэтому слой отрисовки может сравнивать снимки
/// по ссылке.
@immutable
final class BoardSnapshot {
  BoardSnapshot({
    required this.pegCount,
    required Map<int, Peg> pegByCell,
    required Set<int> emptyTargets,
    required Set<int> captureCells,
  })  : pegByCell = Map<int, Peg>.unmodifiable(pegByCell),
        emptyTargets = Set<int>.unmodifiable(emptyTargets),
        captureCells = Set<int>.unmodifiable(captureCells);

  final int pegCount;

  /// Ячейка -> фишка. Только реально стоящие на поле фишки.
  final Map<int, Peg> pegByCell;

  /// Клетки, куда может прыгнуть выбранная фишка.
  final Set<int> emptyTargets;

  /// Клетки с фишками, которые выбранная фишка может побить.
  final Set<int> captureCells;
}

/// Запись истории: состояние «до» и сам ход.
@immutable
final class HistoryEntry {
  const HistoryEntry({required this.before, required this.move});

  final Board before;
  final Move move;
}

enum GamePhase { playing, over }

/// Неизменяемое состояние всей сессии. Стор (`GameStore`) меняет только
/// ссылки на этот объект.
@immutable
final class GameState {
  const GameState({
    required this.board,
    required this.selectedPegId,
    required this.history,
    required this.movesMade,
    required this.phase,
    required this.result,
  });

  final Board board;

  /// Фишка, выбранная тапом. null — выбора нет.
  final int? selectedPegId;

  final List<HistoryEntry> history;
  final int movesMade;
  final GamePhase phase;
  final GameResult? result;

  bool get canUndo => history.isNotEmpty;

  int? get selectedCell =>
      selectedPegId == null ? null : board.cellOf(selectedPegId!);

  GameState copyWith({
    int? selectedPegId,
    bool clearSelection = false,
  }) =>
      GameState(
        board: board,
        selectedPegId:
            clearSelection ? null : (selectedPegId ?? this.selectedPegId),
        history: history,
        movesMade: movesMade,
        phase: phase,
        result: result,
      );
}
