// lib/features/dashboard/domain/models/dashboard_model.dart

class CategorySummary {
  final String categoryName;
  final double total;
  final int count;
  const CategorySummary({required this.categoryName, required this.total, required this.count});
}

class DashboardSummary {
  final double totalIncome;
  final double totalExpenses;
  final double netBalance;
  final double totalTransferred;
  final List<CategorySummary> topExpenseCategories;
  final List<CategorySummary> topIncomeCategories;

  const DashboardSummary({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netBalance,
    required this.totalTransferred,
    required this.topExpenseCategories,
    required this.topIncomeCategories,
  });
}
