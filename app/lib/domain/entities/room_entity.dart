class Room {
  final int id;
  final String roomNo;

  Room({required this.id, required this.roomNo});

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as int,
      roomNo: json['room_no'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'room_no': roomNo};
}
