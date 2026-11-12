import 'package:flutter/foundation.dart';

import 'board_geometry.dart';
import 'move.dart';
import 'peg.dart';

/// Неизменяемое состояние игрового поля: массив из 49 позиций, из них
/// 33 игровые (в углах — всегда `null`). `null` в игровой ячейке = пустая.
///
/// Все ходы возвращают новый `Board` (copy-on-write), поэтому история ходов
/// хранит ссылки на прежние состояния и отмена хода — это просто сдвиг стека.
@immutable
final class Board {
  Board._(List<Peg?> cells, this.pegCount)
      : _cells = List<Peg?>.unmodifiable(cells),
        _view = List<Peg?>.unmodifiable(cells);

  /// Пустое поле (все ячейки свободны) — удобно для тестов и эндшпильных позиций.
  factory Board.empty() => Board._(List<Peg?>.filled(BoardGeometry.cellCount, null), 0);

  /// Поле с фишками в заданных ячейках (для эндшпилей, тестов и solver).
  factory Board.fromOccupied(Iterable<int> occupied) {
    final List<Peg?> cells = List<Peg?>.filled(BoardGeometry.cellCount, null);
    int nextId = 1;
    int count = 0;
    for (final int index in occupied) {
      if (BoardGeometry.isPlayableIndex(index) && cells[index] == null) {
        cells[index] = Peg(nextId++);
        count++;
      }
    }
    return Board._(cells, count);
  }

  /// Стартовая позиция «Тактики»: 32 фишки, центр (4,4) пуст.
  factory Board.initial() {
    final List<Peg?> cells = List<Peg?>.filled(BoardGeometry.cellCount, null);
    int nextId = 1;
    for (final int index in BoardGeometry.playableIndexes) {
      if (index == BoardGeometry.centerIndex) {
        continue;
      }
      cells[index] = Peg(nextId++);
    }
    return Board._(cells, BoardGeometry.playableCells - 1);
  }

  final List<Peg?> _cells;
  final List<Peg?> _view;

  /// Только для чтения; длина 49, индексы совпадают с позициями в стеке фишек.
  List<Peg?> get cells => _view;

  final int pegCount;

  Peg? pegAt(int index) => _cells[index];

  bool isEmptyAt(int index) => _cells[index] == null;

  bool isPlayable(int index) => BoardGeometry.isPlayableIndex(index);

  /// Все фишки поля вместе с их ячейками.
  Map<int, Peg> get pegByCell {
    final Map<int, Peg> result = <int, Peg>{};
    for (final int index in BoardGeometry.playableIndexes) {
      final Peg? peg = _cells[index];
      if (peg != null) {
        result[index] = peg;
      }
    }
    return result;
  }

  int? cellOf(int pegId) {
    for (final int index in BoardGeometry.playableIndexes) {
      if (_cells[index]?.id == pegId) {
        return index;
      }
    }
    return null;
  }

  /// Возможные прыжки данной фишки (проверка «через фишку на пустое»
  /// и только по вертикали/горизонтали).
  List<Move> movesFrom(int from) {
    final List<Move> result = <Move>[];
    if (!isPlayable(from) || isEmptyAt(from)) {
      return result;
    }
    final int row = BoardGeometry.rowOf(from);
    final int col = BoardGeometry.colOf(from);
    for (int d = 0; d < BoardGeometry.dRow.length; d++) {
      final int midRow = row + BoardGeometry.dRow[d];
      final int midCol = col + BoardGeometry.dCol[d];
      final int toRow = row + BoardGeometry.dRow[d] * 2;
      final int toCol = col + BoardGeometry.dCol[d] * 2;
      if (!BoardGeometry.inBounds(toRow, toCol) || !BoardGeometry.isPlayable(toRow, toCol)) {
        continue;
      }
      final int through = BoardGeometry.index(midRow, midCol);
      final int to = BoardGeometry.index(toRow, toCol);
      if (!isEmptyAt(through) && isEmptyAt(to)) {
        result.add(Move(from, through, to));
      }
    }
    return result;
  }

  List<Move> allMoves() {
    final List<Move> result = <Move>[];
    for (final int index in BoardGeometry.playableIndexes) {
      if (!isEmptyAt(index)) {
        result.addAll(movesFrom(index));
      }
    }
    return result;
  }

  bool get hasLegalMoves => allMoves().isNotEmpty;

  /// Индекс единственной оставшейся фишки, если она ровно одна, иначе null.
  int? get lonePegIndex {
    if (pegCount != 1) {
      return null;
    }
    for (final int index in BoardGeometry.playableIndexes) {
      if (!isEmptyAt(index)) {
        return index;
      }
    }
    return null;
  }

  bool isLegalMove(Move move) => movesFrom(move.from).contains(move);

  /// Проверка прыжка «из в» для жестов пользователя: тап по пустой клетке или
  /// перетаскивание. Возвращает готовый `Move`, если ход разрешён, иначе null.
  ///
  /// Фишки и цель должны лежать на одной прямой на расстоянии ровно 2 клетки,
  /// клетка между ними обязана быть занятой, цель — пустой и игровой.
  Move? jumpTo(int from, int to) {
    if (!isPlayable(from) || !isPlayable(to) || isEmptyAt(from) || !isEmptyAt(to)) {
      return null;
    }
    final int dRow = BoardGeometry.rowOf(to) - BoardGeometry.rowOf(from);
    final int dCol = BoardGeometry.colOf(to) - BoardGeometry.colOf(from);
    final bool straight = (dRow == 0 && dCol.abs() == 2) || (dCol == 0 && dRow.abs() == 2);
    if (!straight) {
      return null;
    }
    final int through =
        BoardGeometry.index(BoardGeometry.rowOf(from) + dRow ~/ 2, BoardGeometry.colOf(from) + dCol ~/ 2);
    if (isEmptyAt(through)) {
      return null;
    }
    final Move move = Move(from, through, to);
    return isLegalMove(move) ? move : null;
  }

  /// Применить прыжок: стартовая клетка пустеет, побитая фишка уходит,
  /// целевая занимает её (тот же id — ради плавной анимации перелёта).
  Board applyJump(Move move) {
    if (move.from == move.to ||
        isEmptyAt(move.from) ||
        isEmptyAt(move.through) ||
        !isEmptyAt(move.to) ||
        !isLegalMove(move)) {
      return this;
    }
    final List<Peg?> next = List<Peg?>.of(_cells);
    next[move.to] = Peg(next[move.from]!.id);
    next[move.from] = null;
    next[move.through] = null;
    return Board._(next, pegCount - 1);
  }

  @override
  bool operator ==(Object other) {
    if (other is! Board) {
      return false;
    }
    for (int i = 0; i < BoardGeometry.cellCount; i++) {
      if (_cells[i]?.id != other._cells[i]?.id) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(
      List<int>.generate(BoardGeometry.cellCount, (int i) => _cells[i]?.id ?? -1));

  /// ASCII-схема поля — удобна в логах и в текстах упавших тестов.
  @override
  String toString() {
    final StringBuffer buf = StringBuffer();
    for (int row = 0; row < BoardGeometry.size; row++) {
      for (int col = 0; col < BoardGeometry.size; col++) {
        if (!BoardGeometry.isPlayable(row, col)) {
          buf.write('  ');
          continue;
        }
        final int index = BoardGeometry.index(row, col);
        buf.write(isEmptyAt(index) ? ' . ' : ' O ');
      }
      buf.write('\n');
    }
    return buf.toString();
  }
}
