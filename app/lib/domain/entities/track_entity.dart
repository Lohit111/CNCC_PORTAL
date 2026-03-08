class Track {
  final int id;
  final String? requestId;
  final String? storeRequestId;
  final String actionType;
  final String performedBy;
  final String performedByRole;
  final String? comment;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  Track({
    required this.id,
    this.requestId,
    this.storeRequestId,
    required this.actionType,
    required this.performedBy,
    required this.performedByRole,
    this.comment,
    this.metadata,
    required this.createdAt,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'] as int,
      requestId: json['request_id'] as String?,
      storeRequestId: json['store_request_id'] as String?,
      actionType: json['action_type'] as String,
      performedBy: json['performed_by'] as String,
      performedByRole: json['performed_by_role'] as String,
      comment: json['comment'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'request_id': requestId,
      'store_request_id': storeRequestId,
      'action_type': actionType,
      'performed_by': performedBy,
      'performed_by_role': performedByRole,
      'comment': comment,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper method to get display text for action type
  String get actionDisplayText {
    switch (actionType) {
      case 'RAISED':
        // Check metadata to see if this is an update or initial creation
        if (metadata != null && metadata!['old_status'] != null) {
          return 'User Updated Request';
        }
        return 'Request Created';
      case 'REPLIED':
        return 'Admin Replied';
      case 'REJECTED':
        return 'Request Rejected';
      case 'ASSIGNED':
        return 'Assigned to Staff';
      case 'REASSIGN_REQUESTED':
        return 'Reassignment Requested';
      case 'IN_PROGRESS':
        return 'Work Started';
      case 'COMPLETED':
        return 'Request Completed';
      case 'STORE_REQUEST_CREATED':
        return 'Store Request Created';
      case 'STORE_REQUEST_APPROVED':
        return 'Store Request Approved';
      case 'STORE_REQUEST_REJECTED':
        return 'Store Request Rejected';
      case 'STORE_REQUEST_FULFILLED':
        return 'Store Request Fulfilled';
      default:
        return actionType;
    }
  }
}
