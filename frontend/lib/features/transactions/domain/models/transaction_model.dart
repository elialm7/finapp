// lib/features/transactions/domain/models/transaction_model.dart

enum MovementType { income, expense, transfer }

extension MovementTypeExt on MovementType {
  String get label {
    switch (this) {
      case MovementType.income: return 'Ingreso';
      case MovementType.expense: return 'Gasto';
      case MovementType.transfer: return 'Transferencia';
    }
  }

  String get apiValue {
    switch (this) {
      case MovementType.income: return 'INCOME';
      case MovementType.expense: return 'EXPENSE';
      case MovementType.transfer: return 'TRANSFER';
    }
  }

  static MovementType fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'INCOME': return MovementType.income;
      case 'EXPENSE': return MovementType.expense;
      case 'TRANSFER': return MovementType.transfer;
      default: throw ArgumentError('Unknown type: $value');
    }
  }
}

class Transaction {
  final String id;
  final String accountId;
  final String? accountName;
  final String? destinationAccountId;
  final String? destinationAccountName;
  final String? contactId;
  final String? contactName;
  final String? categoryId;
  final String? categoryName;
  final double amount;
  final MovementType type;
  final String? description;
  final DateTime transactionDate;
  final DateTime? createdAt;

  const Transaction({
    required this.id,
    required this.accountId,
    this.accountName,
    this.destinationAccountId,
    this.destinationAccountName,
    this.contactId,
    this.contactName,
    this.categoryId,
    this.categoryName,
    required this.amount,
    required this.type,
    this.description,
    required this.transactionDate,
    this.createdAt,
  });

  String get subtitle {
    if (contactName != null) return contactName!;
    if (destinationAccountName != null) return '→ $destinationAccountName';
    if (categoryName != null) return categoryName!;
    return accountName ?? '';
  }
}
