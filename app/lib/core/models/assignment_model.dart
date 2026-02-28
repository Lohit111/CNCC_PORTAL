class AssignmentModel {
  final int id;
  final String requestId;
  final String staffId;
  final String assignedBy;
  final bool isActive;
  final DateTime createdAt;
  final String? staffEmail;

  AssignmentModel({
    required this.id,
    required this.requestId,
    required this.staffId,
    required this.assignedBy,
    required this.isActive,
    required this.createdAt,
    this.staffEmail,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    return AssignmentModel(
      id: json['id'],
      requestId: json['request_id'],
      staffId: json['staff_id'],
      assignedBy: json['assigned_by'],
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at']),
      staffEmail: json['staff_email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'request_id': requestId,
      'staff_id': staffId,
      'assigned_by': assignedBy,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'staff_email': staffEmail,
    };
  }
}
