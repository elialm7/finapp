// lib/features/accounts/data/repositories/account_repository.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../dtos/account_dto.dart';
import '../../domain/models/account_model.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(ref.read(apiClientProvider).dio);
});

class AccountRepository {
  final Dio _dio;
  AccountRepository(this._dio);

  Future<List<Account>> getAll() async {
    try {
      final res = await _dio.get('/accounts');
      return (res.data as List).map((e) => _toModel(AccountDto.fromJson(e))).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Account> create(String name, double initialBalance) async {
    try {
      final dto = AccountRequestDto(name: name, initialBalance: initialBalance);
      final res = await _dio.post('/accounts', data: dto.toJson());
      return _toModel(AccountDto.fromJson(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Account> update(String id, String name) async {
    try {
      final res = await _dio.put('/accounts/$id', data: {'name': name});
      return _toModel(AccountDto.fromJson(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete('/accounts/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Account _toModel(AccountDto dto) => Account(
    id: dto.id,
    name: dto.name,
    currentBalance: dto.currentBalance,
    createdAt: DateTime.parse(dto.createdAt),
  );
}
