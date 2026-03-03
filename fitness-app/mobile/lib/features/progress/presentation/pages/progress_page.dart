import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../exercises/data/models/exercise_model.dart';
import '../../../exercises/presentation/providers/exercise_provider.dart';
import '../../data/models/progress_model.dart';
import '../providers/progress_provider.dart';

class ProgressPage extends ConsumerWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedExerciseIdProvider);
    final exercisesAsync = ref.watch(exerciseListProvider);
    final volumeAsync = ref.watch(volumeProgressProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Exercise Progress',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          exercisesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(
              'Failed to load exercises: $e',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            data: (exercises) => _ExerciseDropdown(
              exercises: exercises,
              selectedId: selectedId,
              onChanged: (id) =>
                  ref.read(selectedExerciseIdProvider.notifier).select(id),
            ),
          ),
          const SizedBox(height: 16),
          if (selectedId != null)
            _ExerciseProgressChart(exerciseId: selectedId),
          const SizedBox(height: 32),
          Text(
            'Weekly Volume',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          volumeAsync.when(
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'Failed to load volume data: $err',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ),
            data: (points) => _VolumeBarChart(points: points),
          ),
        ],
      ),
    );
  }
}

class _ExerciseDropdown extends StatelessWidget {
  const _ExerciseDropdown({
    required this.exercises,
    required this.selectedId,
    required this.onChanged,
  });

  final List<ExerciseModel> exercises;
  final String? selectedId;
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: selectedId,
      hint: const Text('Select an exercise'),
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Exercise',
      ),
      items: exercises
          .map(
            (e) => DropdownMenuItem(
              value: e.id,
              child: Text(e.name, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _ExerciseProgressChart extends ConsumerWidget {
  const _ExerciseProgressChart({required this.exerciseId});

  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(exerciseProgressProvider(exerciseId));
    final theme = Theme.of(context);

    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: progressAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(
            'Error: $err',
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
        data: (points) {
          if (points.isEmpty) {
            return Center(
              child: Text(
                'No data yet for this exercise',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }
          final displayPoints =
              points.length > 12 ? points.sublist(points.length - 12) : points;
          final spots = displayPoints.asMap().entries.map((entry) {
            return FlSpot(entry.key.toDouble(), entry.value.maxWeight);
          }).toList();

          return LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: theme.colorScheme.primary,
                  barWidth: 2,
                  belowBarData: BarAreaData(
                    show: true,
                    color: theme.colorScheme.primary.withAlpha(30),
                  ),
                  dotData: const FlDotData(show: true),
                ),
              ],
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= displayPoints.length) {
                        return const SizedBox.shrink();
                      }
                      final label = displayPoints[index].weekStart;
                      final shortLabel =
                          label.length >= 5 ? label.substring(5) : label;
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          shortLabel,
                          style: theme.textTheme.labelSmall,
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toInt()}kg',
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
            ),
          );
        },
      ),
    );
  }
}

class _VolumeBarChart extends StatelessWidget {
  const _VolumeBarChart({required this.points});

  final List<VolumeProgressPoint> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayPoints =
        points.length > 8 ? points.sublist(points.length - 8) : points;

    if (displayPoints.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No volume data available',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final maxVolume =
        displayPoints.map((p) => p.totalVolume).reduce((a, b) => a > b ? a : b);

    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          barGroups: displayPoints.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.totalVolume,
                  color: theme.colorScheme.secondary,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
          maxY: maxVolume * 1.2,
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= displayPoints.length) {
                    return const SizedBox.shrink();
                  }
                  final label = displayPoints[index].weekStart;
                  final shortLabel =
                      label.length >= 5 ? label.substring(5) : label;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(shortLabel, style: theme.textTheme.labelSmall),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (value, meta) =>
                    Text('${value.toInt()}', style: theme.textTheme.labelSmall),
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
        ),
      ),
    );
  }
}
