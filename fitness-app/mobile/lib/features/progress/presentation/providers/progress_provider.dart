import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/progress_model.dart';
import '../../data/repositories/progress_repository_impl.dart';

part 'progress_provider.g.dart';

@riverpod
class SelectedExerciseId extends _$SelectedExerciseId {
  @override
  String? build() => null;

  void select(String? exerciseId) {
    state = exerciseId;
  }
}

@riverpod
Future<List<ExerciseProgressPoint>> exerciseProgress(
  Ref ref,
  String exerciseId,
) async {
  return ref.watch(progressRepositoryProvider).getExerciseProgress(exerciseId);
}

@riverpod
Future<List<VolumeProgressPoint>> volumeProgress(Ref ref) async {
  return ref.watch(progressRepositoryProvider).getVolumeProgress();
}
