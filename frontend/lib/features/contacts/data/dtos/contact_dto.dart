// lib/features/contacts/data/dtos/contact_dto.dart

class ContactDto {
  final String id;
  final String name;
  final String? description;
  final String createdAt;
  const ContactDto({required this.id, required this.name, this.description, required this.createdAt});
  factory ContactDto.fromJson(Map<String, dynamic> json) => ContactDto(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    createdAt: json['createdAt'] as String,
  );
}
