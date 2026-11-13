import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tactics/app/app.dart';
import 'package:tactics/app/app_controller.dart';
import 'package:tactics/core/key_value_storage.dart';

void main() {
  testWidgets('меню → игра → ход → отмена', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final AppController app = await AppController.load(MemoryStorage());
    await tester.pumpWidget(TaktikaApp(app: app));
    await tester.pumpAndSettle();

    expect(find.text('NEW GAME'), findsOneWidget);
    await tester.tap(find.text('NEW GAME'));
    await tester.pumpAndSettle();

    expect(find.text('32'), findsOneWidget); // счётчик фишек
    expect(find.text('Undo'), findsOneWidget);

    // Тап по фишке (1,3), затем по центру (3,3).
    final Finder board = find.bySemanticsLabel('Game board, 32 pegs');
    expect(board, findsOneWidget);
    final Rect rect = tester.getRect(board);
    final double step = rect.width / 7;
    await tester.tapAt(rect.topLeft + Offset(step * 3.5, step * 1.5));
    await tester.pump();
    await tester.tapAt(rect.topLeft + Offset(step * 3.5, step * 3.5));
    await tester.pumpAndSettle();

    expect(app.game.state.board.pegCount, 31);
    expect(find.text('31'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(app.game.state.board.pegCount, 32);
  });

  testWidgets('перетаскивание фишки в центр делает ход', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final AppController app = await AppController.load(MemoryStorage());
    await tester.pumpWidget(TaktikaApp(app: app));
    await tester.pumpAndSettle();
    await tester.tap(find.text('NEW GAME'));
    await tester.pumpAndSettle();

    final Rect rect = tester.getRect(find.bySemanticsLabel('Game board, 32 pegs'));
    final double step = rect.width / 7;
    final Offset from = rect.topLeft + Offset(step * 3.5, step * 1.5);
    final Offset to = rect.topLeft + Offset(step * 3.5, step * 3.5);
    final TestGesture gesture = await tester.startGesture(from);
    await gesture.moveTo(from + const Offset(0, 40));
    await gesture.moveTo(to);
    await gesture.up();
    await tester.pumpAndSettle();

    expect(app.game.state.board.pegCount, 31);
  });

  testWidgets('смена языка в настройках', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final AppController app = await AppController.load(MemoryStorage());
    await tester.pumpWidget(TaktikaApp(app: app));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Русский'));
    await tester.pumpAndSettle();
    expect(find.text('Настройки'), findsOneWidget);
  });
}
