import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/game_feedback.dart';
import '../core/key_value_storage.dart';
import '../domain/game_store.dart';
import '../features/settings/settings_controller.dart';
import '../features/stats/stats_controller.dart';

/// Корневой контроллер приложения: настройки, статистика, текущая партия и
/// её автосохранение.
class AppController extends ChangeNotifier {
  AppController._(this.storage)
      : settings = SettingsController(storage),
        stats = StatsController(storage) {
    feedback = GameFeedback(settings);
  }

  static const String _gameKey = 'game.v1';

  final KeyValueStorage storage;
  final SettingsController settings;
  final StatsController stats;
  late final GameFeedback feedback;

  GameStore? _game;
  List<int>? _savedMoves;
  int _savedTick = -1;
  bool _resultRecorded = false;

  /// Текущая партия (после `openGame`).
  GameStore get game => _game!;

  /// Есть ли незаконченная сохранённая партия.
  bool get hasSavedGame => _savedMoves != null && _savedMoves!.isNotEmpty;

  /// Число ходов в сохранённой партии.
  int get savedMovesCount => (_savedMoves?.length ?? 0) ~/ 2;

  /// Загружает всё сохранённое.
  static Future<AppController> load(KeyValueStorage storage) async {
    final AppController app = AppController._(storage);
    await Future.wait(<Future<void>>[
      app.settings.load(),
      app.stats.load(),
      app._loadSavedGame(),
    ]);
    return app;
  }

  Future<void> _loadSavedGame() async {
    final String? raw = await storage.read(_gameKey);
    if (raw == null) {
      return;
    }
    try {
      final Object? data = jsonDecode(raw);
      if (data is Map<String, Object?> && data['moves'] is List<Object?>) {
        _savedMoves = (data['moves']! as List<Object?>).cast<int>();
      }
    } catch (_) {
      _savedMoves = null;
    }
  }

  /// Открывает партию: продолжение сохранённой либо новую.
  void openGame({required bool resume}) {
    _game?.removeListener(_onGameChanged);
    _game?.dispose();
    final GameStore store =
        GameStore(savedMoves: resume ? _savedMoves : null);
    _game = store;
    _resultRecorded = store.isGameOver;
    _savedTick = store.layoutTick;
    if (!resume) {
      _clearSave();
    }
    store.addListener(_onGameChanged);
    notifyListeners();
  }

  void _onGameChanged() {
    final GameStore store = _game!;
    if (store.layoutTick == _savedTick) {
      return; // выбор/подсказка — сохранять нечего
    }
    _savedTick = store.layoutTick;

    if (store.isGameOver) {
      if (!_resultRecorded) {
        _resultRecorded = true;
        stats.record(store.state.result!);
        feedback.gameOver(win: store.state.result!.isWin);
      }
      _clearSave();
      return;
    }
    final List<int> moves = store.movesFlat;
    if (moves.isEmpty) {
      // Рестарт: новая партия снова засчитывается в статистике.
      _resultRecorded = false;
      _clearSave();
      return;
    }
    _savedMoves = moves;
    storage.write(_gameKey, jsonEncode(<String, Object?>{'v': 1, 'moves': moves}));
    notifyListeners();
  }

  void _clearSave() {
    final bool had = _savedMoves != null;
    _savedMoves = null;
    storage.remove(_gameKey);
    if (had) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _game?.removeListener(_onGameChanged);
    _game?.dispose();
    settings.dispose();
    stats.dispose();
    super.dispose();
  }
}
