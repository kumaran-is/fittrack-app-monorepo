import 'package:dio/dio.dart';
import '../storage/token_store.dart';

class AuthInterceptor extends Interceptor {
  final TokenStore _tokenStore;

  AuthInterceptor(this._tokenStore);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStore.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      _tokenStore.clear();
    }
    handler.next(err);
  }
}
