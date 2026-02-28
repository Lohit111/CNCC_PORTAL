class CommentModel {
  final int id;
  final String requestId;
  final String senderId;
  final String senderRole;
  final String message;
  final String type;
  final DateTime createdAt;
  final String? senderEmail;

  CommentModel({
    required this.id,
    required this.requestId,
    required this.senderId,
    required this.senderRole,
    required this.message,
    required this.type,
    required this.createdAt,
    this.senderEmail,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'],
      requestId: json['request_id'],
      senderId: json['sender_id'],
      senderRole: json['sender_role'],
      message: json['message'],
      type: json['type'],
      createdAt: DateTime.parse(json['created_at']),
      senderEmail: json['sender_email'],
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
      'sender_email': senderEmail,
    };
  }
}
