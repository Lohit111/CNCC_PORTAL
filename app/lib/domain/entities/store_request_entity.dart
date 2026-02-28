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
}
