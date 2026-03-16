// lib/features/transactions/presentation/providers/transaction_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/date_utils.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../domain/models/transaction_model.dart';
import '../../../accounts/presentation/providers/account_provider.dart';

// Date range state
final dateRangeProvider = StateProvider<DateTimeRange>((ref) {
  return AppDateUtils.currentMonth();
});

// Transactions list
final transactionsProvider = StateNotifierProvider<TransactionsNotifier, AsyncValue<TransactionPage>>((ref) {
  final range = ref.watch(dateRangeProvider);
  return TransactionsNotifier(ref.read(transactionRepositoryProvider), range);
});

class TransactionsNotifier extends StateNotifier<AsyncValue<TransactionPage>> {
  final TransactionRepository _repo;
  final DateTimeRange _range;
  int _page = 0;

  TransactionsNotifier(this._repo, this._range) : super(const AsyncLoading()) {
    load();
  }

  Future<void> load({int page = 0}) async {
    _page = page;
    if (page == 0) state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getAll(
      from: _range.start,
      to: _range.end,
      page: page,
    ));
  }

  Future<void> create(dynamic dto, WidgetRef ref) async {
    await _repo.create(dto);
    await load();
    ref.read(accountsProvider.notifier).load();
  }

  Future<void> delete(String id, WidgetRef ref) async {
    await _repo.delete(id);
    await load(page: _page);
    ref.read(accountsProvider.notifier).load();
  }
}
