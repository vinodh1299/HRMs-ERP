class AttendanceLog {
  final int? id;
  final int employeeId;
  final String date;
  final String? checkIn;
  final String? checkOut;
  final String source;
  final double? latitude;
  final double? longitude;

  AttendanceLog({
    this.id,
    required this.employeeId,
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.source,
    this.latitude,
    this.longitude,
  });

  factory AttendanceLog.fromJson(Map<String, dynamic> json) {
    return AttendanceLog(
      id: json['id'],
      employeeId: json['employee_id'],
      date: json['date'],
      checkIn: json['check_in'],
      checkOut: json['check_out'],
      source: json['source'] ?? 'Web',
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
    );
  }
}

class RegularizationRequest {
  final int id;
  final int employeeId;
  final String? employeeName;
  final String? employeeCode;
  final String date;
  final String reason;
  final String? requestedIn;
  final String? requestedOut;
  final String status;
  final String createdAt;

  RegularizationRequest({
    required this.id,
    required this.employeeId,
    this.employeeName,
    this.employeeCode,
    required this.date,
    required this.reason,
    this.requestedIn,
    this.requestedOut,
    required this.status,
    required this.createdAt,
  });

  factory RegularizationRequest.fromJson(Map<String, dynamic> json) {
    return RegularizationRequest(
      id: json['id'],
      employeeId: json['employee_id'],
      employeeName: json['employee_name'],
      employeeCode: json['employee_code'],
      date: json['date'],
      reason: json['reason'] ?? '',
      requestedIn: json['requested_in'],
      requestedOut: json['requested_out'],
      status: json['status'] ?? 'Pending',
      createdAt: json['created_at'] ?? '',
    );
  }
}
