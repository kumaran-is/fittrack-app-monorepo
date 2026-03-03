import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/repositories/progress_repository.dart';
import '../models/progress_model.dart';

part 'progress_repository_impl.g.dart';

class ProgressRepositoryImpl implements ProgressRepository {
  final ApiClient _apiClient;

  ProgressRepositoryImpl(this._apiClient);

  @override
  Future<List<ExerciseProgressPoint>> getExerciseProgress(
    String exerciseId,
  ) async {
    try {
      final response = await _apiClient.dio.get(
        '/progress/exercises/$exerciseId',
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => ExerciseProgressPoint.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<List<VolumeProgressPoint>> getVolumeProgress() async {
    try {
      final response = await _apiClient.dio.get('/progress/volume');
      final list = response.data as List<dynamic>;
      return list
          .map((e) => VolumeProgressPoint.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  AppException _mapDioException(DioException e) {
    if (e.response?.statusCode == 401) {
      return const AuthException('Unauthorized');
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
ProgressRepository progressRepository(Ref ref) {
  return ProgressRepositoryImpl(ref.read(apiClientProvider));
}
