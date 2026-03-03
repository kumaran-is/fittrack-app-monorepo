import '../../data/models/exercise_model.dart';

abstract class ExerciseRepository {
  Future<List<ExerciseModel>> getExercises({String? category, String? query});
  Future<ExerciseModel> getExercise(String id);
  Future<ExerciseModel> createExercise({
    required String name,
    required String category,
    String? muscleGroup,
    String? description,
  });
  Future<void> deleteExercise(String id);
}
