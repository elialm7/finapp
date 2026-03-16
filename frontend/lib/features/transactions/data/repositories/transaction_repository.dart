// lib/features/transactions/data/repositories/transaction_repository.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/date_utils.dart';
import '../dtos/transaction_dto.dart';
import '../../domain/models/transaction_model.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.read(apiClientProvider).dio);
});

class TransactionPage {
  final List<Transaction> items;
  final int total;
  final int page;
  final int size;
  const TransactionPage({required this.items, required this.total, required this.page, required this.size});
}

class TransactionRepository {
  final Dio _dio;
  TransactionRepository(this._dio);

  Future<TransactionPage> getAll({
    required DateTime from,
    required DateTime to,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final res = await _dio.get('/transactions', queryParameters: {
        'from': AppDateUtils.toIso(from),
        'to': AppDateUtils.toIso(to),
        'page': page,
        'size': size,
      });
      final pageDto = TransactionPageDto.fromJson(res.data);
      return TransactionPage(
        items: pageDto.items.map(_toModel).toList(),
        total: pageDto.total,
        page: pageDto.page,
        size: pageDto.size,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Transaction> create(TransactionRequestDto dto) async {
    try {
      final res = await _dio.post('/transactions', data: dto.toJson());
      return _toModel(TransactionDto.fromJson(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete('/transactions/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Transaction _toModel(TransactionDto dto) => Transaction(
    id: dto.id,
    accountId: dto.accountId,
    accountName: dto.accountName,
    destinationAccountId: dto.destinationAccountId,
    destinationAccountName: dto.destinationAccountName,
    contactId: dto.contactId,
    contactName: dto.contactName,
    categoryId: dto.categoryId,
    categoryName: dto.categoryName,
    amount: dto.amount,
    type: MovementTypeExt.fromApi(dto.type),
    description: dto.description,
    transactionDate: DateTime.parse(dto.transactionDate),
    createdAt: dto.createdAt != null ? DateTime.parse(dto.createdAt!) : null,
  );
}
