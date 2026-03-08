class Request {
  final String id;
  final String raisedBy;
  final int mainTypeId;
  final int subTypeId;
  final String description;
  final String status;
  final String isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Request({
    required this.id,
    required this.raisedBy,
    required this.mainTypeId,
    required this.subTypeId,
    required this.description,
    required this.status,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Request.fromJson(Map<String, dynamic> json) {
    return Request(
      id: json['id'] as String,
      raisedBy: json['raised_by'] as String,
      mainTypeId: json['main_type_id'] as int,
      subTypeId: json['sub_type_id'] as int,
      description: json['description'] as String,
      status: json['status'] as String,
      isActive: json['is_active'] as String? ?? 'true',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
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
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper method to get status display text
  String get statusDisplayText {
    switch (status) {
      case 'RAISED':
        return 'Raised';
      case 'REPLIED':
        return 'Replied';
      case 'REJECTED':
        return 'Rejected';
      case 'ASSIGNED':
        return 'Assigned';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'REASSIGN_REQUESTED':
        return 'Reassignment Requested';
      case 'COMPLETED':
        return 'Completed';
      default:
        return status;
    }
  }
}
