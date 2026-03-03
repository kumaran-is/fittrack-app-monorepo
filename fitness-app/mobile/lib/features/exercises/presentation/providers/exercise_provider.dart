import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/exercise_model.dart';
import '../../data/repositories/exercise_repository_impl.dart';

part 'exercise_provider.g.dart';

@Riverpod(keepAlive: true)
class ExerciseFilter extends _$ExerciseFilter {
  @override
  ({String category, String query}) build() => (category: 'ALL', query: '');

  void setCategory(String category) {
    state = (category: category, query: state.query);
  }

  void setQuery(String query) {
    state = (category: state.category, query: query);
  }
}

@riverpod
class ExerciseList extends _$ExerciseList {
  @override
  Future<List<ExerciseModel>> build() async {
    final filter = ref.watch(exerciseFilterProvider);
    return ref.watch(exerciseRepositoryProvider).getExercises(
          category: filter.category == 'ALL' ? null : filter.category,
          query: filter.query.isEmpty ? null : filter.query,
        );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      final filter = ref.read(exerciseFilterProvider);
      return ref.read(exerciseRepositoryProvider).getExercises(
            category: filter.category == 'ALL' ? null : filter.category,
            query: filter.query.isEmpty ? null : filter.query,
          );
    });
  }

  Future<void> addExercise({
    required String name,
    required String category,
    String? muscleGroup,
    String? description,
  }) async {
    await ref.read(exerciseRepositoryProvider).createExercise(
          name: name,
          category: category,
          muscleGroup: muscleGroup,
          description: description,
        );
    await refresh();
  }

  Future<void> deleteExercise(String id) async {
    final previous = state.valueOrNull ?? [];
    state = AsyncValue.data(previous.where((e) => e.id != id).toList());
    try {
      await ref.read(exerciseRepositoryProvider).deleteExercise(id);
    } catch (e) {
      state = AsyncValue.data(previous);
      rethrow;
    }
  }
}
