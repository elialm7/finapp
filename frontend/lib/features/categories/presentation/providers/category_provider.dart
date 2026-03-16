// lib/features/categories/presentation/providers/category_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/category_repository.dart';
import '../../domain/models/category_model.dart';

final categoriesProvider = StateNotifierProvider<CategoriesNotifier, AsyncValue<List<Category>>>((ref) {
  return CategoriesNotifier(ref.read(categoryRepositoryProvider));
});

class CategoriesNotifier extends StateNotifier<AsyncValue<List<Category>>> {
  final CategoryRepository _repo;
  CategoriesNotifier(this._repo) : super(const AsyncLoading()) { load(); }

  Future<void> load() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getAll());
  }

  Future<void> create(String name, String type) async {
    await _repo.create(name, type);
    await load();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await load();
  }
}
