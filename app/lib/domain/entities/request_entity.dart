class Request {
  final String id;
  final String raisedBy;
  final String mainType;
  final String subType;
  final String description;
  final String roomNo;
  final String phoneNo;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Request({
    required this.id,
    required this.raisedBy,
    required this.mainType,
    required this.subType,
    required this.description,
    required this.roomNo,
    required this.phoneNo,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Request.fromJson(Map<String, dynamic> json) {
    return Request(
      id: json['id'] as String,
      raisedBy: json['raised_by'] as String,
      mainType: json['main_type'] as String,
      subType: json['sub_type'] as String,
      description: json['description'] as String,
      roomNo: json['room_no'] as String,
      phoneNo: json['phone_no'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse('${json['created_at']}Z').toLocal(),
      updatedAt: DateTime.parse('${json['updated_at']}Z').toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'raised_by': raisedBy,
      'main_type': mainType,
      'sub_type': subType,
      'description': description,
      'room_no': roomNo,
      'phone_no': phoneNo,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

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
