// lib/core/network/api_exception.dart
import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException({required this.message, this.statusCode});

  factory ApiException.fromDioException(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      final message = data is Map ? data['message'] ?? 'Error desconocido' : 'Error desconocido';
      return ApiException(message: message, statusCode: e.response!.statusCode);
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const ApiException(message: 'Tiempo de conexión agotado');
    }
    return ApiException(message: e.message ?? 'Error de red');
  }

  @override
  String toString() => message;
}
