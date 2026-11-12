import 'dart:ui' show Offset, Size;

import 'package:flutter/foundation.dart';

import '../../domain/board_geometry.dart';

/// Метрика поля в локальных координатах квадрата board. Всё считается из
/// короткой стороны доступной области, поэтому крест влезает и на iPhone SE,
/// и на вытянутом Android-экране, и в ландшафте.
@immutable
final class BoardMetrics {
  BoardMetrics(this.size)
      : side = _minSide(size),
        pad = _minSide(size) * 0.055,
        gap = _minSide(size) * 0.038;

  /// Иное значение с той же длиной стороны равно прежнему (== сравнивает
  /// размер) — слою фишек это даёт признак «метрики не менялись».
  bool sameSize(Size other) => size.width == other.width && size.height == other.height;

  static double _minSide(Size s) => (s.width < s.height ? s.width : s.height);

  final Size size;

  /// Сторона квадрата, в который вписан крест.
  final double side;
  final double pad;
  final double gap;

  double get cellSize => (side - 2 * pad - (BoardGeometry.size - 1) * gap) / BoardGeometry.size;

  double get pegDiameter => cellSize * 0.84;

  double _step(double cellSize) => cellSize + gap;

  Offset centerOf(int index) {
    final double c = cellSize;
    final double step = _step(c);
    final int row = BoardGeometry.rowOf(index);
    final int col = BoardGeometry.colOf(index);
    return Offset(pad + col * step + c / 2, pad + row * step + c / 2);
  }

  Offset topLeftOf(int index, double objectSize) {
    final Offset c = centerOf(index);
    return Offset(c.dx - objectSize / 2, c.dy - objectSize / 2);
  }

  /// Ближайшая игровая клетка под точкой (для drag-and-drop), либо null.
  int? cellAt(Offset local) {
    final double c = cellSize;
    final double step = _step(c);
    if (local.dx < 0 || local.dy < 0 || local.dx > size.width || local.dy > size.height) {
      return null;
    }
    final int col = ((local.dx - pad - c / 2) / step).round();
    final int row = ((local.dy - pad - c / 2) / step).round();
    if (!BoardGeometry.inBounds(row, col)) {
      return null;
    }
    final int index = BoardGeometry.index(row, col);
    if (!BoardGeometry.isPlayableIndex(index)) {
      return null;
    }
    final Offset center = centerOf(index);
    final double limit = c * 0.62;
    if ((local.dx - center.dx).abs() > limit || (local.dy - center.dy).abs() > limit) {
      return null;
    }
    return index;
  }

  @override
  bool operator ==(Object other) =>
      other is BoardMetrics &&
      other.size.width == size.width &&
      other.size.height == size.height;

  @override
  int get hashCode => Object.hash(size.width, size.height);
}
