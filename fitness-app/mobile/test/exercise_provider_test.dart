import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fitness_app/core/error/app_exception.dart';
import 'package:fitness_app/features/exercises/data/models/exercise_model.dart';
import 'package:fitness_app/features/exercises/data/repositories/exercise_repository_impl.dart';
import 'package:fitness_app/features/exercises/domain/repositories/exercise_repository.dart';
import 'package:fitness_app/features/exercises/presentation/providers/exercise_provider.dart';

class MockExerciseRepository extends Mock implements ExerciseRepository {}

void main() {
  late MockExerciseRepository mockRepo;

  const testExercise = ExerciseModel(
    id: '1',
    name: 'Bench Press',
    category: 'CHEST',
    muscleGroup: 'Pectorals',
  );

  setUp(() {
    mockRepo = MockExerciseRepository();
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [exerciseRepositoryProvider.overrideWithValue(mockRepo)],
    );
  }

  group('ExerciseList provider', () {
    test('returns exercises on success', () async {
      when(
        () => mockRepo.getExercises(
          category: any(named: 'category'),
          query: any(named: 'query'),
        ),
      ).thenAnswer((_) async => [testExercise]);

      final container = makeContainer();
      addTearDown(container.dispose);

      final result = await container.read(exerciseListProvider.future);
      expect(result, [testExercise]);
    });

    test('propagates ServerException as error state', () async {
      when(
        () => mockRepo.getExercises(
          category: any(named: 'category'),
          query: any(named: 'query'),
        ),
      ).thenThrow(const ServerException('Server error'));

      final container = makeContainer();
      addTearDown(container.dispose);

      Object? caughtError;
      try {
        await container.read(exerciseListProvider.future);
      } catch (e) {
        caughtError = e;
      }
      expect(caughtError, isA<ServerException>());
    });
  });

  group('ExerciseFilter provider', () {
    test('initial state is ALL category with empty query', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final filter = container.read(exerciseFilterProvider);
      expect(filter.category, 'ALL');
      expect(filter.query, '');
    });

    test('setCategory updates category', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(exerciseFilterProvider.notifier).setCategory('CHEST');
      final filter = container.read(exerciseFilterProvider);
      expect(filter.category, 'CHEST');
      expect(filter.query, '');
    });

    test('setQuery updates query', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(exerciseFilterProvider.notifier).setQuery('bench');
      final filter = container.read(exerciseFilterProvider);
      expect(filter.category, 'ALL');
      expect(filter.query, 'bench');
    });
  });
}
