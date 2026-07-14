class LeaveType {
  final int id;
  final String name;
  final String accrualType;
  final int maxCarryForward;
  final bool encashable;

  LeaveType({
    required this.id,
    required this.name,
    required this.accrualType,
    required this.maxCarryForward,
    required this.encashable,
  });

  factory LeaveType.fromJson(Map<String, dynamic> json) {
    return LeaveType(
      id: json['id'],
      name: json['name'],
      accrualType: json['accrual_type'] ?? 'Monthly',
      maxCarryForward: json['max_carry_forward'] ?? 0,
      encashable: json['encashable'] == 1 || json['encashable'] == true,
    );
  }
}

class LeaveBalance {
  final int id;
  final int employeeId;
  final int leaveTypeId;
  final String leaveTypeName;
  final int year;
  final double opening;
  final double accrued;
  final double used;
  final double balance;

  LeaveBalance({
    required this.id,
    required this.employeeId,
    required this.leaveTypeId,
    required this.leaveTypeName,
    required this.year,
    required this.opening,
    required this.accrued,
    required this.used,
    required this.balance,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      id: json['id'],
      employeeId: json['employee_id'],
      leaveTypeId: json['leave_type_id'],
      leaveTypeName: json['leave_type_name'] ?? 'Leave',
      year: json['year'],
      opening: double.tryParse(json['opening'].toString()) ?? 0.0,
      accrued: double.tryParse(json['accrued'].toString()) ?? 0.0,
      used: double.tryParse(json['used'].toString()) ?? 0.0,
      balance: double.tryParse(json['balance'].toString()) ?? 0.0,
    );
  }
}

class LeaveApplication {
  final int id;
  final int employeeId;
  final String? employeeName;
  final String? employeeCode;
  final int leaveTypeId;
  final String leaveTypeName;
  final String fromDate;
  final String toDate;
  final double days;
  final String reason;
  final String status;
  final String createdAt;

  LeaveApplication({
    required this.id,
    required this.employeeId,
    this.employeeName,
    this.employeeCode,
    required this.leaveTypeId,
    required this.leaveTypeName,
    required this.fromDate,
    required this.toDate,
    required this.days,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  factory LeaveApplication.fromJson(Map<String, dynamic> json) {
    return LeaveApplication(
      id: json['id'],
      employeeId: json['employee_id'],
      employeeName: json['employee_name'],
      employeeCode: json['employee_code'],
      leaveTypeId: json['leave_type_id'],
      leaveTypeName: json['leave_type_name'] ?? 'Leave',
      fromDate: json['from_date'],
      toDate: json['to_date'],
      days: double.tryParse(json['days'].toString()) ?? 0.0,
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'Pending',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class Holiday {
  final int id;
  final int? locationId;
  final String date;
  final String name;

  Holiday({
    required this.id,
    this.locationId,
    required this.date,
    required this.name,
  });

  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      id: json['id'],
      locationId: json['location_id'],
      date: json['date'],
      name: json['name'],
    );
  }
}
