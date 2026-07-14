import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/leave.dart';
import '../services/api_service.dart';

class LeaveState {
  final List<LeaveType> leaveTypes;
  final List<LeaveBalance> balances;
  final List<LeaveApplication> applications;
  final List<Holiday> holidays;
  final bool isLoading;
  final String? errorMessage;

  LeaveState({
    required this.leaveTypes,
    required this.balances,
    required this.applications,
    required this.holidays,
    required this.isLoading,
    this.errorMessage,
  });

  factory LeaveState.initial() => LeaveState(
        leaveTypes: [],
        balances: [],
        applications: [],
        holidays: [],
        isLoading: false,
      );

  LeaveState copyWith({
    List<LeaveType>? leaveTypes,
    List<LeaveBalance>? balances,
    List<LeaveApplication>? applications,
    List<Holiday>? holidays,
    bool? isLoading,
    String? errorMessage,
  }) {
    return LeaveState(
      leaveTypes: leaveTypes ?? this.leaveTypes,
      balances: balances ?? this.balances,
      applications: applications ?? this.applications,
      holidays: holidays ?? this.holidays,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class LeaveNotifier extends StateNotifier<LeaveState> {
  final ApiService _apiService = ApiService();

  LeaveNotifier() : super(LeaveState.initial());

  Future<void> fetchLeaveData({int? employeeId}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final types = await _apiService.getLeaveTypes();
      final bals = await _apiService.getLeaveBalances(employeeId: employeeId);
      final apps = await _apiService.getLeaveApplications(employeeId: employeeId);
      final hols = await _apiService.getHolidays();

      state = LeaveState(
        leaveTypes: types,
        balances: bals,
        applications: apps,
        holidays: hols,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> applyLeave({
    required int leaveTypeId,
    required String fromDate,
    required String toDate,
    required double days,
    required String reason,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _apiService.applyLeave(leaveTypeId, fromDate, toDate, days, reason);
      await fetchLeaveData(); // Refresh data
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final leaveProvider = StateNotifierProvider<LeaveNotifier, LeaveState>((ref) {
  return LeaveNotifier();
});
