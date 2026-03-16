// lib/features/auth/data/repositories/auth_repository_impl.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../dtos/auth_dto.dart';
import '../../domain/models/auth_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(apiClientProvider).dio);
});

class AuthRepository {
  final Dio _dio;
  final _storage = const FlutterSecureStorage();

  AuthRepository(this._dio);

  Future<AuthUser> login(String email, String password) async {
    try {
      final dto = LoginRequestDto(email: email, password: password);
      final response = await _dio.post('/auth/login', data: dto.toJson());
      final authDto = AuthResponseDto.fromJson(response.data);
      await _persist(authDto);
      return _toModel(authDto);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<AuthUser> register(String email, String password, String currency) async {
    try {
      final dto = RegisterRequestDto(email: email, password: password, baseCurrency: currency);
      final response = await _dio.post('/auth/register', data: dto.toJson());
      final authDto = AuthResponseDto.fromJson(response.data);
      await _persist(authDto);
      return _toModel(authDto);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<AuthUser?> tryRestoreSession() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    final email = await _storage.read(key: AppConstants.userEmailKey);
    final currency = await _storage.read(key: AppConstants.baseCurrencyKey);
    if (token != null && email != null && currency != null) {
      return AuthUser(token: token, email: email, baseCurrency: currency);
    }
    return null;
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<void> _persist(AuthResponseDto dto) async {
    await _storage.write(key: AppConstants.tokenKey, value: dto.token);
    await _storage.write(key: AppConstants.userEmailKey, value: dto.email);
    await _storage.write(key: AppConstants.baseCurrencyKey, value: dto.baseCurrency);
  }

  AuthUser _toModel(AuthResponseDto dto) => AuthUser(
    token: dto.token,
    email: dto.email,
    baseCurrency: dto.baseCurrency,
  );
}
