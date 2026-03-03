import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../exercises/presentation/providers/exercise_provider.dart';
import '../../data/models/plan_model.dart';
import '../providers/plan_provider.dart';

class PlanDetailPage extends ConsumerWidget {
  const PlanDetailPage({super.key, required this.planId});

  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(planDetailProvider(planId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: planAsync.maybeWhen(
          data: (plan) => Text(plan.name),
          orElse: () => const Text('Plan Details'),
        ),
      ),
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(err.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () =>
                    ref.read(planDetailProvider(planId).notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (plan) => _PlanDetailBody(plan: plan, planId: planId),
      ),
    );
  }
}

class _PlanDetailBody extends ConsumerWidget {
  const _PlanDetailBody({required this.plan, required this.planId});

  final PlanDetailModel plan;
  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      children: [
        if (plan.description != null && plan.description!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              plan.description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        Expanded(
          child: plan.days.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.today_outlined,
                        size: 64,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No days added yet',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: plan.days.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) =>
                      _DayExpansionTile(day: plan.days[i], planId: planId),
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.tonal(
            onPressed: () => _showAddDaySheet(context, ref, plan.days.length),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Icon(Icons.add), SizedBox(width: 8), Text('Add Day')],
            ),
          ),
        ),
      ],
    );
  }

  void _showAddDaySheet(BuildContext context, WidgetRef ref, int currentCount) {
    final nameController = TextEditingController();
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
            Text('Add Day', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Day Name (e.g. Push Day)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  ref.read(planDetailProvider(planId).notifier).addDay(
                        name: nameController.text.trim(),
                        orderIndex: currentCount,
                      );
                  Navigator.of(ctx).pop();
                }
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Add Day'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ).whenComplete(() => nameController.dispose());
  }
}

class _DayExpansionTile extends ConsumerWidget {
  const _DayExpansionTile({required this.day, required this.planId});

  final PlanDayModel day;
  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      child: ExpansionTile(
        title: Text(
          day.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${day.exercises.length} exercise${day.exercises.length == 1 ? '' : 's'}',
        ),
        children: [
          ...day.exercises.map(
            (pe) => ListTile(
              title: Text(pe.exercise.name),
              subtitle: Text('${pe.sets} sets x ${pe.reps} reps'),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                tooltip: 'Remove exercise',
                onPressed: () => ref
                    .read(planDetailProvider(planId).notifier)
                    .removeExerciseFromDay(day.id, pe.id),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: FilledButton.tonal(
              onPressed: () => _showAddExerciseSheet(context, ref),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 18),
                  SizedBox(width: 4),
                  Text('Add Exercise'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddExerciseSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddExerciseToDaySheet(
        onAdd: (exerciseId, sets, reps, rest) {
          ref.read(planDetailProvider(planId).notifier).addExerciseToDay(
                day.id,
                exerciseId: exerciseId,
                sets: sets,
                reps: reps,
                restSeconds: rest,
              );
        },
      ),
    );
  }
}

class _AddExerciseToDaySheet extends ConsumerStatefulWidget {
  const _AddExerciseToDaySheet({required this.onAdd});

  final void Function(String exerciseId, int sets, int reps, int? restSeconds)
      onAdd;

  @override
  ConsumerState<_AddExerciseToDaySheet> createState() =>
      _AddExerciseToDaySheetState();
}

class _AddExerciseToDaySheetState
    extends ConsumerState<_AddExerciseToDaySheet> {
  String? _selectedExerciseId;
  final _setsController = TextEditingController(text: '3');
  final _repsController = TextEditingController(text: '10');
  final _restController = TextEditingController(text: '60');

  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    _restController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selectedExerciseId == null) return;
    final sets = int.tryParse(_setsController.text) ?? 3;
    final reps = int.tryParse(_repsController.text) ?? 10;
    final rest = int.tryParse(_restController.text);
    widget.onAdd(_selectedExerciseId!, sets, reps, rest);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exerciseListProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Add Exercise to Day',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          exercisesAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Failed to load exercises: $e'),
            data: (exercises) => DropdownButtonFormField<String>(
              initialValue: _selectedExerciseId,
              hint: const Text('Select exercise'),
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: exercises
                  .map(
                    (e) => DropdownMenuItem(value: e.id, child: Text(e.name)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _selectedExerciseId = v),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _setsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Sets',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _repsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Reps',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _restController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Rest (s)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _selectedExerciseId == null ? null : _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Add'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
