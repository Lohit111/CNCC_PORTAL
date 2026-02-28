class StoreRequestModel {
  final String id;
  final String parentRequestId;
  final String requestedBy;
  final String description;
  final String status;
  final String? respondedBy;
  final String? responseComment;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? requesterEmail;

  StoreRequestModel({
    required this.id,
    required this.parentRequestId,
    required this.requestedBy,
    required this.description,
    required this.status,
    this.respondedBy,
    this.responseComment,
    required this.createdAt,
    required this.updatedAt,
    this.requesterEmail,
  });

  factory StoreRequestModel.fromJson(Map<String, dynamic> json) {
    return StoreRequestModel(
      id: json['id'],
      parentRequestId: json['parent_request_id'],
      requestedBy: json['requested_by'],
      description: json['description'],
      status: json['status'],
      respondedBy: json['responded_by'],
      responseComment: json['response_comment'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      requesterEmail: json['requester_email'],
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
      'requester_email': requesterEmail,
    };
  }
}
