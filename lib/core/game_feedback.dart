import 'package:flutter/services.dart';

import '../features/settings/settings_controller.dart';

/// Тактильный и звуковой отклик на события игры; учитывает настройки.
class GameFeedback {
  GameFeedback(this._settings);

  final SettingsController _settings;

  void select() {
    if (_settings.haptics) {
      HapticFeedback.selectionClick();
    }
  }

  void move() {
    if (_settings.haptics) {
      HapticFeedback.lightImpact();
    }
    if (_settings.sound) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  void reject() {
    if (_settings.haptics) {
      HapticFeedback.heavyImpact();
    }
  }

  void gameOver({required bool win}) {
    if (_settings.haptics) {
      win ? HapticFeedback.vibrate() : HapticFeedback.mediumImpact();
    }
  }
}
