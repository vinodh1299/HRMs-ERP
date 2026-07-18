import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/employee.dart';
import '../models/attendance.dart';
import '../models/leave.dart';
import '../models/finance.dart';

class ApiService {
  // ─── Local State/Mock Database (Static to persist during application runtime) ───
  static final List<Map<String, dynamic>> _mockDepartments = [
    {'id': 1, 'name': 'Media'},
    {'id': 2, 'name': 'Maintenance'},
    {'id': 3, 'name': 'Finance'},
    {'id': 4, 'name': 'CPD'},
    {'id': 5, 'name': 'HR'},
    {'id': 6, 'name': 'Inventory'},
    {'id': 7, 'name': 'HOB'},
    {'id': 8, 'name': 'IT'},
    {'id': 9, 'name': 'ETS'},
    {'id': 10, 'name': 'AGAPE'},
    {'id': 11, 'name': 'ACHS'},
    {'id': 12, 'name': 'ROH'},
    {'id': 13, 'name': 'ACCASI'},
    {'id': 14, 'name': 'HOJ'},
    {'id': 15, 'name': 'ACCOT'},
    {'id': 16, 'name': 'LTP'},
    {'id': 17, 'name': 'Farm'},
    {'id': 18, 'name': 'Library'},
    {'id': 19, 'name': 'Fitness Centre'},
    {'id': 20, 'name': 'PTP'},
    {'id': 21, 'name': 'ACASC'},
    {'id': 22, 'name': 'Facilities'},
  ];

  static final List<Map<String, dynamic>> _mockDesignations = [
    {'id': 1, 'title': 'Senior Software Engineer'},
    {'id': 2, 'title': 'Engineering Manager'},
    {'id': 3, 'title': 'Operations Manager'},
  ];

  static final List<Map<String, dynamic>> _mockDocuments = [
    {
      'id': 1,
      'employeeId': 1,
      'fileName': 'Offer_Letter.pdf',
      'fileType': 'Offer Letter',
      'uploadDate': '2026-07-10 10:00 AM',
      'size': '1.2 MB',
    },
    {
      'id': 2,
      'employeeId': 1,
      'fileName': 'Aadhaar_Card.pdf',
      'fileType': 'ID Proof',
      'uploadDate': '2026-07-10 10:05 AM',
      'size': '850 KB',
    },
    {
      'id': 3,
      'employeeId': 2,
      'fileName': 'Degree_Certificate.pdf',
      'fileType': 'Education',
      'uploadDate': '2026-07-12 11:30 AM',
      'size': '2.1 MB',
    },
  ];

  static final List<Map<String, dynamic>> _mockAuditLogs = [
    {
      'action': 'Staff Logged In',
      'details': 'Staff account logged in from web portal.',
      'timestamp': '2026-07-18 09:00 AM',
    },
  ];

  static User _currentUser = User(
    id: 1,
    email: 'staff@acaindia.org',
    employeeId: 1,
    role: 'Employee',
  );

  static Employee _currentEmployee = Employee(
    id: 1,
    employeeCode: 'ACA-001',
    firstName: 'John',
    lastName: 'Doe',
    dob: '1990-01-01',
    gender: 'Male',
    personalEmail: 'staff@acaindia.org',
    phone: '9876543210',
    departmentId: 1,
    departmentName: 'Media',
    designationId: 1,
    designationTitle: 'Senior Software Engineer',
    locationId: 1,
    locationName: 'ACA Campus',
    reportingManagerId: 2,
    managerName: 'Jane Smith',
    dateOfJoining: '2020-06-15',
    employmentType: 'Full-Time',
    status: 'Active',
  );

