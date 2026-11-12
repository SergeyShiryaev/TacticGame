import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/key_value_storage.dart';
import '../../domain/game_result.dart';

/// Накопленная статистика игрока.
@immutable
final class GameStats {
  const GameStats({
    this.played = 0,
    this.wins = 0,
    this.perfectWins = 0,
    this.bestPegsLeft,
    this.streak = 0,
    this.bestStreak = 0,
  });

  final int played;
  final int wins;
  final int perfectWins;

  /// Минимум фишек, с которым закончилась партия.
  final int? bestPegsLeft;
  final int streak;
  final int bestStreak;

  GameStats recorded(GameResult result) {
    final bool win = result.isWin;
    final int nextStreak = win ? streak + 1 : 0;
    return GameStats(
      played: played + 1,
      wins: wins + (win ? 1 : 0),
      perfectWins: perfectWins + (result.grade == GameGrade.perfectWin ? 1 : 0),
      bestPegsLeft: bestPegsLeft == null
          ? result.pegsLeft
          : (result.pegsLeft < bestPegsLeft! ? result.pegsLeft : bestPegsLeft),
      streak: nextStreak,
      bestStreak: nextStreak > bestStreak ? nextStreak : bestStreak,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'played': played,
        'wins': wins,
        'perfect': perfectWins,
        'best': bestPegsLeft,
        'streak': streak,
        'bestStreak': bestStreak,
      };

  factory GameStats.fromJson(Map<String, Object?> json) => GameStats(
        played: json['played'] as int? ?? 0,
        wins: json['wins'] as int? ?? 0,
        perfectWins: json['perfect'] as int? ?? 0,
        bestPegsLeft: json['best'] as int?,
        streak: json['streak'] as int? ?? 0,
        bestStreak: json['bestStreak'] as int? ?? 0,
      );
}

/// Хранит и обновляет статистику.
class StatsController extends ChangeNotifier {
  StatsController(this._storage);

  static const String _key = 'stats.v1';

  final KeyValueStorage _storage;

  GameStats stats = const GameStats();

  Future<void> load() async {
    final String? raw = await _storage.read(_key);
    if (raw == null) {
      return;
    }
    try {
      final Object? data = jsonDecode(raw);
      if (data is Map<String, Object?>) {
        stats = GameStats.fromJson(data);
      }
    } catch (_) {
      // Повреждённая статистика — начинаем с нуля.
    }
  }

  void record(GameResult result) {
    stats = stats.recorded(result);
    notifyListeners();
    _storage.write(_key, jsonEncode(stats.toJson()));
  }

  void reset() {
    stats = const GameStats();
    notifyListeners();
    _storage.remove(_key);
  }
}
