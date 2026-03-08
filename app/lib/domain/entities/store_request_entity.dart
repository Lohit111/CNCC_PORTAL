class StoreRequest {
  final String id;
  final String parentRequestId;
  final String requestedBy;
  final String description;
  final String status;
  final String? respondedBy;
  final String? responseComment;
  final DateTime createdAt;
  final DateTime updatedAt;

  StoreRequest({
    required this.id,
    required this.parentRequestId,
    required this.requestedBy,
    required this.description,
    required this.status,
    this.respondedBy,
    this.responseComment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StoreRequest.fromJson(Map<String, dynamic> json) {
    return StoreRequest(
      id: json['id'] as String,
      parentRequestId: json['parent_request_id'] as String,
      requestedBy: json['requested_by'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      respondedBy: json['responded_by'] as String?,
      responseComment: json['response_comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parent_request_id': parentRequestId,
      'requested_by': requestedBy,
      'description': description,
      'status': status,
      'responded_by': respondedBy,
      'response_comment': responseComment,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper method to get status display text
  String get statusDisplayText {
    switch (status) {
      case 'PENDING':
        return 'Pending';
      case 'APPROVED':
        return 'Approved';
      case 'REJECTED':
        return 'Rejected';
      case 'FULFILLED':
        return 'Fulfilled';
      default:
        return status;
    }
  }
}
