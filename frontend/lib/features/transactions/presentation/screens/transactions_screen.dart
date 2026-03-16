// lib/features/transactions/presentation/screens/transactions_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../../domain/models/transaction_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/date_range_picker_button.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(transactionsProvider);
    final currency = ref.watch(currentCurrencyProvider);
    final range = ref.watch(dateRangeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Movimientos'),
        actions: [
          DateRangePickerButton(
            range: range,
            onChanged: (r) {
              ref.read(dateRangeProvider.notifier).state = r;
              ref.read(transactionsProvider.notifier).load();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/transactions/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
      body: txAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(transactionsProvider.notifier).load(),
        ),
        data: (page) {
          if (page.items.isEmpty) {
            return EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Sin movimientos',
              subtitle: 'No hay transacciones en este período',
              onAction: () => context.go('/transactions/new'),
              actionLabel: 'Agregar movimiento',
            );
          }

          // Group by date
          final grouped = <String, List<Transaction>>{};
          for (final tx in page.items) {
            final key = AppDateUtils.formatDate(tx.transactionDate);
            grouped.putIfAbsent(key, () => []).add(tx);
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: grouped.length,
            itemBuilder: (context, i) {
              final date = grouped.keys.elementAt(i);
              final txs = grouped[date]!;
              return _DateGroup(date: date, transactions: txs, currency: currency, ref: ref);
            },
          );
        },
      ),
    );
  }
}

class _DateGroup extends StatelessWidget {
  final String date;
  final List<Transaction> transactions;
  final String currency;
  final WidgetRef ref;

  const _DateGroup({
    required this.date,
    required this.transactions,
    required this.currency,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            date,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        ...transactions.map((tx) => _TransactionTile(
          transaction: tx,
          currency: currency,
          onDelete: () => _confirmDelete(context, tx),
        )),
      ],
    );
  }

  void _confirmDelete(BuildContext context, Transaction tx) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar movimiento'),
        content: const Text('¿Seguro que deseas eliminar esta transacción? Se revertirá el saldo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              ref.read(transactionsProvider.notifier).delete(tx.id, ref);
              Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: AppTheme.expense)),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final String currency;
  final VoidCallback onDelete;

  const _TransactionTile({
    required this.transaction,
    required this.currency,
    required this.onDelete,
  });

  Color get _typeColor {
    switch (transaction.type) {
      case MovementType.income: return AppTheme.income;
      case MovementType.expense: return AppTheme.expense;
      case MovementType.transfer: return AppTheme.transfer;
    }
  }

  IconData get _typeIcon {
    switch (transaction.type) {
      case MovementType.income: return Icons.arrow_downward_rounded;
      case MovementType.expense: return Icons.arrow_upward_rounded;
      case MovementType.transfer: return Icons.swap_horiz_rounded;
    }
  }

  String get _amountPrefix {
    switch (transaction.type) {
      case MovementType.income: return '+';
      case MovementType.expense: return '-';
      case MovementType.transfer: return '↔';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _typeColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_typeIcon, color: _typeColor, size: 20),
        ),
        title: Text(
          transaction.description ?? transaction.subtitle,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          transaction.subtitle,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$_amountPrefix${CurrencyFormatter.format(transaction.amount, currency)}',
              style: TextStyle(
                color: _typeColor,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.textSecondary),
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
