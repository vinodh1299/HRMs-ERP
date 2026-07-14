import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants.dart';
import '../models/user.dart';
import '../models/employee.dart';
import '../services/api_service.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final User? user;
  final Employee? employee;
  final String? errorMessage;

  AuthState({
    required this.isAuthenticated,
    required this.isLoading,
    this.user,
    this.employee,
    this.errorMessage,
  });

  factory AuthState.initial() => AuthState(isAuthenticated: false, isLoading: false);
  factory AuthState.loading() => AuthState(isAuthenticated: false, isLoading: true);
  
  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    User? user,
    Employee? employee,
    String? errorMessage,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      employee: employee ?? this.employee,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  
  // In-memory token fallback for non-secure HTTP contexts (where Web Crypto fails)
  static String? _inMemoryToken;

  AuthNotifier() : super(AuthState.initial()) {
    checkAutoLogin();
  }

  Future<String?> _readToken() async {
    try {
      return await _storage.read(key: AppConstants.tokenKey) ?? _inMemoryToken;
    } catch (_) {
      return _inMemoryToken;
    }
  }

  Future<void> _writeToken(String token) async {
    _inMemoryToken = token;
    try {
      await _storage.write(key: AppConstants.tokenKey, value: token);
    } catch (_) {}
  }

  Future<void> _deleteToken() async {
    _inMemoryToken = null;
    try {
      await _storage.delete(key: AppConstants.tokenKey);
    } catch (_) {}
  }

  Future<void> checkAutoLogin() async {
    state = AuthState.loading();
    try {
      final token = await _readToken();
      if (token != null) {
        final profileData = await _apiService.getProfile();
        final user = User.fromJson(profileData['user']);
        final employee = profileData['employee'] != null 
            ? Employee.fromJson(profileData['employee']) 
            : null;
        
        state = AuthState(
          isAuthenticated: true,
          isLoading: false,
          user: user,
          employee: employee,
        );
      } else {
        state = AuthState.initial();
      }
    } catch (e) {
      await _deleteToken();
      state = AuthState(
        isAuthenticated: false,
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final loginData = await _apiService.login(email, password);
      final token = loginData['token'];
      final user = User.fromJson(loginData['user']);

      await _writeToken(token);
      
      // Load full profile to get associated employee details
      final profileData = await _apiService.getProfile();
      final employee = profileData['employee'] != null 
          ? Employee.fromJson(profileData['employee']) 
          : null;

      state = AuthState(
        isAuthenticated: true,
        isLoading: false,
        user: user,
        employee: employee,
      );
      return true;
    } catch (e) {
      state = AuthState(
        isAuthenticated: false,
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      await _apiService.logout();
    } catch (_) {}
    await _deleteToken();
    state = AuthState.initial();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
