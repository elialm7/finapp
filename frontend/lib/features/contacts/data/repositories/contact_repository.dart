// lib/features/contacts/data/repositories/contact_repository.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../dtos/contact_dto.dart';
import '../../domain/models/contact_model.dart';

final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  return ContactRepository(ref.read(apiClientProvider).dio);
});

class ContactRepository {
  final Dio _dio;
  ContactRepository(this._dio);

  Future<List<Contact>> getAll() async {
    try {
      final res = await _dio.get('/contacts');
      return (res.data as List).map((e) => _toModel(ContactDto.fromJson(e))).toList();
    } on DioException catch (e) { throw ApiException.fromDioException(e); }
  }

  Future<Contact> create(String name, String? description) async {
    try {
      final res = await _dio.post('/contacts', data: {'name': name, 'description': description});
      return _toModel(ContactDto.fromJson(res.data));
    } on DioException catch (e) { throw ApiException.fromDioException(e); }
  }

  Future<Contact> update(String id, String name, String? description) async {
    try {
      final res = await _dio.put('/contacts/$id', data: {'name': name, 'description': description});
      return _toModel(ContactDto.fromJson(res.data));
    } on DioException catch (e) { throw ApiException.fromDioException(e); }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete('/contacts/$id');
    } on DioException catch (e) { throw ApiException.fromDioException(e); }
  }

  Contact _toModel(ContactDto dto) => Contact(
    id: dto.id,
    name: dto.name,
    description: dto.description,
    createdAt: DateTime.parse(dto.createdAt),
  );
}
