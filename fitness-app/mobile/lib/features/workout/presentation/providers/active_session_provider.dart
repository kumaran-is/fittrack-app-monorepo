import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/session_model.dart';
import '../../data/repositories/session_repository_impl.dart';

part 'active_session_provider.g.dart';

@riverpod
class ActiveSession extends _$ActiveSession {
  @override
  SessionDetailModel? build() => null;

  Future<void> startSession({required String name, String? planId}) async {
    try {
      final repo = ref.read(sessionRepositoryProvider);
      final session = await repo.createSession(name: name, planId: planId);
      final detail = await repo.getSession(session.id);
      state = detail;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logSet({
    required String exerciseId,
    required int setNumber,
    required int reps,
    required double weightKg,
    String? notes,
  }) async {
    final current = state;
    if (current == null) return;
    try {
      final newSet = await ref.read(sessionRepositoryProvider).logSet(
            current.id,
            exerciseId: exerciseId,
            setNumber: setNumber,
            reps: reps,
            weightKg: weightKg,
            notes: notes,
          );
      state = current.copyWith(sets: [...current.sets, newSet]);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeSet(String setId) async {
    final current = state;
    if (current == null) return;
    try {
      await ref.read(sessionRepositoryProvider).deleteSet(current.id, setId);
      state = current.copyWith(
        sets: current.sets.where((s) => s.id != setId).toList(),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> completeSession() async {
    final current = state;
    if (current == null) return;
    try {
      await ref.read(sessionRepositoryProvider).completeSession(current.id);
      state = current.copyWith(completed: true);
    } catch (e) {
      rethrow;
    }
  }

  void clearSession() {
    state = null;
  }
}

@riverpod
class SessionHistory extends _$SessionHistory {
  @override
  Future<List<SessionModel>> build() async {
    return ref.watch(sessionRepositoryProvider).getSessions();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(sessionRepositoryProvider).getSessions(),
    );
  }
}
