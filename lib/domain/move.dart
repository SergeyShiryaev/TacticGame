import 'package:flutter/foundation.dart';

/// Ход-прыжок: фишка с `from` перелетает через `through` в пустую `to`.
/// Все три ячейки лежат на одной прямой (шахматный ладейный ход на 2 клетки).
@immutable
final class Move {
  const Move(this.from, this.through, this.to);

  final int from;
  final int through;
  final int to;

  @override
  bool operator ==(Object other) =>
      other is Move && other.from == from && other.through == through && other.to == to;

  @override
  int get hashCode => Object.hash(from, through, to);

  @override
  String toString() => 'Move($from -> $through -> $to)';
}
