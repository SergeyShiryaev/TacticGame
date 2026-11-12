import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/domain/board.dart';
import 'package:my_app/domain/move.dart';
import 'package:my_app/domain/solver.dart';

int cell(int row, int col) => row * 7 + col;

void main() {
  group('PegSolver', () {
    test('находит выигрывающий ход в простой позиции', () {
      final Board board = Board.fromOccupied(<int>[cell(3, 1), cell(3, 2)]);
      final HintResult result = PegSolver(budget: 1000).hint(board);
      expect(result.status, HintStatus.winning);
      expect(result.move, Move(cell(3, 1), cell(3, 2), cell(3, 3)));
    });

    test('позиция без решения: статус noSolution', () {
      // Три фишки подряд; после любого прыжка остаются две несоседние.
      final Board board = Board.fromOccupied(
        <int>[cell(3, 0), cell(3, 1), cell(3, 2)],
      );
      final HintResult result = PegSolver(budget: 1000).hint(board);
      expect(result.status, HintStatus.noSolution);
    });

    test('позиция без ходов: noSolution и нет хода', () {
      final Board board = Board.fromOccupied(<int>[cell(0, 2), cell(6, 4)]);
      final HintResult result = PegSolver(budget: 1000).hint(board);
      expect(result.status, HintStatus.noSolution);
      expect(result.move, isNull);
    });

    test('стартовая позиция решается в разумный бюджет', () {
      final Board board = Board.initial();
      final HintResult result = PegSolver(budget: 3000000).hint(board);
      expect(result.status, anyOf(HintStatus.winning, HintStatus.unknown));
      expect(result.move, isNotNull);
      expect(board.isLegalMove(result.move!), isTrue);
    });

    test('крошечный бюджет: unknown и запасной ход', () {
      final HintResult result = PegSolver(budget: 3).hint(Board.initial());
      expect(result.status, HintStatus.unknown);
      expect(result.move, isNotNull);
    });

    test('упаковка результата для изолята сохраняет данные', () {
      const HintResult original =
          HintResult(HintStatus.winning, Move(22, 23, 24));
      final HintResult copy = HintResult.fromList(original.toList());
      expect(copy.status, HintStatus.winning);
      expect(copy.move, original.move);
      expect(HintResult.fromList(const <int>[1]).move, isNull);
    });
  });
}
