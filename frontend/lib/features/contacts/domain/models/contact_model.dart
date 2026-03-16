// lib/features/contacts/domain/models/contact_model.dart
class Contact {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  const Contact({required this.id, required this.name, this.description, required this.createdAt});
}
