// lib/features/dashboard/data/dtos/dashboard_dto.dart

class CategorySummaryDto {
  final String categoryName;
  final double total;
  final int count;
  const CategorySummaryDto({required this.categoryName, required this.total, required this.count});
  factory CategorySummaryDto.fromJson(Map<String, dynamic> json) => CategorySummaryDto(
    categoryName: json['categoryName'] as String,
    total: (json['total'] as num).toDouble(),
    count: (json['count'] as num).toInt(),
  );
}

class DashboardDto {
  final double totalIncome;
  final double totalExpenses;
  final double netBalance;
  final double totalTransferred;
  final List<CategorySummaryDto> topExpenseCategories;
  final List<CategorySummaryDto> topIncomeCategories;

  const DashboardDto({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netBalance,
    required this.totalTransferred,
    required this.topExpenseCategories,
    required this.topIncomeCategories,
  });

  factory DashboardDto.fromJson(Map<String, dynamic> json) => DashboardDto(
    totalIncome: (json['totalIncome'] as num).toDouble(),
    totalExpenses: (json['totalExpenses'] as num).toDouble(),
    netBalance: (json['netBalance'] as num).toDouble(),
    totalTransferred: (json['totalTransferred'] as num).toDouble(),
    topExpenseCategories: (json['topExpenseCategories'] as List)
        .map((e) => CategorySummaryDto.fromJson(e)).toList(),
    topIncomeCategories: (json['topIncomeCategories'] as List)
        .map((e) => CategorySummaryDto.fromJson(e)).toList(),
  );
}
