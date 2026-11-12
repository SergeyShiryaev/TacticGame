import 'storage_io.dart' if (dart.library.js_interop) 'storage_web.dart'
    as platform;

/// Простое хранилище «ключ → строка». Реализации: `localStorage` (web),
/// `SharedPreferences`/`UserDefaults` через платформенный канал (мобильные)
/// и память (тесты, десктоп).
abstract interface class KeyValueStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
}

/// Хранилище в памяти: тесты и платформы без нативной реализации.
class MemoryStorage implements KeyValueStorage {
  final Map<String, String> _data = <String, String>{};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async => _data[key] = value;

  @override
  Future<void> remove(String key) async => _data.remove(key);
}

/// Хранилище для текущей платформы.
KeyValueStorage createPlatformStorage() => platform.createStorage();
