import '../../data/models/progress_model.dart';

abstract class ProgressRepository {
  Future<List<ExerciseProgressPoint>> getExerciseProgress(String exerciseId);
  Future<List<VolumeProgressPoint>> getVolumeProgress();
}
