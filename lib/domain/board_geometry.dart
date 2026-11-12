/// Геометрия поля «Тактики» (англ. Peg Solitaire / English board).
///
/// Поле — крест из 33 ячеек, вписанный в сетку 7×7: четыре угловых квадрата
/// 2×2 неигровые. Индексация плоская: `index = row * size + col`,
/// всего 49 позиций, из них 33 игровые.
class BoardGeometry {
  BoardGeometry._();

  /// Сторона сетки (7×7).
  static const int size = 7;

  /// Число позиций в массиве поля (включая неигровые углы).
  static const int cellCount = size * size;

  /// Число игровых ячеек креста.
  static const int playableCells = 33;

  /// Центр креста — (3, 3) с нуля, то есть (4, 4) в нумерации с единицы.
  static const int centerIndex = 3 * size + 3;

  /// Направления ходов: вертикаль и горизонталь. Диагоналей нет.
  static const List<int> dRow = <int>[-1, 0, 1, 0];
  static const List<int> dCol = <int>[0, -1, 0, 1];

  /// Игровые ячейки креста (отсортированы по возрастанию индекса).
  static final List<int> playableIndexes = List<int>.unmodifiable(_buildPlayable());

  static List<int> _buildPlayable() {
    final List<int> result = <int>[];
    for (int i = 0; i < cellCount; i++) {
      if (isPlayableIndex(i)) {
        result.add(i);
      }
    }
    return result;
  }

  static bool inBounds(int row, int col) =>
      row >= 0 && row < size && col >= 0 && col < size;

  /// Угловые квадраты 2×2 — неигровая зона.
  static bool isCorner(int row, int col) =>
      (row < 2 || row >= size - 2) && (col < 2 || col >= size - 2);

  static bool isPlayable(int row, int col) => inBounds(row, col) && !isCorner(row, col);

  static bool isPlayableIndex(int index) =>
      index >= 0 && index < cellCount && isPlayable(rowOf(index), colOf(index));

  static int index(int row, int col) => row * size + col;

  static int rowOf(int index) => index ~/ size;

  static int colOf(int index) => index % size;
}
