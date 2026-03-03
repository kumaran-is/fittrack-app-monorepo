import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/storage/token_store.dart';
import '../../data/repositories/auth_repository_impl.dart';

part 'auth_provider.g.dart';

sealed class AuthState {
  const AuthState();
}

class AuthAuthenticated extends AuthState {
  final String userId;
  const AuthAuthenticated(this.userId);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  @override
  Future<AuthState> build() async {
    final tokenStore = ref.watch(tokenStoreProvider);
    final hasToken = await tokenStore.hasToken();
    if (hasToken) {
      final userId = await tokenStore.getUserId() ?? '';
      return AuthAuthenticated(userId);
    }
    return const AuthUnauthenticated();
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final resp =
          await ref.read(authRepositoryProvider).login(email, password);
      return AuthAuthenticated(resp.userId);
    });
  }

  Future<void> register(
    String email,
    String password,
    String displayName,
  ) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final resp = await ref
          .read(authRepositoryProvider)
          .register(email, password, displayName);
      return AuthAuthenticated(resp.userId);
    });
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncValue.data(AuthUnauthenticated());
  }

  /// Registers a demo account (if not yet created) then logs in automatically.
  Future<void> demoLogin() async {
    state = const AsyncLoading();
    try {
      await ref
          .read(authRepositoryProvider)
          .register('demo@fitness.com', 'Demo1234!', 'Demo User');
    } catch (_) {
      // Account may already exist — proceed to login
    }
    state = await AsyncValue.guard(() async {
      final resp = await ref
          .read(authRepositoryProvider)
          .login('demo@fitness.com', 'Demo1234!');
      return AuthAuthenticated(resp.userId);
    });
  }
}
