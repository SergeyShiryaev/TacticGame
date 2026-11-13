import 'package:flutter_test/flutter_test.dart';
import 'package:tactics/domain/board.dart';
import 'package:tactics/domain/game_result.dart';
import 'package:tactics/domain/game_store.dart';

int cell(int row, int col) => row * 7 + col;

void main() {
  group('Redo', () {
    late GameStore store;
    setUp(() => store = GameStore());
    tearDown(() => store.dispose());

    test('повтор возвращает отменённый ход', () {
      store.tapCell(cell(1, 3));
      store.tapCell(24);
      store.undo();
      expect(store.canRedo, isTrue);
      expect(store.redo(), isTrue);
      expect(store.state.board.pegCount, 31);
      expect(store.state.movesMade, 1);
      expect(store.canRedo, isFalse);
    });

    test('новый ход очищает стек повторов', () {
      store.tapCell(cell(1, 3));
      store.tapCell(24);
      store.undo();
      store.tapCell(cell(3, 1));
      store.tapCell(24);
      expect(store.canRedo, isFalse);
    });

    test('повтор — это ход: расстановка анимируется', () {
      store.tapCell(cell(1, 3));
      store.tapCell(24);
      store.undo();
      store.redo();
      expect(store.layoutShouldAnimate, isTrue);
    });

    test('рестарт очищает стек повторов', () {
      store.tapCell(cell(1, 3));
      store.tapCell(24);
      store.undo();
      store.restart();
      expect(store.canRedo, isFalse);
    });
  });

  group('Сохранение партии', () {
    test('movesFlat и восстановление дают ту же позицию', () {
      final GameStore a = GameStore();
      a.tapCell(cell(1, 3));
      a.tapCell(24);
      a.tapCell(cell(2, 3));
      a.tapCell(cell(0, 3)); // 17-? ход, если допустим; иначе игнорируется
      final List<int> saved = a.movesFlat;

      final GameStore b = GameStore(savedMoves: saved);
      expect(b.state.board, a.state.board);
      expect(b.state.movesMade, a.state.movesMade);
      expect(b.movesFlat, saved);
      a.dispose();
      b.dispose();
    });

    test('повреждённое сохранение даёт чистую партию', () {
      final GameStore store = GameStore(savedMoves: <int>[0, 1, 2, 3]);
      expect(store.state.movesMade, 0);
      expect(store.state.board.pegCount, 32);
      store.dispose();
    });

    test('восстановленная партия может быть отменена', () {
      final GameStore a = GameStore();
      a.tapCell(cell(1, 3));
      a.tapCell(24);
      final GameStore b = GameStore(savedMoves: a.movesFlat);
      expect(b.canUndo, isTrue);
      b.undo();
      expect(b.state.board.pegCount, 32);
      a.dispose();
      b.dispose();
    });
  });

  group('Конец партии', () {
    test('позиция без ходов сразу заканчивается', () {
      final GameStore store = GameStore(
        board: Board.fromOccupied(
          <int>[cell(0, 2), cell(0, 4), cell(6, 2), cell(6, 4)],
        ),
      );
      expect(store.isGameOver, isTrue);
      expect(store.state.result!.grade, GameGrade.deadEnd);
      store.dispose();
    });

    test('последний прыжок в центр — идеальная победа', () {
      final GameStore store = GameStore(
        board: Board.fromOccupied(<int>[cell(3, 1), cell(3, 2)]),
      );
      expect(store.isGameOver, isFalse);
      store.tapCell(cell(3, 1));
      store.tapCell(cell(3, 3));
      expect(store.isGameOver, isTrue);
      expect(store.state.result!.grade, GameGrade.perfectWin);
      store.dispose();
    });
  });

  group('Подсказка', () {
    test('requestHint выставляет ход и сбрасывается ходом', () async {
      final GameStore store = GameStore();
      final result = await store.requestHint();
      expect(result, isNotNull);
      expect(store.hint, isNotNull);
      store.tapCell(cell(1, 3));
      store.tapCell(24);
      expect(store.hint, isNull);
      store.dispose();
    });
  });
}
