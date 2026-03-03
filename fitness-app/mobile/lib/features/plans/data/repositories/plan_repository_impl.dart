import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/repositories/plan_repository.dart';
import '../models/plan_model.dart';

part 'plan_repository_impl.g.dart';

class PlanRepositoryImpl implements PlanRepository {
  final ApiClient _apiClient;

  PlanRepositoryImpl(this._apiClient);

  @override
  Future<List<PlanModel>> getPlans() async {
    try {
      final response = await _apiClient.dio.get('/plans');
      final list = response.data as List<dynamic>;
      return list
          .map((e) => PlanModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<PlanDetailModel> getPlan(String id) async {
    try {
      final response = await _apiClient.dio.get('/plans/$id');
      return PlanDetailModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<PlanModel> createPlan({
    required String name,
    String? description,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/plans',
        data: {
          'name': name,
          if (description != null) 'description': description,
        },
      );
      return PlanModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<PlanModel> updatePlan(
    String id, {
    required String name,
    String? description,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '/plans/$id',
        data: {
          'name': name,
          if (description != null) 'description': description,
        },
      );
      return PlanModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<void> deletePlan(String id) async {
    try {
      await _apiClient.dio.delete('/plans/$id');
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<PlanDayModel> addDay(
    String planId, {
    required String name,
    required int orderIndex,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/plans/$planId/days',
        data: {'name': name, 'orderIndex': orderIndex},
      );
      return PlanDayModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<void> deleteDay(String planId, String dayId) async {
    try {
      await _apiClient.dio.delete('/plans/$planId/days/$dayId');
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<void> addExerciseToDay(
    String planId,
    String dayId, {
    required String exerciseId,
    required int sets,
    required int reps,
    int? restSeconds,
  }) async {
    try {
      await _apiClient.dio.post(
        '/plans/$planId/days/$dayId/exercises',
        data: {
          'exerciseId': exerciseId,
          'sets': sets,
          'reps': reps,
          if (restSeconds != null) 'restSeconds': restSeconds,
        },
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<void> removeExerciseFromDay(
    String planId,
    String dayId,
    String exerciseId,
  ) async {
    try {
      await _apiClient.dio.delete(
        '/plans/$planId/days/$dayId/exercises/$exerciseId',
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  AppException _mapDioException(DioException e) {
    if (e.response?.statusCode == 401) {
      return const AuthException('Unauthorized');
    }
    if (e.response?.statusCode == 404) {
      return const NotFoundException('Plan not found');
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
PlanRepository planRepository(Ref ref) {
  return PlanRepositoryImpl(ref.read(apiClientProvider));
}
