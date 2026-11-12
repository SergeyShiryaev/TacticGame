import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/app/app_controller.dart';
import 'package:my_app/core/key_value_storage.dart';
import 'package:my_app/domain/game_result.dart';
import 'package:my_app/features/settings/settings_controller.dart';
import 'package:my_app/features/stats/stats_controller.dart';

int cell(int row, int col) => row * 7 + col;

void main() {
  group('Статистика', () {
    test('победа и серия', () {
      GameStats s = const GameStats();
      s = s.recorded(GameResult(pegsLeft: 1, movesMade: 31, lonePegIndex: 24));
      s = s.recorded(GameResult(pegsLeft: 1, movesMade: 31, lonePegIndex: 10));
      expect(s.played, 2);
      expect(s.wins, 2);
      expect(s.perfectWins, 1);
      expect(s.streak, 2);
      s = s.recorded(GameResult(pegsLeft: 5, movesMade: 20));
      expect(s.streak, 0);
      expect(s.bestStreak, 2);
      expect(s.bestPegsLeft, 1);
    });

    test('сериализация туда и обратно', () {
      final GameStats s = const GameStats()
          .recorded(GameResult(pegsLeft: 3, movesMade: 29));
      final GameStats copy = GameStats.fromJson(s.toJson());
      expect(copy.played, 1);
      expect(copy.bestPegsLeft, 3);
    });

    test('контроллер сохраняет и загружает', () async {
      final MemoryStorage storage = MemoryStorage();
      final StatsController a = StatsController(storage);
      a.record(GameResult(pegsLeft: 2, movesMade: 30));
      await Future<void>.delayed(Duration.zero);
      final StatsController b = StatsController(storage);
      await b.load();
      expect(b.stats.played, 1);
      expect(b.stats.bestPegsLeft, 2);
    });
  });

  group('Настройки', () {
    test('сохраняются и загружаются', () async {
      final MemoryStorage storage = MemoryStorage();
      final SettingsController a = SettingsController(storage)
        ..setLanguage('en')
        ..setHaptics(false)
        ..setReduceMotion(true);
      await Future<void>.delayed(Duration.zero);
      final SettingsController b = SettingsController(storage);
      await b.load();
      expect(b.languageCode, 'en');
      expect(b.haptics, isFalse);
      expect(b.reduceMotion, isTrue);
      expect(b.sound, isTrue);
      a.dispose();
      b.dispose();
    });

    test('повреждённые данные не ломают загрузку', () async {
      final MemoryStorage storage = MemoryStorage();
      await storage.write('settings.v1', '{не json');
      final SettingsController s = SettingsController(storage);
      await s.load();
      expect(s.languageCode, isNull);
      expect(s.haptics, isTrue);
      s.dispose();
    });
  });

  group('AppController', () {
    test('автосохраняет партию и продолжает её', () async {
      final MemoryStorage storage = MemoryStorage();
      final AppController a = await AppController.load(storage);
      expect(a.hasSavedGame, isFalse);
      a.openGame(resume: false);
      a.game.tapCell(cell(1, 3));
      a.game.tapCell(24);
      await Future<void>.delayed(Duration.zero);

      final AppController b = await AppController.load(storage);
      expect(b.hasSavedGame, isTrue);
      expect(b.savedMovesCount, 1);
      b.openGame(resume: true);
      expect(b.game.state.movesMade, 1);
      a.dispose();
      b.dispose();
    });

    test('рестарт стирает сохранение', () async {
      final MemoryStorage storage = MemoryStorage();
      final AppController a = await AppController.load(storage);
      a.openGame(resume: false);
      a.game.tapCell(cell(1, 3));
      a.game.tapCell(24);
      a.game.restart();
      await Future<void>.delayed(Duration.zero);
      final AppController b = await AppController.load(storage);
      expect(b.hasSavedGame, isFalse);
      a.dispose();
      b.dispose();
    });
  });
}
