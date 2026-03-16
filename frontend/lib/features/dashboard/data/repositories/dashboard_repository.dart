// lib/features/dashboard/data/repositories/dashboard_repository.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/date_utils.dart';
import '../dtos/dashboard_dto.dart';
import '../../domain/models/dashboard_model.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.read(apiClientProvider).dio);
});

class DashboardRepository {
  final Dio _dio;
  DashboardRepository(this._dio);

  Future<DashboardSummary> getSummary(DateTime from, DateTime to) async {
    try {
      final res = await _dio.get('/transactions/dashboard', queryParameters: {
        'from': AppDateUtils.toIso(from),
        'to': AppDateUtils.toIso(to),
      });
      final dto = DashboardDto.fromJson(res.data);
      return DashboardSummary(
        totalIncome: dto.totalIncome,
        totalExpenses: dto.totalExpenses,
        netBalance: dto.netBalance,
        totalTransferred: dto.totalTransferred,
        topExpenseCategories: dto.topExpenseCategories
            .map((e) => CategorySummary(categoryName: e.categoryName, total: e.total, count: e.count))
            .toList(),
        topIncomeCategories: dto.topIncomeCategories
            .map((e) => CategorySummary(categoryName: e.categoryName, total: e.total, count: e.count))
            .toList(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
