import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/token_store.dart';
import 'auth_interceptor.dart';

part 'api_client.g.dart';

class ApiClient {
  // Use 10.0.2.2 for Android emulator (host machine alias)
  // Use localhost for iOS simulator or web
  static const baseUrl = 'http://10.0.2.2:8080/api/v1';

  late final Dio dio;

  ApiClient(TokenStore tokenStore) {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    dio.interceptors.add(AuthInterceptor(tokenStore));
  }
}

@Riverpod(keepAlive: true)
ApiClient apiClient(Ref ref) {
  final tokenStore = ref.read(tokenStoreProvider);
  return ApiClient(tokenStore);
}
