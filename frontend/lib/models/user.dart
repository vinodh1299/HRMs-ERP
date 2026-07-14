class User {
  final int id;
  final String email;
  final int? employeeId;
  final String role;

  User({
    required this.id,
    required this.email,
    this.employeeId,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      employeeId: json['employee_id'],
      role: json['role'] ?? json['role_name'] ?? 'Employee',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'employee_id': employeeId,
      'role_name': role,
    };
  }
}
