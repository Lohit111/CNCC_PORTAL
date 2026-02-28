class MainType {
  final int id;
  final String name;
  final String createdBy;
  final DateTime createdAt;

  MainType({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.createdAt,
  });

  factory MainType.fromJson(Map<String, dynamic> json) {
    return MainType(
      id: json['id'] as int,
      name: json['name'] as String,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class SubType {
  final int id;
  final String name;
  final int mainTypeId;

  SubType({
    required this.id,
    required this.name,
    required this.mainTypeId,
  });

  factory SubType.fromJson(Map<String, dynamic> json) {
    return SubType(
      id: json['id'] as int,
      name: json['name'] as String,
      mainTypeId: json['main_type_id'] as int,
    );
  }
}
