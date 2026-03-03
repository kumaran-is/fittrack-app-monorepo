import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../exercises/data/models/exercise_model.dart';

part 'plan_model.freezed.dart';
part 'plan_model.g.dart';

@freezed
class PlanModel with _$PlanModel {
  const factory PlanModel({
    required String id,
    required String name,
    String? description,
    String? userId,
  }) = _PlanModel;

  factory PlanModel.fromJson(Map<String, dynamic> json) =>
      _$PlanModelFromJson(json);
}

@freezed
class PlanExerciseModel with _$PlanExerciseModel {
  const factory PlanExerciseModel({
    required String id,
    required ExerciseModel exercise,
    required int sets,
    required int reps,
    int? restSeconds,
  }) = _PlanExerciseModel;

  factory PlanExerciseModel.fromJson(Map<String, dynamic> json) =>
      _$PlanExerciseModelFromJson(json);
}

@freezed
class PlanDayModel with _$PlanDayModel {
  const factory PlanDayModel({
    required String id,
    required String name,
    required int orderIndex,
    @Default([]) List<PlanExerciseModel> exercises,
  }) = _PlanDayModel;

  factory PlanDayModel.fromJson(Map<String, dynamic> json) =>
      _$PlanDayModelFromJson(json);
}

@freezed
class PlanDetailModel with _$PlanDetailModel {
  const factory PlanDetailModel({
    required String id,
    required String name,
    String? description,
    String? userId,
    @Default([]) List<PlanDayModel> days,
  }) = _PlanDetailModel;

  factory PlanDetailModel.fromJson(Map<String, dynamic> json) =>
      _$PlanDetailModelFromJson(json);
}
