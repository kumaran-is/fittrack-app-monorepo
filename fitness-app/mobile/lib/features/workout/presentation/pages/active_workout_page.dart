import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../exercises/presentation/providers/exercise_provider.dart';
import '../../data/models/session_model.dart';
import '../providers/active_session_provider.dart';

class ActiveWorkoutPage extends ConsumerWidget {
  const ActiveWorkoutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(activeSessionProvider);
    final theme = Theme.of(context);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Active Workout')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.fitness_center,
                size: 64,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text('No active workout', style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => context.go('/workout'),
                child: const Text('Go to Workouts'),
              ),
            ],
          ),
        ),
      );
    }

    final completed = session.completed ?? false;
    final setsByExercise = <String, List<SetModel>>{};
    for (final s in session.sets) {
      setsByExercise.putIfAbsent(s.exerciseId, () => []).add(s);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(session.name),
        actions: [
          if (!completed)
            TextButton(
              onPressed: () => _confirmComplete(context, ref),
              child: const Text('Complete'),
            ),
        ],
      ),
      body: Column(
        children: [
          if (completed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: theme.colorScheme.primaryContainer,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Workout Completed!',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...setsByExercise.entries.map(
                  (entry) => _ExerciseSetGroup(
                    exerciseId: entry.key,
                    sets: entry.value,
                    sessionId: session.id,
                    isCompleted: completed,
                  ),
                ),
                if (!completed) _AddExerciseCard(sessionId: session.id),
              ],
            ),
          ),
          if (!completed)
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: () => _confirmComplete(context, ref),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: theme.colorScheme.primary,
                ),
                child: const Text('Complete Workout'),
              ),
            ),
        ],
      ),
    );
  }

  void _confirmComplete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Workout'),
        content: const Text('Mark this workout as complete?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              HapticFeedback.mediumImpact();
              await ref.read(activeSessionProvider.notifier).completeSession();
              await ref.read(sessionHistoryProvider.notifier).refresh();
              if (context.mounted) context.go('/workout');
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }
}

class _ExerciseSetGroup extends ConsumerWidget {
  const _ExerciseSetGroup({
    required this.exerciseId,
    required this.sets,
    required this.sessionId,
    required this.isCompleted,
  });

  final String exerciseId;
  final List<SetModel> sets;
  final String sessionId;
  final bool isCompleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(exerciseListProvider);
    final theme = Theme.of(context);

    final exerciseName = exercisesAsync.maybeWhen(
      data: (list) =>
          list.where((e) => e.id == exerciseId).firstOrNull?.name ?? exerciseId,
      orElse: () => exerciseId,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exerciseName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                SizedBox(width: 40),
                Expanded(child: Text('Reps', textAlign: TextAlign.center)),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Weight (kg)', textAlign: TextAlign.center),
                ),
                SizedBox(width: 40),
              ],
            ),
            const Divider(),
            ...sets.asMap().entries.map(
                  (entry) => _SetRow(
                    set: entry.value,
                    setIndex: entry.key,
                    sessionId: sessionId,
                    isCompleted: isCompleted,
                  ),
                ),
            if (!isCompleted)
              TextButton.icon(
                onPressed: () => _showLogSetSheet(context, ref),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Set'),
              ),
          ],
        ),
      ),
    );
  }

  void _showLogSetSheet(BuildContext context, WidgetRef ref) {
    _showSetEntrySheet(
      context: context,
      ref: ref,
      exerciseId: exerciseId,
      setNumber: sets.length + 1,
    );
  }
}

void _showSetEntrySheet({
  required BuildContext context,
  required WidgetRef ref,
  required String exerciseId,
  required int setNumber,
}) {
  final repsController = TextEditingController(text: '10');
  final weightController = TextEditingController(text: '0');

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(ctx).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Log Set $setNumber', style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: repsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Reps',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              final reps = int.tryParse(repsController.text) ?? 10;
              final weight = double.tryParse(weightController.text) ?? 0;
              Navigator.of(ctx).pop();
              HapticFeedback.lightImpact();
              await ref.read(activeSessionProvider.notifier).logSet(
                    exerciseId: exerciseId,
                    setNumber: setNumber,
                    reps: reps,
                    weightKg: weight,
                  );
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Log Set'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  ).whenComplete(() {
    repsController.dispose();
    weightController.dispose();
  });
}

class _SetRow extends ConsumerWidget {
  const _SetRow({
    required this.set,
    required this.setIndex,
    required this.sessionId,
    required this.isCompleted,
  });

  final SetModel set;
  final int setIndex;
  final String sessionId;
  final bool isCompleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '${setIndex + 1}',
              style: Theme.of(context).textTheme.labelLarge,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              '${set.reps}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${set.weightKg}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          SizedBox(
            width: 40,
            child: isCompleted
                ? null
                : Semantics(
                    label: 'Delete set ${setIndex + 1}',
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => ref
                          .read(activeSessionProvider.notifier)
                          .removeSet(set.id),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AddExerciseCard extends ConsumerWidget {
  const _AddExerciseCard({required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(exerciseListProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Log New Exercise',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            exercisesAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Failed to load: $e'),
              data: (exercises) => Column(
                children: exercises
                    .map(
                      (exercise) => ListTile(
                        title: Text(exercise.name),
                        subtitle: Text(exercise.category),
                        trailing: Semantics(
                          label: 'Log ${exercise.name}',
                          child: IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => _showSetEntrySheet(
                              context: context,
                              ref: ref,
                              exerciseId: exercise.id,
                              setNumber: 1,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
