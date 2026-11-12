import 'board.dart';
import 'board_geometry.dart';
import 'move.dart';

/// Итог поиска подсказки.
enum HintStatus {
  /// Найден ход, после которого победа (одна фишка) ещё достижима.
  winning,

  /// Поиск полностью исчерпан: из этой позиции победить нельзя.
  noSolution,

  /// Бюджет поиска закончился; ход подобран эвристически.
  unknown,
}

final class HintResult {
  const HintResult(this.status, [this.move]);

  final HintStatus status;
  final Move? move;

  /// Упаковка для передачи между изолятами.
  List<int> toList() => <int>[
        status.index,
        if (move != null) ...<int>[move!.from, move!.through, move!.to],
      ];

  factory HintResult.fromList(List<int> data) {
    final HintStatus status = HintStatus.values[data[0]];
    final Move? move =
        data.length >= 4 ? Move(data[1], data[2], data[3]) : null;
    return HintResult(status, move);
  }
}

/// Вход для `compute`: первый элемент — бюджет узлов, остальные — индексы
/// занятых клеток.
List<int> solveHintEntry(List<int> args) {
  final int budget = args[0];
  final Board board = Board.fromOccupied(args.sublist(1));
  return PegSolver(budget: budget).hint(board).toList();
}

/// Поиск решения с запоминанием тупиковых позиций.
///
/// Позиция хранится двумя целыми: младшие 32 бита и один старший. На вебе
/// побитовые операции работают только с 32 битами, поэтому 33 клетки в одно
/// число не помещаются.
class PegSolver {
  PegSolver({required this.budget});

  final int budget;

  static final List<int> _bitOfCell = _buildBitOfCell();
  static final List<_Jump> _jumps = _buildJumps();

  static List<int> _buildBitOfCell() {
    final List<int> result = List<int>.filled(BoardGeometry.cellCount, -1);
    int bit = 0;
    for (final int index in BoardGeometry.playableIndexes) {
      result[index] = bit++;
    }
    return result;
  }

  static List<_Jump> _buildJumps() {
    final List<_Jump> result = <_Jump>[];
    for (final int from in BoardGeometry.playableIndexes) {
      final int row = BoardGeometry.rowOf(from);
      final int col = BoardGeometry.colOf(from);
      for (int d = 0; d < BoardGeometry.dRow.length; d++) {
        final int toRow = row + BoardGeometry.dRow[d] * 2;
        final int toCol = col + BoardGeometry.dCol[d] * 2;
        if (!BoardGeometry.isPlayable(toRow, toCol)) {
          continue;
        }
        final int through = BoardGeometry.index(
          row + BoardGeometry.dRow[d],
          col + BoardGeometry.dCol[d],
        );
        result.add(_Jump(
          from,
          through,
          BoardGeometry.index(toRow, toCol),
          _bitOfCell[from],
          _bitOfCell[through],
          _bitOfCell[BoardGeometry.index(toRow, toCol)],
        ));
      }
    }
    return result;
  }

  final Set<int> _dead = <int>{};
  int _nodes = 0;
  bool _aborted = false;

  HintResult hint(Board board) {
    final List<int> occupied = <int>[
      for (final int index in BoardGeometry.playableIndexes)
        if (!board.isEmptyAt(index)) index,
    ];
    int lo = 0;
    int hi = 0;
    for (final int index in occupied) {
      final int bit = _bitOfCell[index];
      if (bit < 32) {
        lo |= 1 << bit;
      } else {
        hi |= 1 << (bit - 32);
      }
    }
    final int pegs = occupied.length;

    Move? fallback;
    for (final _Jump j in _jumps) {
      if (!j.canJump(lo, hi)) {
        continue;
      }
      final Move move = Move(j.from, j.through, j.to);
      fallback ??= move;
      final int nextLo = j.nextLo(lo);
      final int nextHi = j.nextHi(hi);
      if (_solve(nextLo, nextHi, pegs - 1)) {
        return HintResult(HintStatus.winning, move);
      }
      if (_aborted) {
        break;
      }
    }
    if (_aborted) {
      return HintResult(HintStatus.unknown, fallback);
    }
    return HintResult(HintStatus.noSolution, fallback);
  }

  bool _solve(int lo, int hi, int pegs) {
    if (pegs == 1) {
      return true;
    }
    final int key = hi * 4294967296 + lo;
    if (_dead.contains(key)) {
      return false;
    }
    if (++_nodes > budget) {
      _aborted = true;
      return false;
    }
    for (final _Jump j in _jumps) {
      if (!j.canJump(lo, hi)) {
        continue;
      }
      if (_solve(j.nextLo(lo), j.nextHi(hi), pegs - 1)) {
        return true;
      }
      if (_aborted) {
        return false;
      }
    }
    _dead.add(key);
    return false;
  }
}

final class _Jump {
  _Jump(this.from, this.through, this.to, int fromBit, int midBit, int toBit)
      : fromLo = fromBit < 32 ? 1 << fromBit : 0,
        fromHi = fromBit >= 32 ? 1 << (fromBit - 32) : 0,
        midLo = midBit < 32 ? 1 << midBit : 0,
        midHi = midBit >= 32 ? 1 << (midBit - 32) : 0,
        toLo = toBit < 32 ? 1 << toBit : 0,
        toHi = toBit >= 32 ? 1 << (toBit - 32) : 0;

  final int from;
  final int through;
  final int to;
  final int fromLo;
  final int fromHi;
  final int midLo;
  final int midHi;
  final int toLo;
  final int toHi;

  bool canJump(int lo, int hi) =>
      ((lo & fromLo) | (hi & fromHi)) != 0 &&
      ((lo & midLo) | (hi & midHi)) != 0 &&
      ((lo & toLo) | (hi & toHi)) == 0;

  int nextLo(int lo) => ((lo & ~fromLo & ~midLo) | toLo) & 0xFFFFFFFF;

  int nextHi(int hi) => (hi & ~fromHi & ~midHi) | toHi;
}
