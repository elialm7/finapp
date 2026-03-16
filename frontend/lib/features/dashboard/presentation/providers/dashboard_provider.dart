// lib/features/dashboard/presentation/providers/dashboard_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/date_utils.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../domain/models/dashboard_model.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';

final dashboardProvider = StateNotifierProvider<DashboardNotifier, AsyncValue<DashboardSummary>>((ref) {
  final range = ref.watch(dateRangeProvider);
  return DashboardNotifier(ref.read(dashboardRepositoryProvider), range);
});

class DashboardNotifier extends StateNotifier<AsyncValue<DashboardSummary>> {
  final DashboardRepository _repo;
  final DateTimeRange _range;

  DashboardNotifier(this._repo, this._range) : super(const AsyncLoading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getSummary(_range.start, _range.end));
  }
}
