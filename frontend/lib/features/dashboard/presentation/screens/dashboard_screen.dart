// lib/features/dashboard/presentation/screens/dashboard_screen.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/dashboard_provider.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/widgets/date_range_picker_button.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../domain/models/dashboard_model.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(dashboardProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final currency = ref.watch(currentCurrencyProvider);
    final range = ref.watch(dateRangeProvider);
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Resumen'),
            Text(
              authState.email ?? '',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          DateRangePickerButton(
            range: range,
            onChanged: (r) {
              ref.read(dateRangeProvider.notifier).state = r;
              ref.read(dashboardProvider.notifier).load();
              ref.read(transactionsProvider.notifier).load();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/transactions/new'),
        icon: const Icon(Icons.add),
        label: const Text(''),
      ),
      body: dashAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.read(dashboardProvider.notifier).load()),
        data: (summary) => _DashboardContent(
          summary: summary,
          currency: currency,
          accountsAsync: accountsAsync,
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final DashboardSummary summary;
  final String currency;
  final AsyncValue accountsAsync;

  const _DashboardContent({
    required this.summary,
    required this.currency,
    required this.accountsAsync,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Net balance hero card
          _NetBalanceCard(summary: summary, currency: currency),
          const SizedBox(height: 16),

          // Income / Expense row
          Row(
            children: [
              Expanded(child: _StatCard(
                label: 'Ingresos',
                amount: summary.totalIncome,
                currency: currency,
                color: AppTheme.income,
                icon: Icons.arrow_downward_rounded,
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(
                label: 'Gastos',
                amount: summary.totalExpenses,
                currency: currency,
                color: AppTheme.expense,
                icon: Icons.arrow_upward_rounded,
              )),
            ],
          ),
          const SizedBox(height: 12),

          // Transfers card
          if (summary.totalTransferred > 0)
            _StatCard(
              label: 'Transferencias',
              amount: summary.totalTransferred,
              currency: currency,
              color: AppTheme.transfer,
              icon: Icons.swap_horiz_rounded,
              fullWidth: true,
            ),
          const SizedBox(height: 20),

          // Pie chart for expenses
          if (summary.topExpenseCategories.isNotEmpty) ...[
            const _SectionTitle('Top Gastos por categoría'),
            const SizedBox(height: 12),
            _CategoryPieChart(
              categories: summary.topExpenseCategories,
              color: AppTheme.expense,
              currency: currency,
            ),
            const SizedBox(height: 20),
          ],

          // Top income categories
          if (summary.topIncomeCategories.isNotEmpty) ...[
            const _SectionTitle('Top Ingresos por categoría'),
            const SizedBox(height: 12),
            _CategoryList(categories: summary.topIncomeCategories, color: AppTheme.income, currency: currency),
            const SizedBox(height: 20),
          ],

          // Accounts summary
          const _SectionTitle('Cuentas'),
          const SizedBox(height: 12),
          accountsAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const SizedBox(),
            data: (accounts) => Column(
              children: (accounts as List).map((a) => _AccountSummaryTile(account: a, currency: currency)).toList(),
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _NetBalanceCard extends StatelessWidget {
  final DashboardSummary summary;
  final String currency;
  const _NetBalanceCard({required this.summary, required this.currency});

  @override
  Widget build(BuildContext context) {
    final isPositive = summary.netBalance >= 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [const Color(0xFF2ED47A), const Color(0xFF1AAD5A)]
              : [AppTheme.expense, const Color(0xFFCC4444)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Balance neto del período', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(summary.netBalance, currency),
            style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final double amount;
  final String currency;
  final Color color;
  final IconData icon;
  final bool fullWidth;

  const _StatCard({
    required this.label,
    required this.amount,
    required this.currency,
    required this.color,
    required this.icon,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: color)),
                Text(
                  CurrencyFormatter.format(amount, currency),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
  );
}

class _CategoryPieChart extends StatelessWidget {
  final List<CategorySummary> categories;
  final Color color;
  final String currency;
  const _CategoryPieChart({required this.categories, required this.color, required this.currency});

  static const _colors = [
    Color(0xFFFF6B6B), Color(0xFFFF8E53), Color(0xFFFFBE0B),
    Color(0xFF4ECDC4), Color(0xFF6C63FF),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: categories.asMap().entries.map((e) {
                    final c = _colors[e.key % _colors.length];
                    return PieChartSectionData(
                      value: e.value.total,
                      color: c,
                      title: '',
                      radius: 60,
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...categories.asMap().entries.map((e) {
              final c = _colors[e.key % _colors.length];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(e.value.categoryName, style: const TextStyle(fontSize: 13))),
                    Text(
                      CurrencyFormatter.format(e.value.total, currency),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  final List<CategorySummary> categories;
  final Color color;
  final String currency;
  const _CategoryList({required this.categories, required this.color, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: categories.map((c) => ListTile(
            dense: true,
            leading: Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            title: Text(c.categoryName, style: const TextStyle(fontSize: 14)),
            trailing: Text(
              CurrencyFormatter.format(c.total, currency),
              style: TextStyle(fontWeight: FontWeight.w700, color: color),
            ),
          )).toList(),
        ),
      ),
    );
  }
}

class _AccountSummaryTile extends StatelessWidget {
  final dynamic account;
  final String currency;
  const _AccountSummaryTile({required this.account, required this.currency});

  @override
  Widget build(BuildContext context) {
    final isPositive = (account.currentBalance as double) >= 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.account_balance_wallet_outlined, color: AppTheme.primary, size: 20),
        ),
        title: Text(account.name as String, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: Text(
          CurrencyFormatter.format(account.currentBalance as double, currency),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isPositive ? AppTheme.income : AppTheme.expense,
          ),
        ),
      ),
    );
  }
}
