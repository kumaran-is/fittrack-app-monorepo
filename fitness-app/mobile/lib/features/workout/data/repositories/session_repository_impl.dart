import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/repositories/session_repository.dart';
import '../models/session_model.dart';

part 'session_repository_impl.g.dart';

class SessionRepositoryImpl implements SessionRepository {
  final ApiClient _apiClient;

  SessionRepositoryImpl(this._apiClient);

  @override
  Future<SessionModel> createSession({
    required String name,
    String? planId,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/sessions',
        data: {'name': name, if (planId != null) 'planId': planId},
      );
      return SessionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<List<SessionModel>> getSessions({int page = 0, int size = 20}) async {
    try {
      final response = await _apiClient.dio.get(
        '/sessions',
        queryParameters: {'page': page, 'size': size},
      );
      final data = response.data;
      // Handle both paginated and plain list responses
      if (data is Map<String, dynamic> && data.containsKey('content')) {
        final list = data['content'] as List<dynamic>;
        return list
            .map((e) => SessionModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      final list = data as List<dynamic>;
      return list
          .map((e) => SessionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<SessionDetailModel> getSession(String id) async {
    try {
      final response = await _apiClient.dio.get('/sessions/$id');
      return SessionDetailModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<void> completeSession(String id) async {
    try {
      await _apiClient.dio.patch('/sessions/$id/complete');
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<SetModel> logSet(
    String sessionId, {
    required String exerciseId,
    required int setNumber,
    required int reps,
    required double weightKg,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/sessions/$sessionId/sets',
        data: {
          'exerciseId': exerciseId,
          'setNumber': setNumber,
          'reps': reps,
          'weightKg': weightKg,
          if (notes != null) 'notes': notes,
        },
      );
      return SetModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<void> deleteSet(String sessionId, String setId) async {
    try {
      await _apiClient.dio.delete('/sessions/$sessionId/sets/$setId');
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  AppException _mapDioException(DioException e) {
    if (e.response?.statusCode == 401) {
      return const AuthException('Unauthorized');
    }
    if (e.response?.statusCode == 404) {
      return const NotFoundException('Session not found');
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const NetworkException('Connection timed out');
    }
    return ServerException(
      e.response?.data?['message']?.toString() ?? e.message ?? 'Server error',
    );
  }
}

@Riverpod(keepAlive: true)
SessionRepository sessionRepository(Ref ref) {
  return SessionRepositoryImpl(ref.read(apiClientProvider));
}
