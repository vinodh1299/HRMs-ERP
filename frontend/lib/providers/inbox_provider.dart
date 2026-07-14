import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/attendance.dart';
import '../models/leave.dart';
import '../services/api_service.dart';

class InboxState {
  final List<LeaveApplication> pendingLeaves;
  final List<RegularizationRequest> pendingRegularizations;
  final bool isLoading;
  final String? errorMessage;

  InboxState({
    required this.pendingLeaves,
    required this.pendingRegularizations,
    required this.isLoading,
    this.errorMessage,
  });

  factory InboxState.initial() => InboxState(
        pendingLeaves: [],
        pendingRegularizations: [],
        isLoading: false,
      );

  InboxState copyWith({
    List<LeaveApplication>? pendingLeaves,
    List<RegularizationRequest>? pendingRegularizations,
    bool? isLoading,
    String? errorMessage,
  }) {
    return InboxState(
      pendingLeaves: pendingLeaves ?? this.pendingLeaves,
      pendingRegularizations: pendingRegularizations ?? this.pendingRegularizations,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class InboxNotifier extends StateNotifier<InboxState> {
  final ApiService _apiService = ApiService();

  InboxNotifier() : super(InboxState.initial());

  Future<void> fetchPendingApprovals() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _apiService.getInboxPending();
      
      final List leavesList = res['leaves'] ?? [];
      final List regsList = res['regularizations'] ?? [];

      state = InboxState(
        pendingLeaves: leavesList.map((x) => LeaveApplication.fromJson(x)).toList(),
        pendingRegularizations: regsList.map((x) => RegularizationRequest.fromJson(x)).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> processLeave(int applicationId, String status) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _apiService.approveLeave(applicationId, status);
      await fetchPendingApprovals(); // Refresh
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> processRegularization(int requestId, String status) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _apiService.approveRegularization(requestId, status);
      await fetchPendingApprovals(); // Refresh
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final inboxProvider = StateNotifierProvider<InboxNotifier, InboxState>((ref) {
  return InboxNotifier();
});
