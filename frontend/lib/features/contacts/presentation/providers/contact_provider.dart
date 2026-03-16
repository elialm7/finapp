// lib/features/contacts/presentation/providers/contact_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/contact_repository.dart';
import '../../domain/models/contact_model.dart';

final contactsProvider = StateNotifierProvider<ContactsNotifier, AsyncValue<List<Contact>>>((ref) {
  return ContactsNotifier(ref.read(contactRepositoryProvider));
});

class ContactsNotifier extends StateNotifier<AsyncValue<List<Contact>>> {
  final ContactRepository _repo;
  ContactsNotifier(this._repo) : super(const AsyncLoading()) { load(); }

  Future<void> load() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getAll());
  }

  Future<void> create(String name, String? description) async {
    await _repo.create(name, description);
    await load();
  }

  Future<void> update(String id, String name, String? description) async {
    await _repo.update(id, name, description);
    await load();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await load();
  }
}
