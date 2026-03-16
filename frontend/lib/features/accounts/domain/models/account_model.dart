// lib/features/accounts/domain/models/account_model.dart

class Account {
  final String id;
  final String name;
  final double currentBalance;
  final DateTime createdAt;

  const Account({
    required this.id,
    required this.name,
    required this.currentBalance,
    required this.createdAt,
  });
}
