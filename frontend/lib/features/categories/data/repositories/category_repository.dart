// lib/features/categories/data/repositories/category_repository.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../dtos/category_dto.dart';
import '../../domain/models/category_model.dart';
import '../../../transactions/domain/models/transaction_model.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.read(apiClientProvider).dio);
});

class CategoryRepository {
  final Dio _dio;
  CategoryRepository(this._dio);

  Future<List<Category>> getAll() async {
    try {
      final res = await _dio.get('/categories');
      return (res.data as List).map((e) => _toModel(CategoryDto.fromJson(e))).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Category> create(String name, String type) async {
    try {
      final res = await _dio.post('/categories', data: {'name': name, 'type': type});
      return _toModel(CategoryDto.fromJson(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Category> update(String id, String name) async {
    try {
      final res = await _dio.put('/categories/$id', data: {'name': name, 'type': 'EXPENSE'});
      return _toModel(CategoryDto.fromJson(res.data));
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete('/categories/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Category _toModel(CategoryDto dto) => Category(
    id: dto.id,
    name: dto.name,
    type: MovementTypeExt.fromApi(dto.type),
  );
}
