import '../../data/models/auth_model.dart';

abstract class AuthRepository {
  Future<AuthResponse> login(String email, String password);
  Future<AuthResponse> register(
    String email,
    String password,
    String displayName,
  );
  Future<void> logout();
  Future<bool> isLoggedIn();
}
