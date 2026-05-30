// Bezpečné ukládání JWT tokenů.
//
// iOS/Android → FlutterSecureStorage (Keychain / EncryptedSharedPreferences)
// Ostatní     → SharedPreferences (fallback pro desktop/web)
//
// Používá se výhradně z AuthInterceptoru (auth_interceptor.dart)
// a AuthRepository (auth_repository.dart). Nikde jinde.
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
class TokenStorage {
  static const _accessKey = 'jwt_access';
  static const _refreshKey = 'jwt_refresh';

  static bool get _useSecure =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android;

  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static Future<String?> getAccess() async {
    if (_useSecure) return _secure.read(key: _accessKey);
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessKey);
  }

  static Future<String?> getRefresh() async {
    if (_useSecure) return _secure.read(key: _refreshKey);
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshKey);
  }

  static Future<void> save({
    required String access,
    required String refresh,
  }) async {
    if (_useSecure) {
      await Future.wait([
        _secure.write(key: _accessKey, value: access),
        _secure.write(key: _refreshKey, value: refresh),
      ]);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_accessKey, access),
      prefs.setString(_refreshKey, refresh),
    ]);
  }

  static Future<void> saveAccess(String token) async {
    if (_useSecure) {
      await _secure.write(key: _accessKey, value: token);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKey, token);
  }

  static Future<void> clear() async {
    if (_useSecure) {
      await _secure.deleteAll();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([prefs.remove(_accessKey), prefs.remove(_refreshKey)]);
  }
}
