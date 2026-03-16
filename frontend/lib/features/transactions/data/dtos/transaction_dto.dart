// lib/features/transactions/data/dtos/transaction_dto.dart

class TransactionDto {
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
  final String type;
  final String? description;
  final String transactionDate;
  final String? createdAt;

  const TransactionDto({
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

  factory TransactionDto.fromJson(Map<String, dynamic> json) => TransactionDto(
    id: json['id'] as String,
    accountId: json['accountId'] as String,
    accountName: json['accountName'] as String?,
    destinationAccountId: json['destinationAccountId'] as String?,
    destinationAccountName: json['destinationAccountName'] as String?,
    contactId: json['contactId'] as String?,
    contactName: json['contactName'] as String?,
    categoryId: json['categoryId'] as String?,
    categoryName: json['categoryName'] as String?,
    amount: (json['amount'] as num).toDouble(),
    type: json['type'] as String,
    description: json['description'] as String?,
    transactionDate: json['transactionDate'] as String,
    createdAt: json['createdAt'] as String?,
  );
}

class TransactionRequestDto {
  final String accountId;
  final String? destinationAccountId;
  final String? contactId;
  final String? categoryId;
  final String? newCategoryName;
  final double amount;
  final String type;
  final String? description;
  final String transactionDate;

  const TransactionRequestDto({
    required this.accountId,
    this.destinationAccountId,
    this.contactId,
    this.categoryId,
    this.newCategoryName,
    required this.amount,
    required this.type,
    this.description,
    required this.transactionDate,
  });

  Map<String, dynamic> toJson() => {
    'accountId': accountId,
    if (destinationAccountId != null) 'destinationAccountId': destinationAccountId,
    if (contactId != null) 'contactId': contactId,
    if (categoryId != null) 'categoryId': categoryId,
    if (newCategoryName != null) 'newCategoryName': newCategoryName,
    'amount': amount,
    'type': type,
    if (description != null) 'description': description,
    'transactionDate': transactionDate,
  };
}

class TransactionPageDto {
  final List<TransactionDto> items;
  final int total;
  final int page;
  final int size;

  const TransactionPageDto({
    required this.items,
    required this.total,
    required this.page,
    required this.size,
  });

  factory TransactionPageDto.fromJson(Map<String, dynamic> json) => TransactionPageDto(
    items: (json['items'] as List).map((e) => TransactionDto.fromJson(e)).toList(),
    total: json['total'] as int,
    page: json['page'] as int,
    size: json['size'] as int,
  );
}
