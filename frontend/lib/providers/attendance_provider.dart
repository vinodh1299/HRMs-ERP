import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/attendance.dart';
import '../services/api_service.dart';

class AttendanceState {
  final List<AttendanceLog> logs;
  final List<RegularizationRequest> regularizations;
  final bool isLoading;
  final String? errorMessage;
  final AttendanceLog? todayLog;

  AttendanceState({
    required this.logs,
    required this.regularizations,
    required this.isLoading,
    this.errorMessage,
    this.todayLog,
  });

  factory AttendanceState.initial() => AttendanceState(
        logs: [],
        regularizations: [],
        isLoading: false,
      );

  AttendanceState copyWith({
    List<AttendanceLog>? logs,
    List<RegularizationRequest>? regularizations,
    bool? isLoading,
    String? errorMessage,
    AttendanceLog? todayLog,
  }) {
    return AttendanceState(
      logs: logs ?? this.logs,
      regularizations: regularizations ?? this.regularizations,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      todayLog: todayLog ?? this.todayLog,
    );
  }
}

class AttendanceNotifier extends StateNotifier<AttendanceState> {
  final ApiService _apiService = ApiService();

  AttendanceNotifier() : super(AttendanceState.initial());

  Future<void> fetchLogs({int? employeeId, int? month, int? year}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final data = await _apiService.getAttendanceLogs(
        employeeId: employeeId,
        month: month,
        year: year,
      );

      final List logDataList = data['logs'] ?? [];
      final List regDataList = data['regularizations'] ?? [];

      final logsList = logDataList.map((item) => AttendanceLog.fromJson(item)).toList();
      final regList = regDataList.map((item) => RegularizationRequest.fromJson(item)).toList();

      // Find today's log if any
      final today = DateTime.now().toIso8601String().split('T')[0];
      AttendanceLog? todayLog;
      try {
        todayLog = logsList.firstWhere((log) => log.date == today);
      } catch (_) {}

      state = AttendanceState(
        logs: logsList,
        regularizations: regList,
        isLoading: false,
        todayLog: todayLog,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> checkIn({String? source, double? lat, double? lng}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _apiService.checkIn(source: source, lat: lat, lng: lng);
      await fetchLogs(); // Refresh logs
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> checkOut() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _apiService.checkOut();
      await fetchLogs(); // Refresh logs
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> regularize(String date, String reason, String checkIn, String checkOut) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _apiService.submitRegularization(date, reason, checkIn, checkOut);
      await fetchLogs(); // Refresh logs
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final attendanceProvider = StateNotifierProvider<AttendanceNotifier, AttendanceState>((ref) {
  return AttendanceNotifier();
});
