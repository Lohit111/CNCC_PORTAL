class RequestModel {
  final String id;
  final String raisedBy;
  final int mainTypeId;
  final int subTypeId;
  final String description;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? raiserEmail;
  final String? mainTypeName;
  final String? subTypeName;
  final int? commentsCount;
  final int? assignmentsCount;

  RequestModel({
    required this.id,
    required this.raisedBy,
    required this.mainTypeId,
    required this.subTypeId,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.raiserEmail,
    this.mainTypeName,
    this.subTypeName,
    this.commentsCount,
    this.assignmentsCount,
  });

  factory RequestModel.fromJson(Map<String, dynamic> json) {
    return RequestModel(
      id: json['id'],
      raisedBy: json['raised_by'],
      mainTypeId: json['main_type_id'],
      subTypeId: json['sub_type_id'],
      description: json['description'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      raiserEmail: json['raiser_email'],
      mainTypeName: json['main_type_name'],
      subTypeName: json['sub_type_name'],
      commentsCount: json['comments_count'],
      assignmentsCount: json['assignments_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'raised_by': raisedBy,
      'main_type_id': mainTypeId,
      'sub_type_id': subTypeId,
      'description': description,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'raiser_email': raiserEmail,
      'main_type_name': mainTypeName,
      'sub_type_name': subTypeName,
      'comments_count': commentsCount,
      'assignments_count': assignmentsCount,
    };
  }
}
