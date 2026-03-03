import '../../data/models/session_model.dart';

abstract class SessionRepository {
  Future<SessionModel> createSession({required String name, String? planId});
  Future<List<SessionModel>> getSessions({int page = 0, int size = 20});
  Future<SessionDetailModel> getSession(String id);
  Future<void> completeSession(String id);
  Future<SetModel> logSet(
    String sessionId, {
    required String exerciseId,
    required int setNumber,
    required int reps,
    required double weightKg,
    String? notes,
  });
  Future<void> deleteSet(String sessionId, String setId);
}
