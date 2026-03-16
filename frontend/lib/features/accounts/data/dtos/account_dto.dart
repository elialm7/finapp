// lib/features/accounts/data/dtos/account_dto.dart

class AccountDto {
  final String id;
  final String name;
  final double currentBalance;
  final String createdAt;

  const AccountDto({
    required this.id,
    required this.name,
    required this.currentBalance,
    required this.createdAt,
  });

  factory AccountDto.fromJson(Map<String, dynamic> json) => AccountDto(
    id: json['id'] as String,
    name: json['name'] as String,
    currentBalance: (json['currentBalance'] as num).toDouble(),
    createdAt: json['createdAt'] as String,
  );
}

class AccountRequestDto {
  final String name;
  final double initialBalance;

  const AccountRequestDto({required this.name, this.initialBalance = 0.0});

  Map<String, dynamic> toJson() => {'name': name, 'initialBalance': initialBalance};
}
