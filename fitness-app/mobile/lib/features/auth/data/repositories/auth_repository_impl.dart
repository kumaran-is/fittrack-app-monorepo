import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_store.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/auth_model.dart';

part 'auth_repository_impl.g.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;
  final TokenStore _tokenStore;

  AuthRepositoryImpl(this._apiClient, this._tokenStore);

  @override
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: LoginRequest(email: email, password: password).toJson(),
      );
      final authResponse = AuthResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
      await _tokenStore.save(authResponse.token, authResponse.userId);
      return authResponse;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<AuthResponse> register(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/register',
        data: RegisterRequest(
          email: email,
          password: password,
          displayName: displayName,
        ).toJson(),
      );
      final authResponse = AuthResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
      await _tokenStore.save(authResponse.token, authResponse.userId);
      return authResponse;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<void> logout() async {
    await _tokenStore.clear();
  }

  @override
  Future<bool> isLoggedIn() => _tokenStore.hasToken();

  AppException _mapDioException(DioException e) {
    if (e.response?.statusCode == 401) {
      return const AuthException('Invalid credentials');
    }
    if (e.response?.statusCode == 409) {
      return const AuthException('Account already exists');
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const NetworkException('Connection timed out');
    }
    return ServerException(
      e.response?.data?['detail']?.toString() ??
          e.response?.data?['message']?.toString() ??
          e.message ??
          'Server error',
    );
  }
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepositoryImpl(
    ref.read(apiClientProvider),
    ref.read(tokenStoreProvider),
  );
}
