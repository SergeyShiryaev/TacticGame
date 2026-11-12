import 'dart:js_interop';

import 'key_value_storage.dart';

KeyValueStorage createStorage() => LocalStorageStorage();

@JS('localStorage')
external _LocalStorage get _localStorage;

extension type _LocalStorage._(JSObject _) implements JSObject {
  external JSString? getItem(JSString key);
  external void setItem(JSString key, JSString value);
  external void removeItem(JSString key);
}

/// Хранилище на `window.localStorage`. Ошибки (приватный режим, квота)
/// не пробрасываются: игра продолжает работать без сохранения.
class LocalStorageStorage implements KeyValueStorage {
  @override
  Future<String?> read(String key) async {
    try {
      return _localStorage.getItem(key.toJS)?.toDart;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      _localStorage.setItem(key.toJS, value.toJS);
    } catch (_) {
      // Нет доступа к localStorage — игнорируем.
    }
  }

  @override
  Future<void> remove(String key) async {
    try {
      _localStorage.removeItem(key.toJS);
    } catch (_) {
      // Нет доступа к localStorage — игнорируем.
    }
  }
}