  static final List<Employee> _mockEmployees = [
    _currentEmployee,
    Employee(
      id: 2,
      employeeCode: 'ACA-002',
      firstName: 'Jane',
      lastName: 'Smith',
      dob: '1985-05-12',
      gender: 'Female',
      personalEmail: 'jane.smith@aca.com',
      phone: '9876543211',
      departmentId: 1,
      departmentName: 'Media',
      designationId: 2,
      designationTitle: 'Engineering Manager',
      locationId: 1,
      locationName: 'ACA Campus',
      reportingManagerId: null,
      managerName: null,
      dateOfJoining: '2018-03-10',
      employmentType: 'Full-Time',
      status: 'Active',
    ),
    Employee(
      id: 3,
      employeeCode: 'ACA-003',
      firstName: 'Alex',
      lastName: 'Rivera',
      dob: '1992-09-22',
      gender: 'Male',
      personalEmail: 'alex.rivera@aca.com',
      phone: '9876543212',
      departmentId: 2,
      departmentName: 'Maintenance',
      designationId: 3,
      designationTitle: 'Operations Manager',
      locationId: 1,
      locationName: 'ACA Campus',
      reportingManagerId: null,
      managerName: null,
      dateOfJoining: '2021-02-01',
      employmentType: 'Full-Time',
      status: 'Active',
    ),
  ];

  static List<AttendanceLog> _attendanceLogs = [
    AttendanceLog(
      id: 101,
      employeeId: 1,
      date: '2026-07-10',
      checkIn: '09:05 AM',
      checkOut: '06:12 PM',
      source: 'Web',
    ),
    AttendanceLog(
      id: 102,
      employeeId: 1,
      date: '2026-07-11',
      checkIn: '08:58 AM',
      checkOut: '06:01 PM',
      source: 'Web',
    ),
    AttendanceLog(
      id: 103,
      employeeId: 1,
      date: '2026-07-12',
      checkIn: '09:12 AM',
      checkOut: '06:30 PM',
      source: 'Web',
    ),
  ];

  static List<RegularizationRequest> _regularizations = [
    RegularizationRequest(
      id: 201,
      employeeId: 1,
      employeeName: 'John Doe',
      employeeCode: 'ACA-001',
      date: '2026-07-09',
      reason: 'Forgot to clock out',
      requestedIn: '09:00 AM',
      requestedOut: '06:00 PM',
      status: 'Approved',
      createdAt: '2026-07-09 09:30 AM',
    ),
  ];

  static List<LeaveBalance> _leaveBalances = [
    LeaveBalance(
      id: 1,
      employeeId: 1,
      leaveTypeId: 1,
      leaveTypeName: 'Sick Leave',
      year: 2026,
      opening: 10.0,
      accrued: 5.0,
      used: 8.0,
      balance: 7.0,
    ),
    LeaveBalance(
      id: 2,
      employeeId: 1,
      leaveTypeId: 2,
      leaveTypeName: 'Casual Leave',
      year: 2026,
      opening: 10.0,
      accrued: 5.0,
      used: 9.0,
      balance: 5.5,
    ),
    LeaveBalance(
      id: 3,
      employeeId: 1,
      leaveTypeId: 3,
      leaveTypeName: 'Earned Leave',
      year: 2026,
      opening: 12.0,
      accrued: 3.0,
      used: 2.0,
      balance: 13.0,
    ),
  ];

  static List<LeaveApplication> _leaveApplications = [
    LeaveApplication(
      id: 301,
      employeeId: 1,
      employeeName: 'John Doe',
      employeeCode: 'ACA-001',
      leaveTypeId: 1,
      leaveTypeName: 'Sick Leave',
      fromDate: '2026-07-01',
      toDate: '2026-07-02',
      days: 2.0,
      reason: 'Fever',
      status: 'Approved',
      createdAt: '2026-06-30',
    ),
  ];

  static final List<Holiday> _holidays = [
    Holiday(id: 1, date: '2026-01-01', name: 'New Year Day'),
    Holiday(id: 2, date: '2026-01-26', name: 'Republic Day'),
    Holiday(id: 3, date: '2026-08-15', name: 'Independence Day'),
    Holiday(id: 4, date: '2026-10-02', name: 'Gandhi Jayanti'),
    Holiday(id: 5, date: '2026-12-25', name: 'Christmas'),
  ];

