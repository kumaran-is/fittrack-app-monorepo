import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/plan_model.dart';
import '../../data/repositories/plan_repository_impl.dart';

part 'plan_provider.g.dart';

@riverpod
class PlanList extends _$PlanList {
  @override
  Future<List<PlanModel>> build() async {
    return ref.watch(planRepositoryProvider).getPlans();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(planRepositoryProvider).getPlans(),
    );
  }

  Future<void> createPlan({required String name, String? description}) async {
    await ref
        .read(planRepositoryProvider)
        .createPlan(name: name, description: description);
    await refresh();
  }

  Future<void> deletePlan(String id) async {
    final previous = state.valueOrNull ?? [];
    state = AsyncValue.data(previous.where((p) => p.id != id).toList());
    try {
      await ref.read(planRepositoryProvider).deletePlan(id);
    } catch (e) {
      state = AsyncValue.data(previous);
      rethrow;
    }
  }
}

@riverpod
class PlanDetail extends _$PlanDetail {
  @override
  Future<PlanDetailModel> build(String planId) async {
    return ref.watch(planRepositoryProvider).getPlan(planId);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(planRepositoryProvider).getPlan(planId),
    );
  }

  Future<void> addDay({required String name, required int orderIndex}) async {
    await ref
        .read(planRepositoryProvider)
        .addDay(planId, name: name, orderIndex: orderIndex);
    await refresh();
  }

  Future<void> deleteDay(String dayId) async {
    await ref.read(planRepositoryProvider).deleteDay(planId, dayId);
    await refresh();
  }

  Future<void> addExerciseToDay(
    String dayId, {
    required String exerciseId,
    required int sets,
    required int reps,
    int? restSeconds,
  }) async {
    await ref.read(planRepositoryProvider).addExerciseToDay(
          planId,
          dayId,
          exerciseId: exerciseId,
          sets: sets,
          reps: reps,
          restSeconds: restSeconds,
        );
    await refresh();
  }

  Future<void> removeExerciseFromDay(String dayId, String exerciseId) async {
    await ref
        .read(planRepositoryProvider)
        .removeExerciseFromDay(planId, dayId, exerciseId);
    await refresh();
  }
}
