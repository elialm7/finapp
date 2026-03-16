// lib/features/categories/domain/models/category_model.dart
import '../../../transactions/domain/models/transaction_model.dart';

class Category {
  final String id;
  final String name;
  final MovementType type;
  const Category({required this.id, required this.name, required this.type});
}
