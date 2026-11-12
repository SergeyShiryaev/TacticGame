import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../../domain/board_geometry.dart';
import '../../domain/game_store.dart';
import '../../domain/move.dart';
import '../../domain/peg.dart';
import '../../l10n/app_strings.dart';
import '../../ui/board/board_metrics.dart';
import '../../ui/paint/peg_sprite.dart';
import '../../ui/theme.dart';
import 'board_scene.dart';

/// Динамический слой поля: подсветки, фишки, перелёт, перетаскивание. Всё
/// рисуется одним проходом; подписка на `store` и `scene` через `repaint`.
class BoardPainter extends CustomPainter {
  BoardPainter({
    required this.store,
    required this.scene,
    required this.metrics,
    required this.sprites,
    required this.strings,
    required this.textDirection,
    required this.onCellTap,
    required this.cursorVisible,
    required this.layoutTick,
  }) : super(repaint: Listenable.merge(<Listenable>[store, scene]));

  final GameStore store;
  final BoardScene scene;
  final BoardMetrics metrics;
  final PegSpriteCache sprites;
  final AppStrings strings;
  final TextDirection textDirection;
  final ValueChanged<int> onCellTap;
  final bool Function() cursorVisible;

  /// Версия расстановки на момент создания: нужна для перестройки семантики.
  final int layoutTick;

  @override
  void paint(Canvas canvas, Size size) {
    final BoardMetrics m = metrics;
    final double cell = m.cellSize;
    final double d = m.pegDiameter;
    final snapshot = store.snapshot;
    final int? selectedCell = store.state.selectedCell;

    // Пустые клетки — тёмные лунки.
    for (final int index in BoardGeometry.playableIndexes) {
      if (!snapshot.pegByCell.containsKey(index)) {
        sprites.paintHole(canvas, m.centerOf(index), d);
      }
    }

    _paintHint(canvas, m);

    if (selectedCell != null) {
      final Paint ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.06
        ..color = AppPalette.highlight;
      canvas.drawCircle(m.centerOf(selectedCell), cell * 0.56, ring);

      final Paint capture = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.05
        ..color = AppPalette.capture;
      for (final int index in snapshot.captureCells) {
        canvas.drawCircle(m.centerOf(index), cell * 0.5, capture);
      }

      final Paint targetRing = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.05
        ..color = AppPalette.highlightSoft;
      final Paint targetDot = Paint()..color = AppPalette.highlightSoft;
      for (final int index in snapshot.emptyTargets) {
        final Offset c = m.centerOf(index);
        canvas.drawCircle(c, cell * 0.42, targetRing);
        canvas.drawCircle(c, cell * 0.20, targetDot);
      }
    }

    final int? cursor = scene.cursorCell;
    if (cursor != null && cursorVisible()) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: m.centerOf(cursor), width: cell * 1.04, height: cell * 1.04),
          Radius.circular(cell * 0.28),
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = cell * 0.06
          ..color = AppPalette.text,
      );
    }

    // Неподвижные фишки.
    final bool flying = scene.flyMove != null;
    for (final MapEntry<int, Peg> entry in snapshot.pegByCell.entries) {
      final int id = entry.value.id;
      if ((flying && id == scene.flyPegId) || id == scene.dragPegId) {
        continue;
      }
      final bool selected = entry.key == selectedCell;
      sprites.paint(
        canvas,
        m.centerOf(entry.key),
        d,
        lifted: selected,
        scale: selected ? 1.06 : 1,
      );
    }

    // Снятая фишка: затухание и уменьшение.
    final Move? ghost = scene.ghostMove;
    if (ghost != null) {
      final double t = scene.ghostT;
      final Offset c = m.centerOf(ghost.through);
      canvas.saveLayer(
        Rect.fromCircle(center: c, radius: d),
        Paint()..color = Color.fromRGBO(0, 0, 0, (1 - t).clamp(0.0, 1.0)),
      );
      sprites.paint(canvas, c, d, scale: 1 - t * 0.5);
      canvas.restore();
    }

    // Перелёт фишки хода.
    final Move? fly = scene.flyMove;
    if (fly != null) {
      final double t = scene.flightT;
      final Offset start = scene.flyFrom ?? m.centerOf(fly.from);
      final Offset pos = Offset.lerp(start, m.centerOf(fly.to), t)!;
      sprites.paint(
        canvas,
        pos,
        d,
        lifted: true,
        scale: 1 + 0.14 * math.sin(math.pi * t),
      );
    }

    // Перетаскиваемая фишка — поверх всего.
    if (scene.dragPegId != null) {
      final double? back = scene.returnT;
      final Offset pos = back == null
          ? scene.dragPos
          : Offset.lerp(
              scene.dragPos,
              scene.dragOrigin,
              Curves.easeOutBack.transform(back),
            )!;
      sprites.paint(canvas, pos, d, lifted: true, scale: 1.1);
    }
  }

  void _paintHint(Canvas canvas, BoardMetrics m) {
    final Move? hint = store.hint;
    if (hint == null) {
      return;
    }
    final double cell = m.cellSize;
    final Paint ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * 0.07
      ..color = AppPalette.hint;
    canvas.drawCircle(m.centerOf(hint.from), cell * 0.58, ring);
    canvas.drawCircle(m.centerOf(hint.to), cell * 0.44, ring);
    canvas.drawCircle(
      m.centerOf(hint.to),
      cell * 0.18,
      Paint()..color = AppPalette.hint.withValues(alpha: 0.7),
    );
  }

  @override
  bool shouldRepaint(BoardPainter oldDelegate) => true;

  @override
  SemanticsBuilderCallback? get semanticsBuilder => (Size size) {
        final int? selectedCell = store.state.selectedCell;
        return <CustomPainterSemantics>[
          for (final int index in BoardGeometry.playableIndexes)
            CustomPainterSemantics(
              key: ValueKey<int>(index),
              rect: Rect.fromCenter(
                center: metrics.centerOf(index),
                width: metrics.cellSize,
                height: metrics.cellSize,
              ),
              properties: SemanticsProperties(
                textDirection: textDirection,
                label: store.state.board.isEmptyAt(index)
                    ? strings.semEmpty(
                        BoardGeometry.rowOf(index) + 1,
                        BoardGeometry.colOf(index) + 1,
                      )
                    : strings.semPeg(
                        BoardGeometry.rowOf(index) + 1,
                        BoardGeometry.colOf(index) + 1,
                      ),
                button: true,
                selected: index == selectedCell,
                onTap: () => onCellTap(index),
              ),
            ),
        ];
      };

  @override
  bool shouldRebuildSemantics(BoardPainter oldDelegate) =>
      oldDelegate.layoutTick != layoutTick ||
      oldDelegate.metrics != metrics ||
      oldDelegate.strings != strings;
}
