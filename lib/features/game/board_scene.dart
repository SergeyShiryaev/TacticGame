import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../domain/move.dart';

/// Изменяемое «сцена»-состояние анимаций и перетаскивания. Painter подписан
/// на него через `repaint`, поэтому кадры анимации не перестраивают виджеты.
class BoardScene extends ChangeNotifier {
  /// Перелёт фишки хода: от `flyFrom` (или центра `from`) к центру `to`.
  Move? flyMove;
  Offset? flyFrom;
  int flyPegId = 0;

  /// Прогресс перелёта после кривой, 0..1.
  double flightT = 0;

  /// Затухание снятой фишки в клетке `through`, 0..1.
  Move? ghostMove;
  double ghostT = 0;

  /// Перетаскиваемая фишка.
  int? dragPegId;
  Offset dragPos = Offset.zero;
  Offset dragOrigin = Offset.zero;

  /// Прогресс возврата при отвергнутом сбросе, 0..1; null — не возвращается.
  double? returnT;

  /// Клетка клавиатурного курсора (видна после первого нажатия клавиши).
  int? cursorCell;

  void repaint() => notifyListeners();
}
