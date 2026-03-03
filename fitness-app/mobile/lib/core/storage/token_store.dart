import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_store.g.dart';

class TokenStore {
  static const _key = 'auth_token';
  static const _userIdKey = 'user_id';
  final _storage = const FlutterSecureStorage();

  Future<void> save(String token, String userId) async {
    await _storage.write(key: _key, value: token);
    await _storage.write(key: _userIdKey, value: userId);
  }

  Future<String?> getToken() => _storage.read(key: _key);
  Future<String?> getUserId() => _storage.read(key: _userIdKey);
  Future<bool> hasToken() async => (await getToken()) != null;

  Future<void> clear() async {
    await _storage.delete(key: _key);
    await _storage.delete(key: _userIdKey);
  }
}

@Riverpod(keepAlive: true)
TokenStore tokenStore(Ref ref) => TokenStore();
