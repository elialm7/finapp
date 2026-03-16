// lib/features/accounts/presentation/providers/account_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/account_repository.dart';
import '../../domain/models/account_model.dart';

final accountsProvider = StateNotifierProvider<AccountsNotifier, AsyncValue<List<Account>>>((ref) {
  return AccountsNotifier(ref.read(accountRepositoryProvider));
});

class AccountsNotifier extends StateNotifier<AsyncValue<List<Account>>> {
  final AccountRepository _repo;

  AccountsNotifier(this._repo) : super(const AsyncLoading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getAll());
  }

  Future<void> create(String name, double initialBalance) async {
    await _repo.create(name, initialBalance);
    await load();
  }

  Future<void> update(String id, String name) async {
    await _repo.update(id, name);
    await load();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await load();
  }
}
