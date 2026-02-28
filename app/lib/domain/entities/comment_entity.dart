class Comment {
  final int id;
  final String requestId;
  final String senderId;
  final String senderRole;
  final String message;
  final String type;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.requestId,
    required this.senderId,
    required this.senderRole,
    required this.message,
    required this.type,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as int,
      requestId: json['request_id'] as String,
      senderId: json['sender_id'] as String,
      senderRole: json['sender_role'] as String,
      message: json['message'] as String,
      type: json['type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'request_id': requestId,
      'sender_id': senderId,
      'sender_role': senderRole,
      'message': message,
      'type': type,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
