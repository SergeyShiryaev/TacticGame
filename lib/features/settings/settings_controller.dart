import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/key_value_storage.dart';

/// Пользовательские настройки; сохраняются в хранилище.
class SettingsController extends ChangeNotifier {
  SettingsController(this._storage);

  static const String _key = 'settings.v1';

  final KeyValueStorage _storage;

  /// `null` — язык системы.
  String? languageCode;
  bool haptics = true;
  bool sound = true;
  bool reduceMotion = false;

  Future<void> load() async {
    final String? raw = await _storage.read(_key);
    if (raw == null) {
      return;
    }
    try {
      final Object? data = jsonDecode(raw);
      if (data is Map<String, Object?>) {
        final Object? lang = data['lang'];
        languageCode = (lang == 'ru' || lang == 'en') ? lang as String : null;
        haptics = data['haptics'] as bool? ?? true;
        sound = data['sound'] as bool? ?? true;
        reduceMotion = data['reduceMotion'] as bool? ?? false;
      }
    } catch (_) {
      // Повреждённые настройки — остаются значения по умолчанию.
    }
  }

  void setLanguage(String? code) => _update(() => languageCode = code);
  void setHaptics(bool value) => _update(() => haptics = value);
  void setSound(bool value) => _update(() => sound = value);
  void setReduceMotion(bool value) => _update(() => reduceMotion = value);

  void _update(VoidCallback change) {
    change();
    notifyListeners();
    _storage.write(
      _key,
      jsonEncode(<String, Object?>{
        'lang': languageCode,
        'haptics': haptics,
        'sound': sound,
        'reduceMotion': reduceMotion,
      }),
    );
  }
}
