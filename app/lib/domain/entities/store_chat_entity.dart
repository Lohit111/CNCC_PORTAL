class StoreChat {
  final int id;
  final String storeRequestId;
  final String senderId;
  final String senderRole;
  final String message;
  final DateTime createdAt;

  StoreChat({
    required this.id,
    required this.storeRequestId,
    required this.senderId,
    required this.senderRole,
    required this.message,
    required this.createdAt,
  });

  factory StoreChat.fromJson(Map<String, dynamic> json) {
    return StoreChat(
      id: json['id'] as int,
      storeRequestId: json['store_request_id'] as String,
      senderId: json['sender_id'] as String,
      senderRole: json['sender_role'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store_request_id': storeRequestId,
      'sender_id': senderId,
      'sender_role': senderRole,
      'message': message,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
