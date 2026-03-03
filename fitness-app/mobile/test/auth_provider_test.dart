import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fitness_app/core/error/app_exception.dart';
import 'package:fitness_app/features/auth/data/models/auth_model.dart';
import 'package:fitness_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:fitness_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:fitness_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:fitness_app/core/storage/token_store.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockTokenStore extends Mock implements TokenStore {}

void main() {
  late MockAuthRepository mockAuthRepo;
  late MockTokenStore mockTokenStore;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    mockTokenStore = MockTokenStore();
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
        tokenStoreProvider.overrideWithValue(mockTokenStore),
      ],
    );
  }

  group('Auth provider', () {
    test('initial state is AuthUnauthenticated when no token', () async {
      when(() => mockTokenStore.hasToken()).thenAnswer((_) async => false);

      final container = makeContainer();
      addTearDown(container.dispose);

      final state = await container.read(authProvider.future);
      expect(state, isA<AuthUnauthenticated>());
    });

    test('initial state is AuthAuthenticated when token exists', () async {
      when(() => mockTokenStore.hasToken()).thenAnswer((_) async => true);
      when(() => mockTokenStore.getUserId()).thenAnswer((_) async => 'user123');

      final container = makeContainer();
      addTearDown(container.dispose);

      final state = await container.read(authProvider.future);
      expect(state, isA<AuthAuthenticated>());
      expect((state as AuthAuthenticated).userId, 'user123');
    });

    test('login sets AuthAuthenticated on success', () async {
      when(() => mockTokenStore.hasToken()).thenAnswer((_) async => false);
      when(
        () => mockAuthRepo.login('user@test.com', 'password'),
      ).thenAnswer((_) async => const AuthResponse(
          token: 'tok', userId: 'u1', displayName: 'Test User'));

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(authProvider.future);
      await container
          .read(authProvider.notifier)
          .login('user@test.com', 'password');

      final state = container.read(authProvider).valueOrNull;
      expect(state, isA<AuthAuthenticated>());
      expect((state as AuthAuthenticated).userId, 'u1');
    });

    test('login sets error state on failure', () async {
      when(() => mockTokenStore.hasToken()).thenAnswer((_) async => false);
      when(
        () => mockAuthRepo.login(any(), any()),
      ).thenThrow(const AuthException('Invalid credentials'));

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(authProvider.future);
      await container
          .read(authProvider.notifier)
          .login('bad@test.com', 'wrong');

      final authState = container.read(authProvider);
      expect(authState.hasError, isTrue);
      expect(authState.error, isA<AuthException>());
    });

    test('logout sets AuthUnauthenticated', () async {
      when(() => mockTokenStore.hasToken()).thenAnswer((_) async => true);
      when(() => mockTokenStore.getUserId()).thenAnswer((_) async => 'u1');
      when(() => mockAuthRepo.logout()).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(authProvider.future);
      await container.read(authProvider.notifier).logout();

      final state = container.read(authProvider).valueOrNull;
      expect(state, isA<AuthUnauthenticated>());
    });
  });
}
