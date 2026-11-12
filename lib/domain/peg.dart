import 'package:flutter/foundation.dart';

/// Фишка-«гвоздик». Id уникален в рамках одной партии и сохраняется при
/// прыжке — это даёт UI анимировать перемещение конкретной фишки
/// (AnimatedPositioned по ключу), а не перерисовывать всю ячейку.
@immutable
final class Peg {
  const Peg(this.id);

  final int id;

  @override
  bool operator ==(Object other) => other is Peg && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Peg($id)';
}
