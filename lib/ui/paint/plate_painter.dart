import 'package:flutter/widgets.dart';

import '../../domain/board_geometry.dart';
import '../board/board_metrics.dart';
import '../theme.dart';

/// Статичные плитки-клетки креста. Перерисовывается только при смене
/// размера, поэтому лежит под `RepaintBoundary`.
@immutable
final class BoardPlatePainter extends CustomPainter {
  const BoardPlatePainter(this.metrics);

  final BoardMetrics metrics;

  @override
  void paint(Canvas canvas, Size size) {
    final double cell = metrics.cellSize;
    final double radius = cell * 0.24;
    final Rect cross = Rect.fromLTWH(
      metrics.pad * 0.4,
      metrics.pad * 0.4,
      metrics.side - metrics.pad * 0.8,
      metrics.side - metrics.pad * 0.8,
    );

    // Каждая игровая клетка — скруглённая плитка шага `cell + gap`; в углах между
    // плитками остаются тёмные ромбики-швы.
    final List<RRect> tiles = <RRect>[
      for (final int index in BoardGeometry.playableIndexes)
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: metrics.centerOf(index),
            width: cell + metrics.gap,
            height: cell + metrics.gap,
          ),
          Radius.circular(radius),
        ),
    ];
    final Path path = Path();
    for (final RRect tile in tiles) {
      path.addRRect(tile);
    }

    // Тень креста.
    canvas.drawShadow(path, const Color(0x66000000), metrics.side * 0.02, false);

    // Пластик: синий градиент и блик.
    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(
      cross,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppPalette.plateTop, AppPalette.plateBottom],
        ).createShader(cross),
    );
    canvas.drawRect(
      cross,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0x22FFFFFF), Color(0x00FFFFFF), Color(0x2A000000)],
          stops: <double>[0, 0.45, 1],
        ).createShader(cross),
    );
    canvas.restore();

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = metrics.side * 0.006
        ..color = AppPalette.plateEdge,
    );

    // Гнёзда: утопленные тёмные круги с тонким светлым ободком.
    final double socketRadius = metrics.cellSize * 0.26;
    final Paint socket = Paint()..color = AppPalette.socket;
    final Paint rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = metrics.cellSize * 0.03
      ..color = AppPalette.socketRim;
    for (final int index in BoardGeometry.playableIndexes) {
      final Offset c = metrics.centerOf(index);
      canvas.drawCircle(c, socketRadius, socket);
      canvas.drawCircle(c, socketRadius, rim);
    }
  }

  @override
  bool shouldRepaint(BoardPlatePainter oldDelegate) =>
      oldDelegate.metrics != metrics;
}
