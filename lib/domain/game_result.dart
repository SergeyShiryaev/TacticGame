import 'package:flutter/foundation.dart';

import 'board_geometry.dart';

/// Оценка исхода партии по количеству оставшихся фишек.
enum GameGrade {
  /// Ровно одна фишка — строго в центре креста.
  perfectWin,

  /// Ровно одна фишка, но не в центре.
  lonePegOffCenter,

  /// Две-три фишки.
  good,

  /// Четыре и более — тупик.
  deadEnd,
}

/// Итог партии: считается только когда доступных ходов не осталось.
@immutable
final class GameResult {
  GameResult({required this.pegsLeft, required this.movesMade, this.lonePegIndex})
      : grade = _gradeOf(pegsLeft, lonePegIndex);

  final int pegsLeft;
  final int movesMade;

  /// Индекс единственной оставшейся фишки (null, если таких больше одной).
  final int? lonePegIndex;

  final GameGrade grade;

  bool get isWin => pegsLeft == 1;

  static GameGrade _gradeOf(int pegsLeft, int? lonePegIndex) {
    if (pegsLeft == 1) {
      return lonePegIndex == BoardGeometry.centerIndex
          ? GameGrade.perfectWin
          : GameGrade.lonePegOffCenter;
    }
    if (pegsLeft <= 3) {
      return GameGrade.good;
    }
    return GameGrade.deadEnd;
  }

  @override
  String toString() => 'GameResult(pegs: $pegsLeft, moves: $movesMade, $grade)';
}
