import '../../data/models/plan_model.dart';

abstract class PlanRepository {
  Future<List<PlanModel>> getPlans();
  Future<PlanDetailModel> getPlan(String id);
  Future<PlanModel> createPlan({required String name, String? description});
  Future<PlanModel> updatePlan(
    String id, {
    required String name,
    String? description,
  });
  Future<void> deletePlan(String id);
  Future<PlanDayModel> addDay(
    String planId, {
    required String name,
    required int orderIndex,
  });
  Future<void> deleteDay(String planId, String dayId);
  Future<void> addExerciseToDay(
    String planId,
    String dayId, {
    required String exerciseId,
    required int sets,
    required int reps,
    int? restSeconds,
  });
  Future<void> removeExerciseFromDay(
    String planId,
    String dayId,
    String exerciseId,
  );
}