  static final FinancesSummary _financesSummary = FinancesSummary(
    bankDetails: BankDetails(
      id: 1,
      accountNo: 'XXXXXX1234',
      ifsc: 'SBIN0001234',
      bankName: 'State Bank of India',
    ),
    statutoryInfo: StatutoryInfo(
      id: 1,
      pfAccount: 'ACA/PF/0001234/A',
      esiStatus: 'Eligible',
      ptState: 'Karnataka',
      lwfStatus: 'Enabled',
    ),
    identity: IdentityInfo(
      pan: 'ABCDE1234F',
      aadhaar: 'XXXX XXXX 1234',
      dob: '1990-01-01',
      personalEmail: 'demo@aca.com',
    ),
  );

  static final List<Payslip> _payslips = [
    Payslip(
      id: 401,
      payrollRunId: 10,
      employeeId: 1,
      gross: 85000.0,
      deductions: 5000.0,
      netPay: 80000.0,
      pdfUrl: null,
      month: 6,
      year: 2026,
      runStatus: 'Released',
    ),
    Payslip(
      id: 402,
      payrollRunId: 9,
      employeeId: 1,
      gross: 85000.0,
      deductions: 5000.0,
      netPay: 80000.0,
      pdfUrl: null,
      month: 5,
      year: 2026,
      runStatus: 'Released',
    ),
  ];

  static final List<Map<String, dynamic>> _announcements = [
    {
      'id': 1,
      'title': 'New Academy Service Schedules',
      'description': 'Academy service schedules have been updated. Please consult the navigation block for updated maps, paths, and timetables.',
      'posted_by': 'Operations Office',
      'date': '13 Jul 2026',
    },
    {
      'id': 2,
      'title': 'Quarterly Town Hall',
      'description': 'Our next general meeting will occur on 20 July. Please submit any topics or questions you would like addressed ahead of time.',
      'posted_by': 'HR Department',
      'date': '10 Jul 2026',
    }
  ];

  static final List<Map<String, dynamic>> _polls = [
    {
      'id': 1,
      'question': 'Which date works best for the annual retreat?',
      'options': ['15th September', '22nd September', '29th September'],
      'votes': [12, 8, 15],
      'user_voted': false,
    }
  ];

  static List<Map<String, dynamic>> _tickets = [
    {
      'id': 9280,
      'subject': 'Request to update service schedules',
      'category': 'General Support',
      'sub_category': 'Operations',
      'raised_by': 'John Doe',
      'designation': 'Senior Software Engineer',
      'phone': '9876543210',
      'location': 'ACA Campus',
      'created_at': '13 Jul 2026',
      'priority': 'MEDIUM',
      'escalation_reason': 'Not Escalated',
      'last_responded_by': 'Support Agent',
      'last_response_time': '3 hours ago',
      'assigned_to_name': 'Support Team',
      'status': 'In Progress',
      'age': '1 day 10 hours',
      'overdue_days': 0,
      'followers': ['Jane Smith'],
      'messages': [
        {
          'sender': 'John Doe',
          'designation': 'Senior Software Engineer',
          'content': 'Please add the updated service schedule details to the main organizational portal.',
          'time': '13 Jul 2026 at 11:30 am',
          'is_admin': false,
        },
        {
          'sender': 'Support Agent',
          'designation': 'Support Lead',
          'content': 'We have received your request. I am working on updating the resource files.',
          'time': '13 Jul 2026 at 02:15 pm',
          'is_admin': true,
        }
      ]
    }
  ];

  static final List<Map<String, dynamic>> _assets = [
    {
      'id': 1,
      'asset_name': 'Developer Laptop',
      'asset_code': 'ACA-LP-012',
      'serial_no': 'S/N-982736452',
      'allocated_on': '2020-06-16',
      'status': 'Allocated',
    }
  ];

