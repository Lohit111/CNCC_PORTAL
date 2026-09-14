class Department {
  final int id;
  final String department;

  Department({required this.id, required this.department});

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] as int,
      department: json['department'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'department': department};
}
