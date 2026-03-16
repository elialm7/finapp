// lib/features/categories/data/dtos/category_dto.dart

class CategoryDto {
  final String id;
  final String name;
  final String type;
  const CategoryDto({required this.id, required this.name, required this.type});
  factory CategoryDto.fromJson(Map<String, dynamic> json) => CategoryDto(
    id: json['id'] as String,
    name: json['name'] as String,
    type: json['type'] as String,
  );
}
