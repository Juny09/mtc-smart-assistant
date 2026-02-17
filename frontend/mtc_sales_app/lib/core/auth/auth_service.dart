import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mtc_sales_app/core/api/api_client.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return AuthService(apiClient);
});

final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  final authService = ref.read(authServiceProvider);
  return UserNotifier(authService);
});

class UserState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? token;
  final String? role;
  final String? fullName;

  UserState({
    this.isAuthenticated = false,
    this.isLoading = true,
    this.token,
    this.role,
    this.fullName,
  });

  UserState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? token,
    String? role,
    String? fullName,
  }) {
    return UserState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      token: token ?? this.token,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
    );
  }
}

class AuthService {
  final ApiClient _apiClient;
  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';
  static const _roleKey = 'user_role';

  AuthService(this._apiClient);

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _apiClient.post(
        '/auth/login',
        data: {'username': username, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await _storage.write(key: _tokenKey, value: data['token']);
        await _storage.write(key: _roleKey, value: data['role']);
        return data;
      } else {
        throw Exception('Login failed: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _roleKey);
  }

  Future<Map<String, String?>?> getUser() async {
    final token = await _storage.read(key: _tokenKey);
    final role = await _storage.read(key: _roleKey);
    if (token != null) {
      return {'token': token, 'role': role};
    }
    return null;
  }
}

class UserNotifier extends StateNotifier<UserState> {
  final AuthService _authService;

  UserNotifier(this._authService) : super(UserState()) {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      final userData = await _authService.getUser();
      if (userData != null) {
        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          token: userData['token'],
          role: userData['role'],
        );
      } else {
        state = state.copyWith(isAuthenticated: false, isLoading: false);
      }
    } catch (e) {
      // If error occurs during check (e.g. storage error), assume not logged in
      state = state.copyWith(isAuthenticated: false, isLoading: false);
    }
  }

  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await _authService.login(username, password);
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        token: data['token'],
        role: data['role'],
        fullName: data['fullName'],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = UserState(isAuthenticated: false, isLoading: false);
  }
}
