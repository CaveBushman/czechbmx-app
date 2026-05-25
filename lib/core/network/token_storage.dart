import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _accessKey = 'jwt_access';
  static const _refreshKey = 'jwt_refresh';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static Future<String?> getAccess() => _storage.read(key: _accessKey);
  static Future<String?> getRefresh() => _storage.read(key: _refreshKey);

  static Future<void> save({required String access, required String refresh}) =>
      Future.wait([
        _storage.write(key: _accessKey, value: access),
        _storage.write(key: _refreshKey, value: refresh),
      ]);

  static Future<void> saveAccess(String token) =>
      _storage.write(key: _accessKey, value: token);

  static Future<void> clear() => _storage.deleteAll();
}
