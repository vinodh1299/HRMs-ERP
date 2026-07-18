import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/employee.dart';
import '../services/api_service.dart';

class EmployeeState {
  final List<Employee> employees;
  final List<Map<String, dynamic>> departments;
  final List<Map<String, dynamic>> locations;
  final List<Map<String, dynamic>> designations;
  final List<Map<String, dynamic>> orgTreeData;
  final List<Map<String, dynamic>> auditLogs;
  final List<Map<String, dynamic>> employeeDocuments;
  final bool isLoading;
  final String? errorMessage;

  EmployeeState({
    required this.employees,
    required this.departments,
    required this.locations,
    required this.designations,
    required this.orgTreeData,
    required this.auditLogs,
    required this.employeeDocuments,
    required this.isLoading,
    this.errorMessage,
  });

  factory EmployeeState.initial() => EmployeeState(
        employees: [],
        departments: [],
        locations: [],
        designations: [],
        orgTreeData: [],
        auditLogs: [],
        employeeDocuments: [],
        isLoading: false,
      );

  EmployeeState copyWith({
    List<Employee>? employees,
    List<Map<String, dynamic>>? departments,
    List<Map<String, dynamic>>? locations,
    List<Map<String, dynamic>>? designations,
    List<Map<String, dynamic>>? orgTreeData,
    List<Map<String, dynamic>>? auditLogs,
    List<Map<String, dynamic>>? employeeDocuments,
    bool? isLoading,
    String? errorMessage,
  }) {
    return EmployeeState(
      employees: employees ?? this.employees,
      departments: departments ?? this.departments,
      locations: locations ?? this.locations,
      designations: designations ?? this.designations,
      orgTreeData: orgTreeData ?? this.orgTreeData,
      auditLogs: auditLogs ?? this.auditLogs,
      employeeDocuments: employeeDocuments ?? this.employeeDocuments,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class EmployeeNotifier extends StateNotifier<EmployeeState> {
  final ApiService _apiService = ApiService();

  EmployeeNotifier() : super(EmployeeState.initial());

  Future<void> fetchMetadata() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final depts = await _apiService.getDepartments();
      final locs = await _apiService.getLocations();
      final desigs = await _apiService.getDesignations();

      state = state.copyWith(
        departments: depts,
        locations: locs,
        designations: desigs,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> fetchEmployees({String? search, int? dept, int? loc}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _apiService.searchEmployees(search: search, dept: dept, loc: loc);
      state = state.copyWith(employees: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> fetchOrgTree() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final tree = await _apiService.getOrgTree();
      state = state.copyWith(orgTreeData: tree, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> fetchAuditLogs() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final logs = await _apiService.getAuditLogs();
      state = state.copyWith(auditLogs: logs, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> fetchEmployeeDocuments(int employeeId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final docs = await _apiService.getEmployeeDocuments(employeeId);
      state = state.copyWith(employeeDocuments: docs, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> addEmployee(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _apiService.createEmployee(data);
      await fetchEmployees();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> editEmployee(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _apiService.updateEmployee(id, data);
      await fetchEmployees();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> addDepartment(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _apiService.createDepartment(data);
      await fetchMetadata();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> uploadDocument(int employeeId, Map<String, dynamic> doc) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _apiService.uploadEmployeeDocument(employeeId, doc);
      await fetchEmployeeDocuments(employeeId);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteDocument(int employeeId, int docId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _apiService.deleteEmployeeDocument(employeeId, docId);
      await fetchEmployeeDocuments(employeeId);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final employeeProvider = StateNotifierProvider<EmployeeNotifier, EmployeeState>((ref) {
  return EmployeeNotifier();
});
