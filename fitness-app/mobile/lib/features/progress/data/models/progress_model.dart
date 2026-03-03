import 'package:freezed_annotation/freezed_annotation.dart';

part 'progress_model.freezed.dart';
part 'progress_model.g.dart';

@freezed
class ExerciseProgressPoint with _$ExerciseProgressPoint {
  const factory ExerciseProgressPoint({
    required String weekStart,
    required double maxWeight,
  }) = _ExerciseProgressPoint;

  factory ExerciseProgressPoint.fromJson(Map<String, dynamic> json) =>
      _$ExerciseProgressPointFromJson(json);
}

@freezed
class VolumeProgressPoint with _$VolumeProgressPoint {
  const factory VolumeProgressPoint({
    required String weekStart,
    required double totalVolume,
  }) = _VolumeProgressPoint;

  factory VolumeProgressPoint.fromJson(Map<String, dynamic> json) =>
      _$VolumeProgressPointFromJson(json);
}
