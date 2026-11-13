import 'package:flutter_test/flutter_test.dart';
import 'package:tactics/domain/board.dart';
import 'package:tactics/domain/board_geometry.dart';
import 'package:tactics/domain/game_store.dart';
import 'package:tactics/domain/move.dart';

/// Индекс ячейки сетки 7x7 (row-major, шаг строки = 7).
int cell(int row, int col) => row * 7 + col;

void main() {
  group('Стартовая позиция', () {
    test('32 фишки, пустой центр (4,4) сетки 7x7', () {
      final Board b = Board.initial();
      expect(BoardGeometry.centerIndex, 24);
      expect(BoardGeometry.centerIndex, cell(3, 3)); // 1-е: строка 4, столбец 4
      expect(b.movesFrom(BoardGeometry.centerIndex), isEmpty,
          reason: 'из пустого центра нельзя ходить');

      int pegs = 0;
      for (final int index in BoardGeometry.playableIndexes) {
        // Фишка стоит везде, кроме центра: проверим ходом в центр.
        if (index == BoardGeometry.centerIndex) continue;
        final int dr = (BoardGeometry.rowOf(index) - 3).abs();
        final int dc = (index - BoardGeometry.rowOf(index) * 7 - 3).abs();
        if (dr == 2 && dc == 0) pegs += 1; //candidates above/below centre
        if (dr == 0 && dc == 2) pegs += 1;
      }
      expect(pegs, 4, reason: 'к центру ведут 4 прыжка (по 2 клетки)');
    });

    test('ход в центр из (1,3) — 10 -> 17 -> 24', () {
      final Board b = Board.initial();
      expect(b.movesFrom(cell(1, 3)), contains(Move(cell(1, 3), 17, 24)));
      expect(b.movesFrom(cell(3, 1)), contains(Move(cell(3, 1), 23, 24)));
    });
  });

  group('Правила прыжка', () {
    test('только вертикаль/горизонталь, ровно 2 клетки, по одной прямой', () {
      final Board b = Board.initial();
      for (final int index in BoardGeometry.playableIndexes) {
        for (final Move m in b.movesFrom(index)) {
          final int fr = BoardGeometry.rowOf(m.from);
          final int fc = m.from - fr * 7;
          final int tr = BoardGeometry.rowOf(m.to);
          final int tc = m.to - tr * 7;
          expect(fr * 7 + fc, m.from);
          expect(tr * 7 + tc, m.to);
          // Диагональ = обе разницы ненулевые. Запрещена.
          expect((tr - fr) * (tc - fc), 0,
              reason: '$m: ход по диагонали недопустим');
          expect((tr - fr).abs() + (tc - fc).abs(), 2,
              reason: '$m: прыжок ровно на 2 клетки');
          final int midRow = (fr + tr) ~/ 2;
          expect(m.through, midRow * 7 + (fc + tc) ~/ 2,
              reason: '$m: средняя ячейка на той же прямой между клетками');
        }
      }
    });

    test('в стартовой позиции ровно 4 первых хода', () {
      final Board b = Board.initial();
      int total = 0;
      for (final int index in BoardGeometry.playableIndexes) {
        total += b.movesFrom(index).length;
      }
      expect(total, 4);
    });
  });

  group('Ходы игрока через тапы', () {
    late GameStore store;
    setUp(() => store = GameStore());
    tearDown(() => store.dispose());

    test('первый тап выделяет фишку, второй — прыжок со снятием', () {
      store.tapCell(cell(1, 3));
      store.tapCell(24);
      expect(store.state.board.pegCount, 31, reason: 'взятие: -1 фишка');
      expect(store.state.movesMade, 1);
      expect(store.state.history, isNotEmpty);
    });

    test('нельзя прыгать через пустую клетку', () {
      store.tapCell(cell(3, 1)); // 22 -> 24 через 23
      store.tapCell(24);
      expect(store.state.board.pegCount, 31);
      // Теперь 22 и 23 пусты; из 21 через пустую 23 в пустую 23 нельзя.
      store.tapCell(cell(3, 0));
      store.tapCell(cell(3, 2));
      expect(store.state.board.pegCount, 31, reason: 'ход через пустоту запрещён');
      expect(store.state.movesMade, 1);
    });

    test('Undo возвращает снятую фишку и счётчик ходов', () {
      store.tapCell(cell(1, 3));
      store.tapCell(24);
      expect(store.state.board.pegCount, 31);
      store.undo();
      expect(store.state.board.pegCount, 32);
      expect(store.state.movesMade, 0);
      expect(store.state.history, isEmpty);
      // Поле снова стартовое: те же 4 первых хода.
      int total = 0;
      for (final int index in BoardGeometry.playableIndexes) {
        total += store.state.board.movesFrom(index).length;
      }
      expect(total, 4);
    });

    test('Restart сбрасывает поле к 32 фишкам', () {
      store.tapCell(cell(1, 3));
      store.tapCell(24);
      store.restart();
      expect(store.state.board.pegCount, 32);
      expect(store.state.movesMade, 0);
      expect(store.state.history, isEmpty);
    });
  });

  group('Что именно меняет расстановку фишек', () {
    // UI по этим сигналам решает, анимировать ли переезд. Если бы Undo или
    // Restart считались «ходом», на экран лег бы перелёт всех затронутых
    // фишек разом — то самое «дёргается всё поле».
    late GameStore store;
    setUp(() => store = GameStore());
    tearDown(() => store.dispose());

    test('ход: расстановка меняется и её надо анимировать', () {
      expect(store.layoutTick, 0);
      expect(store.layoutShouldAnimate, isFalse,
          reason: 'до первого хода анимировать нечего');
      store.tapCell(cell(1, 3));
      expect(store.layoutTick, 0, reason: 'выделение не меняет состав поля');
      store.tapCell(24);
      expect(store.layoutTick, 1);
      expect(store.layoutShouldAnimate, isTrue);
    });

    test('Undo: расстановка меняется, но не анимируется', () {
      store.tapCell(cell(1, 3));
      store.tapCell(24);
      expect(store.layoutShouldAnimate, isTrue);
      store.undo();
      expect(store.layoutTick, 2, reason: 'счётчик считает и отмену');
      expect(store.layoutShouldAnimate, isFalse);
    });

    test('Restart: расстановка меняется, но не анимируется', () {
      store.tapCell(cell(1, 3));
      store.tapCell(24);
      store.restart();
      expect(store.layoutTick, 2);
      expect(store.layoutShouldAnimate, isFalse);
    });

    test('тихий тап по пустой клетке расстановку не считает', () {
      store.tapCell(BoardGeometry.centerIndex);
      store.tapCell(cell(0, 0));
      expect(store.layoutTick, 0);
      expect(store.layoutShouldAnimate, isFalse);
    });
  });
}