  // ─── Auth APIs ───
  Future<Map<String, dynamic>> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600)); // Simulate networking
    
    if (email.toLowerCase().trim() == 'admin@acaindia.org') {
      _currentUser = User(
        id: 2,
        email: 'admin@acaindia.org',
        employeeId: 2,
        role: 'Admin',
      );
      _currentEmployee = Employee(
        id: 2,
        employeeCode: 'ACA-002',
        firstName: 'Admin',
        lastName: 'User',
        dob: '1985-05-05',
        gender: 'Male',
        personalEmail: 'admin@acaindia.org',
        phone: '9999999999',
        departmentId: 2,
        departmentName: 'Administration',
        designationId: 2,
        designationTitle: 'System Administrator',
        locationId: 1,
        locationName: 'ACA Campus',
        reportingManagerId: 0,
        managerName: 'None',
        dateOfJoining: '2018-01-01',
        employmentType: 'Full-Time',
        status: 'Active',
      );
    } else {
      _currentUser = User(
        id: 1,
        email: 'staff@acaindia.org',
        employeeId: 1,
        role: 'Employee',
      );
      _currentEmployee = Employee(
        id: 1,
        employeeCode: 'ACA-001',
        firstName: 'John',
        lastName: 'Doe',
        dob: '1990-01-01',
        gender: 'Male',
        personalEmail: 'staff@acaindia.org',
        phone: '9876543210',
        departmentId: 1,
        departmentName: 'Software Engineering',
        designationId: 1,
        designationTitle: 'Senior Software Engineer',
        locationId: 1,
        locationName: 'ACA Campus',
        reportingManagerId: 2,
        managerName: 'Jane Smith',
        dateOfJoining: '2020-06-15',
        employmentType: 'Full-Time',
        status: 'Active',
      );
    }

    return {
      'token': 'demo-token-12345',
      'user': _currentUser.toJson(),
    };
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<Map<String, dynamic>> getProfile() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return {
      'user': _currentUser.toJson(),
      'employee': _currentEmployee.toJson(),
    };
  }

  // ─── Core HR APIs ───
  Future<List<Employee>> searchEmployees({String? search, int? dept, int? loc}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    List<Employee> results = List.from(_mockEmployees);
    if (search != null && search.isNotEmpty) {
      results = results.where((e) =>
        e.fullName.toLowerCase().contains(search.toLowerCase()) ||
        e.employeeCode.toLowerCase().contains(search.toLowerCase())
      ).toList();
    }
    if (dept != null) {
      results = results.where((e) => e.departmentId == dept).toList();
    }
    if (loc != null) {
      results = results.where((e) => e.locationId == loc).toList();
    }
    return results;
  }

  Future<Employee> getEmployeeProfile(int id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockEmployees.firstWhere((e) => e.id == id, orElse: () => _currentEmployee);
  }

  Future<void> createEmployee(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final newId = _mockEmployees.length + 1;
    final deptId = data['department_id'] ?? 1;
    final deptObj = _mockDepartments.firstWhere((d) => d['id'] == deptId, orElse: () => {'name': 'General'});
    final desigId = data['designation_id'] ?? 1;
    final desigObj = _mockDesignations.firstWhere((d) => d['id'] == desigId, orElse: () => {'title': 'Associate'});

    final newEmp = Employee(
      id: newId,
      employeeCode: 'ACA-00${newId}',
      firstName: data['first_name'] ?? 'New',
      lastName: data['last_name'] ?? 'Employee',
      dob: data['dob'] ?? '',
      gender: data['gender'] ?? 'Male',
      personalEmail: data['personal_email'] ?? '',
      phone: data['phone'] ?? '',
      departmentId: deptId,
      departmentName: deptObj['name'],
      designationId: desigId,
      designationTitle: desigObj['title'],
      locationId: data['location_id'] ?? 1,
      locationName: 'ACA Campus',
      dateOfJoining: data['date_of_joining'] ?? '',
      employmentType: data['employment_type'] ?? 'Full-Time',
      status: 'Active',
    );
    _mockEmployees.add(newEmp);
    await logAdminAction('Add Staff', 'Added new employee profile "${newEmp.fullName}" (Code: ${newEmp.employeeCode}).');
  }

  Future<void> updateEmployee(int id, Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final idx = _mockEmployees.indexWhere((e) => e.id == id);
    if (idx != -1) {
      final existing = _mockEmployees[idx];
      final deptId = data['department_id'] ?? existing.departmentId;
      final deptObj = _mockDepartments.firstWhere((d) => d['id'] == deptId, orElse: () => {'name': 'General'});
      final desigId = data['designation_id'] ?? existing.designationId;
      final desigObj = _mockDesignations.firstWhere((d) => d['id'] == desigId, orElse: () => {'title': 'Associate'});

      final updated = Employee(
        id: id,
        employeeCode: existing.employeeCode,
        firstName: data['first_name'] ?? existing.firstName,
        lastName: data['last_name'] ?? existing.lastName,
        dob: data['dob'] ?? existing.dob,
        gender: data['gender'] ?? existing.gender,
        personalEmail: data['personal_email'] ?? existing.personalEmail,
        phone: data['phone'] ?? existing.phone,
        departmentId: deptId,
        departmentName: deptObj['name'],
        designationId: desigId,
        designationTitle: desigObj['title'],
        locationId: data['location_id'] ?? existing.locationId,
        locationName: existing.locationName,
        dateOfJoining: data['date_of_joining'] ?? existing.dateOfJoining,
        employmentType: data['employment_type'] ?? existing.employmentType,
        status: data['status'] ?? existing.status,
      );
      _mockEmployees[idx] = updated;
      await logAdminAction('Edit Staff', 'Updated employee profile details for "${updated.fullName}".');
    }
  }

  Future<List<Map<String, dynamic>>> getLocations() async {
    return [
      {'id': 1, 'name': 'ACA Campus'}
    ];
  }

  Future<List<Map<String, dynamic>>> getDepartments() async {
    return _mockDepartments;
  }

  Future<void> createDepartment(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newId = _mockDepartments.length + 1;
    _mockDepartments.add({
      'id': newId,
      'name': data['name'] ?? 'New Department',
    });
    await logAdminAction('Create Department', 'Created new department "${data['name']}".');
  }

  Future<List<Map<String, dynamic>>> getDesignations() async {
    return _mockDesignations;
  }

  Future<List<Map<String, dynamic>>> getEmployeeDocuments(int employeeId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockDocuments.where((doc) => doc['employeeId'] == employeeId).toList();
  }

  Future<void> uploadEmployeeDocument(int employeeId, Map<String, dynamic> doc) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newId = _mockDocuments.length + 1;
    final nowStr = DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now());
    _mockDocuments.add({
      'id': newId,
      'employeeId': employeeId,
      'fileName': doc['fileName'] ?? 'Document.pdf',
      'fileType': doc['fileType'] ?? 'General',
      'uploadDate': nowStr,
      'size': doc['size'] ?? '1.0 MB',
    });
    final emp = _mockEmployees.firstWhere((e) => e.id == employeeId);
    await logAdminAction('Upload Document', 'Uploaded document "${doc['fileName']}" for employee ${emp.fullName}.');
  }

  Future<void> deleteEmployeeDocument(int employeeId, int docId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _mockDocuments.removeWhere((doc) => doc['id'] == docId && doc['employeeId'] == employeeId);
    final emp = _mockEmployees.firstWhere((e) => e.id == employeeId);
    await logAdminAction('Delete Document', 'Deleted a document for employee ${emp.fullName}.');
  }

  Future<List<Map<String, dynamic>>> getAuditLogs() async {
    return _mockAuditLogs.reversed.toList();
  }

  Future<void> logAdminAction(String action, String details) async {
    final nowStr = DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now());
    _mockAuditLogs.add({
      'action': action,
      'details': details,
      'timestamp': nowStr,
    });
  }

  Future<List<Map<String, dynamic>>> getOrgTree() async {
    return [
      {
        'id': 2,
        'name': 'Jane Smith',
        'designation': 'Engineering Manager',
        'subordinates': [
          {
            'id': 1,
            'name': 'John Doe',
            'designation': 'Senior Software Engineer',
          }
        ]
      }
    ];
  }

  // ─── Attendance APIs ───
  Future<Map<String, dynamic>> getAttendanceLogs({int? employeeId, int? month, int? year}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return {
      'logs': _attendanceLogs.map((log) => {
        'id': log.id,
        'employee_id': log.employeeId,
        'date': log.date,
        'check_in': log.checkIn,
        'check_out': log.checkOut,
        'source': log.source,
      }).toList(),
      'regularizations': _regularizations.map((reg) => {
        'id': reg.id,
        'employee_id': reg.employeeId,
        'employee_name': reg.employeeName,
        'employee_code': reg.employeeCode,
        'date': reg.date,
        'reason': reg.reason,
        'requested_in': reg.requestedIn,
        'requested_out': reg.requestedOut,
        'status': reg.status,
        'created_at': reg.createdAt,
      }).toList(),
    };
  }

  Future<Map<String, dynamic>> checkIn({String? source, double? lat, double? lng}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    // Check if log already exists
    final idx = _attendanceLogs.indexWhere((log) => log.date == today);
    final nowStr = DateFormat('hh:mm a').format(DateTime.now());

    if (idx != -1) {
      final existing = _attendanceLogs[idx];
      _attendanceLogs[idx] = AttendanceLog(
        id: existing.id,
        employeeId: existing.employeeId,
        date: today,
        checkIn: nowStr,
        checkOut: existing.checkOut,
        source: source ?? 'Web',
      );
    } else {
      _attendanceLogs.add(AttendanceLog(
        id: _attendanceLogs.length + 100,
        employeeId: 1,
        date: today,
        checkIn: nowStr,
        source: source ?? 'Web',
      ));
    }

    return {'success': true};
  }

  Future<Map<String, dynamic>> checkOut() async {
    await Future.delayed(const Duration(milliseconds: 400));
    final today = DateTime.now().toIso8601String().split('T')[0];
    final nowStr = DateFormat('hh:mm a').format(DateTime.now());

    final idx = _attendanceLogs.indexWhere((log) => log.date == today);
    if (idx != -1) {
      final existing = _attendanceLogs[idx];
      _attendanceLogs[idx] = AttendanceLog(
        id: existing.id,
        employeeId: existing.employeeId,
        date: today,
        checkIn: existing.checkIn,
        checkOut: nowStr,
        source: existing.source,
      );
    }

    return {'success': true};
  }

  Future<void> submitRegularization(String date, String reason, String checkIn, String checkOut) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _regularizations.add(RegularizationRequest(
      id: _regularizations.length + 200,
      employeeId: 1,
      employeeName: 'John Doe',
      employeeCode: 'ACA-001',
      date: date,
      reason: reason,
      requestedIn: checkIn,
      requestedOut: checkOut,
      status: 'Pending',
      createdAt: DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now()),
    ));
  }

  Future<void> approveRegularization(int requestId, String status) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _regularizations.indexWhere((r) => r.id == requestId);
    if (idx != -1) {
      final r = _regularizations[idx];
      _regularizations[idx] = RegularizationRequest(
        id: r.id,
        employeeId: r.employeeId,
        employeeName: r.employeeName,
        employeeCode: r.employeeCode,
        date: r.date,
        reason: r.reason,
        requestedIn: r.requestedIn,
        requestedOut: r.requestedOut,
        status: status,
        createdAt: r.createdAt,
      );

      // If approved, update matching attendance log
      if (status == 'Approved') {
        final logIdx = _attendanceLogs.indexWhere((log) => log.date == r.date);
        if (logIdx != -1) {
          final existing = _attendanceLogs[logIdx];
          _attendanceLogs[logIdx] = AttendanceLog(
            id: existing.id,
            employeeId: existing.employeeId,
            date: r.date,
            checkIn: r.requestedIn ?? existing.checkIn,
            checkOut: r.requestedOut ?? existing.checkOut,
            source: existing.source,
          );
        } else {
          _attendanceLogs.add(AttendanceLog(
            id: _attendanceLogs.length + 100,
            employeeId: r.employeeId,
            date: r.date,
            checkIn: r.requestedIn,
            checkOut: r.requestedOut,
            source: 'Regularization',
          ));
        }
      }
    }
  }

  // ─── Leave APIs ───
  Future<List<LeaveType>> getLeaveTypes() async {
    return [
      LeaveType(id: 1, name: 'Sick Leave', accrualType: 'Monthly', maxCarryForward: 5, encashable: true),
      LeaveType(id: 2, name: 'Casual Leave', accrualType: 'Monthly', maxCarryForward: 5, encashable: true),
      LeaveType(id: 3, name: 'Earned Leave', accrualType: 'Yearly', maxCarryForward: 30, encashable: true),
    ];
  }

  Future<List<LeaveBalance>> getLeaveBalances({int? employeeId}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _leaveBalances;
  }

  Future<List<LeaveApplication>> getLeaveApplications({int? employeeId}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _leaveApplications;
  }

  Future<void> applyLeave(int leaveTypeId, String fromDate, String toDate, double days, String reason) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final leaveTypeName = leaveTypeId == 1
        ? 'Sick Leave'
        : leaveTypeId == 2
            ? 'Casual Leave'
            : 'Earned Leave';

    // Deduct leave balance
    final balIdx = _leaveBalances.indexWhere((b) => b.leaveTypeId == leaveTypeId);
    if (balIdx != -1) {
      final current = _leaveBalances[balIdx];
      _leaveBalances[balIdx] = LeaveBalance(
        id: current.id,
        employeeId: current.employeeId,
        leaveTypeId: current.leaveTypeId,
        leaveTypeName: current.leaveTypeName,
        year: current.year,
        opening: current.opening,
        accrued: current.accrued,
        used: current.used + days,
        balance: current.balance - days,
      );
    }

    _leaveApplications.add(LeaveApplication(
      id: _leaveApplications.length + 300,
      employeeId: 1,
      employeeName: 'John Doe',
      employeeCode: 'ACA-001',
      leaveTypeId: leaveTypeId,
      leaveTypeName: leaveTypeName,
      fromDate: fromDate,
      toDate: toDate,
      days: days,
      reason: reason,
      status: 'Pending',
      createdAt: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    ));
  }

  Future<void> approveLeave(int applicationId, String status) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _leaveApplications.indexWhere((a) => a.id == applicationId);
    if (idx != -1) {
      final a = _leaveApplications[idx];
      _leaveApplications[idx] = LeaveApplication(
        id: a.id,
        employeeId: a.employeeId,
        employeeName: a.employeeName,
        employeeCode: a.employeeCode,
        leaveTypeId: a.leaveTypeId,
        leaveTypeName: a.leaveTypeName,
        fromDate: a.fromDate,
        toDate: a.toDate,
        days: a.days,
        reason: a.reason,
        status: status,
        createdAt: a.createdAt,
      );
    }
  }

  Future<List<Holiday>> getHolidays() async {
    return _holidays;
  }

  // ─── Finances APIs ───
  Future<FinancesSummary> getFinancesSummary({int? employeeId}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _financesSummary;
  }

  Future<List<Payslip>> getPayslips({int? employeeId}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _payslips;
  }

  // ─── Inbox Aggregated API ───
  Future<Map<String, dynamic>> getInboxPending() async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Filter pending leaves and regularizations to show on inbox screen
    final pendingLeaves = _leaveApplications.where((a) => a.status == 'Pending').toList();
    final pendingRegs = _regularizations.where((r) => r.status == 'Pending').toList();
    
    return {
      'leaves': pendingLeaves.map((a) => {
        'id': a.id,
        'employee_id': a.employeeId,
        'employee_name': a.employeeName,
        'employee_code': a.employeeCode,
        'leave_type_id': a.leaveTypeId,
        'leave_type_name': a.leaveTypeName,
        'from_date': a.fromDate,
        'to_date': a.toDate,
        'days': a.days,
        'reason': a.reason,
        'status': a.status,
        'created_at': a.createdAt,
      }).toList(),
      'regularizations': pendingRegs.map((r) => {
        'id': r.id,
        'employee_id': r.employeeId,
        'employee_name': r.employeeName,
        'employee_code': r.employeeCode,
        'date': r.date,
        'reason': r.reason,
        'requested_in': r.requestedIn,
        'requested_out': r.requestedOut,
        'status': r.status,
        'created_at': r.createdAt,
      }).toList(),
    };
  }



  // ─── Dashboard Feeds ───
  Future<List<Map<String, dynamic>>> getAnnouncements() async {
    return _announcements;
  }

  Future<List<Map<String, dynamic>>> getPolls() async {
    return _polls;
  }

  Future<List<Map<String, dynamic>>> getGoals({int? employeeId}) async {
    return [];
  }

  Future<List<Map<String, dynamic>>> getTickets() async {
    return _tickets;
  }

  Future<List<Map<String, dynamic>>> getAssets() async {
    return _assets;
  }
}
