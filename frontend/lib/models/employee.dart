class Employee {
  final int id;
  final String employeeCode;
  final String firstName;
  final String lastName;
  final String dob;
  final String gender;
  final String personalEmail;
  final String phone;
  final String? pan;
  final String? aadhaar;
  final int? departmentId;
  final String? departmentName;
  final int? designationId;
  final String? designationTitle;
  final int? locationId;
  final String? locationName;
  final int? reportingManagerId;
  final String? managerName;
  final String dateOfJoining;
  final String employmentType;
  final String status;

  Employee({
    required this.id,
    required this.employeeCode,
    required this.firstName,
    required this.lastName,
    required this.dob,
    required this.gender,
    required this.personalEmail,
    required this.phone,
    this.pan,
    this.aadhaar,
    this.departmentId,
    this.departmentName,
    this.designationId,
    this.designationTitle,
    this.locationId,
    this.locationName,
    this.reportingManagerId,
    this.managerName,
    required this.dateOfJoining,
    required this.employmentType,
    required this.status,
  });

  String get fullName => '$firstName $lastName';

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      employeeCode: json['employee_code'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      dob: json['dob'] ?? '',
      gender: json['gender'] ?? 'Other',
      personalEmail: json['personal_email'] ?? '',
      phone: json['phone'] ?? '',
      pan: json['pan'],
      aadhaar: json['aadhaar'],
      departmentId: json['department_id'],
      departmentName: json['department_name'],
      designationId: json['designation_id'],
      designationTitle: json['designation_title'],
      locationId: json['location_id'],
      locationName: json['location_name'],
      reportingManagerId: json['reporting_manager_id'],
      managerName: json['manager_name'],
      dateOfJoining: json['date_of_joining'] ?? '',
      employmentType: json['employment_type'] ?? 'Full-Time',
      status: json['status'] ?? 'Active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_code': employeeCode,
      'first_name': firstName,
      'last_name': lastName,
      'dob': dob,
      'gender': gender,
      'personal_email': personalEmail,
      'phone': phone,
      'pan': pan,
      'aadhaar': aadhaar,
      'department_id': departmentId,
      'designation_id': designationId,
      'location_id': locationId,
      'reporting_manager_id': reportingManagerId,
      'date_of_joining': dateOfJoining,
      'employment_type': employmentType,
      'status': status,
    };
  }
}
