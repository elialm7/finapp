// lib/features/auth/domain/models/auth_model.dart

class AuthUser {
  final String token;
  final String email;
  final String baseCurrency;

  const AuthUser({
    required this.token,
    required this.email,
    required this.baseCurrency,
  });
}
