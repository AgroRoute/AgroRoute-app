import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum _SecureStorageKeys { jwtToken, username, userId }

class SecureStorageHelper {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<String> get jwtToken async {
    return await _secureStorage.read(key: _SecureStorageKeys.jwtToken.name) ??
        '';
  }

  Future<bool> hasJwtToken() async =>
      _secureStorage.containsKey(key: _SecureStorageKeys.jwtToken.name);

  Future<void> setJwtToken(String value) async => await _secureStorage.write(
    key: _SecureStorageKeys.jwtToken.name,
    value: value,
  );

  Future<void> setUserId(String value) async => await _secureStorage.write(
    key: _SecureStorageKeys.userId.name,
    value: value,
  );

  Future<String> get userId async {
    return await _secureStorage.read(key: _SecureStorageKeys.userId.name) ?? '';
  }

  Future<bool> hasUserId() async =>
      _secureStorage.containsKey(key: _SecureStorageKeys.userId.name);

  Future<String> get username async {
    return await _secureStorage.read(key: _SecureStorageKeys.username.name) ??
        '';
  }

  Future<bool> hasUserame() async =>
      _secureStorage.containsKey(key: _SecureStorageKeys.username.name);

  Future<void> setUsername(String value) async => await _secureStorage.write(
    key: _SecureStorageKeys.username.name,
    value: value,
  );

  Future<void> clear() async {}
}
