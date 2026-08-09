class Assignment {
  final int id;
  final String requestId;
  final String staffId;
  final int trackId;
  final bool isActive;
  final DateTime createdAt;

  Assignment({
    required this.id,
    required this.requestId,
    required this.staffId,
    required this.trackId,
    required this.isActive,
    required this.createdAt,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'] as int,
      requestId: json['request_id'] as String,
      staffId: json['staff_id'] as String,
      trackId: json['track_id'] as int,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse('${json['created_at']}Z').toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'request_id': requestId,
      'staff_id': staffId,
      'track_id': trackId,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
