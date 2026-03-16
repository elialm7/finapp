// lib/features/auth/data/dtos/auth_dto.dart

class LoginRequestDto {
  final String email;
  final String password;
  const LoginRequestDto({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class RegisterRequestDto {
  final String email;
  final String password;
  final String baseCurrency;
  const RegisterRequestDto({
    required this.email,
    required this.password,
    this.baseCurrency = 'PYG',
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'baseCurrency': baseCurrency,
  };
}

class AuthResponseDto {
  final String token;
  final String email;
  final String baseCurrency;

  const AuthResponseDto({
    required this.token,
    required this.email,
    required this.baseCurrency,
  });

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) => AuthResponseDto(
    token: json['token'] as String,
    email: json['email'] as String,
    baseCurrency: json['baseCurrency'] as String,
  );
}
