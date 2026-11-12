import 'package:flutter/services.dart';

import 'key_value_storage.dart';

KeyValueStorage createStorage() => ChannelStorage();

/// Хранилище через платформенный канал `taktika/storage`. Если нативной
/// части нет (десктоп, тесты), тихо переключается на память.
class ChannelStorage implements KeyValueStorage {
  static const MethodChannel _channel = MethodChannel('taktika/storage');

  final MemoryStorage _fallback = MemoryStorage();
  bool _native = true;

  @override
  Future<String?> read(String key) async {
    if (_native) {
      try {
        return await _channel.invokeMethod<String>(
          'read',
          <String, Object?>{'key': key},
        );
      } on MissingPluginException {
        _native = false;
      } on PlatformException {
        return null;
      }
    }
    return _fallback.read(key);
  }

  @override
  Future<void> write(String key, String value) async {
    if (_native) {
      try {
        await _channel.invokeMethod<void>(
          'write',
          <String, Object?>{'key': key, 'value': value},
        );
        return;
      } on MissingPluginException {
        _native = false;
      } on PlatformException {
        return;
      }
    }
    await _fallback.write(key, value);
  }

  @override
  Future<void> remove(String key) async {
    if (_native) {
      try {
        await _channel.invokeMethod<void>(
          'remove',
          <String, Object?>{'key': key},
        );
        return;
      } on MissingPluginException {
        _native = false;
      } on PlatformException {
        return;
      }
    }
    await _fallback.remove(key);
  }
}
