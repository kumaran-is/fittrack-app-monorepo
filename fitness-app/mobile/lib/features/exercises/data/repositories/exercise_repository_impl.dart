import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/repositories/exercise_repository.dart';
import '../models/exercise_model.dart';

part 'exercise_repository_impl.g.dart';

class ExerciseRepositoryImpl implements ExerciseRepository {
  final ApiClient _apiClient;

  ExerciseRepositoryImpl(this._apiClient);

  @override
  Future<List<ExerciseModel>> getExercises({
    String? category,
    String? query,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null && category != 'ALL') {
        queryParams['category'] = category;
      }
      if (query != null && query.isNotEmpty) queryParams['q'] = query;

      final response = await _apiClient.dio.get(
        '/exercises',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => ExerciseModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<ExerciseModel> getExercise(String id) async {
    try {
      final response = await _apiClient.dio.get('/exercises/$id');
      return ExerciseModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<ExerciseModel> createExercise({
    required String name,
    required String category,
    String? muscleGroup,
    String? description,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/exercises',
        data: {
          'name': name,
          'category': category,
          if (muscleGroup != null) 'muscleGroup': muscleGroup,
          if (description != null) 'description': description,
        },
      );
      return ExerciseModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<void> deleteExercise(String id) async {
    try {
      await _apiClient.dio.delete('/exercises/$id');
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  AppException _mapDioException(DioException e) {
    if (e.response?.statusCode == 401) {
      return const AuthException('Unauthorized');
    }
    if (e.response?.statusCode == 404) {
      return const NotFoundException('Exercise not found');
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
ExerciseRepository exerciseRepository(Ref ref) {
  return ExerciseRepositoryImpl(ref.read(apiClientProvider));
}
