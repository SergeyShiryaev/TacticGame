import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../theme.dart';

/// Кэш записанных `Picture` фишки. Запись шейдеров и теней выполняется один
/// раз на размер, а на каждом кадре фишка рисуется одним `drawPicture`.
class PegSpriteCache {
  double _diameter = -1;
  ui.Picture? _normal;
  ui.Picture? _lifted;
  ui.Picture? _hole;

  void _ensure(double diameter) {
    if (_diameter == diameter && _normal != null) {
      return;
    }
    _normal?.dispose();
    _lifted?.dispose();
    _hole?.dispose();
    _diameter = diameter;
    _normal = _record(diameter, lifted: false);
    _lifted = _record(diameter, lifted: true);
    _hole = _recordHole(diameter);
  }

  /// Рисует пустую лунку (тёмное углубление) с центром в [center].
  void paintHole(Canvas canvas, Offset center, double diameter) {
    _ensure(diameter);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.drawPicture(_hole!);
    canvas.restore();
  }

  /// Рисует фишку с центром в [center]. [scale] — множитель размера.
  void paint(
    Canvas canvas,
    Offset center,
    double diameter, {
    bool lifted = false,
    double scale = 1,
  }) {
    _ensure(diameter);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (scale != 1) {
      canvas.scale(scale);
    }
    canvas.drawPicture((lifted ? _lifted : _normal)!);
    canvas.restore();
  }

  void dispose() {
    _normal?.dispose();
    _lifted?.dispose();
    _hole?.dispose();
    _normal = null;
    _lifted = null;
    _hole = null;
    _diameter = -1;
  }

  /// Лунка: тёмный круг с мягким градиентом и тонким светлым ободком.
  static ui.Picture _recordHole(double diameter) {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final double r = diameter * 0.37;
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..shader = const RadialGradient(
          colors: <Color>[Color(0xFF040C16), Color(0xFF0B1B30), Color(0xFF1A3556)],
          stops: <double>[0.0, 0.6, 1.0],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: r)),
    );
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.12
        ..color = const Color(0x33FFFFFF),
    );
    return recorder.endRecording();
  }

  static ui.Picture _record(double diameter, {required bool lifted}) {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final double r = diameter / 2;
    const Offset c = Offset.zero;

    // Тень под фишкой.
    canvas.drawCircle(
      c + Offset(0, r * (lifted ? 0.34 : 0.16)),
      r * 0.92,
      Paint()
        ..color = AppPalette.pegShadow
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * (lifted ? 0.26 : 0.14)),
    );

    // Корпус: перламутровый шарик со смещённым источником света.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          colors: <Color>[AppPalette.pegLight, AppPalette.pegMain, AppPalette.pegDeep],
          stops: <double>[0.0, 0.6, 1.0],
          center: Alignment(-0.34, -0.4),
          radius: 1.05,
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    // Тонкий тёмный ободок.
    canvas.drawCircle(
      c,
      r * 0.97,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.06
        ..color = AppPalette.pegRim.withValues(alpha: 0.55),
    );

    // Мягкий блик и яркая точка.
    final Offset gloss = c + Offset(-r * 0.30, -r * 0.36);
    canvas.drawCircle(
      gloss,
      r * 0.38,
      Paint()
        ..shader = const RadialGradient(
          colors: <Color>[Color(0xE6FFFFFF), Color(0x00FFFFFF)],
        ).createShader(Rect.fromCircle(center: gloss, radius: r * 0.38)),
    );
    canvas.drawCircle(
      gloss + Offset(-r * 0.03, -r * 0.03),
      r * 0.10,
      Paint()..color = const Color(0xF2FFFFFF),
    );

    return recorder.endRecording();
  }
}
