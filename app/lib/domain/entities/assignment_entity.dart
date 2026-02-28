class Assignment {
  final int id;
  final String requestId;
  final String staffId;
  final String assignedBy;
  final bool isActive;
  final DateTime createdAt;

  Assignment({
    required this.id,
    required this.requestId,
    required this.staffId,
    required this.assignedBy,
    required this.isActive,
    required this.createdAt,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'] as int,
      requestId: json['request_id'] as String,
      staffId: json['staff_id'] as String,
      assignedBy: json['assigned_by'] as String,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
