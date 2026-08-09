class MainType {
  final int id;
  final String name;

  MainType({
    required this.id,
    required this.name,
  });

  factory MainType.fromJson(Map<String, dynamic> json) {
    return MainType(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'main_type_id': mainTypeId,
    };
  }
}
