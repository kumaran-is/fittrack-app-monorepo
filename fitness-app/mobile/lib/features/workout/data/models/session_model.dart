import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_model.freezed.dart';
part 'session_model.g.dart';

@freezed
class SetModel with _$SetModel {
  const factory SetModel({
    required String id,
    required String exerciseId,
    required int setNumber,
    required int reps,
    required double weightKg,
    String? notes,
  }) = _SetModel;

  factory SetModel.fromJson(Map<String, dynamic> json) =>
      _$SetModelFromJson(json);
}

@freezed
class SessionModel with _$SessionModel {
  const factory SessionModel({
    required String id,
    required String name,
    String? planId,
    bool? completed,
  }) = _SessionModel;

  factory SessionModel.fromJson(Map<String, dynamic> json) =>
      _$SessionModelFromJson(json);
}

@freezed
class SessionDetailModel with _$SessionDetailModel {
  const factory SessionDetailModel({
    required String id,
    required String name,
    String? planId,
    bool? completed,
    @Default([]) List<SetModel> sets,
  }) = _SessionDetailModel;

  factory SessionDetailModel.fromJson(Map<String, dynamic> json) =>
      _$SessionDetailModelFromJson(json);
}

@freezed
class PagedSessions with _$PagedSessions {
  const factory PagedSessions({
    required List<SessionModel> content,
    required int totalElements,
    required bool last,
  }) = _PagedSessions;

  factory PagedSessions.fromJson(Map<String, dynamic> json) =>
      _$PagedSessionsFromJson(json);
}
