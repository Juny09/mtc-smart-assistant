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
  final String? token;
  final String? role;
  final String? fullName;

  UserState({
    this.isAuthenticated = false,
    this.token,
    this.role,
    this.fullName,
  });

  UserState copyWith({
    bool? isAuthenticated,
    String? token,
    String? role,
    String? fullName,
  }) {
    return UserState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
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
      final response = await _apiClient.post('/auth/login', data: {
        'username': username,
        'password': password,
      });

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

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }
}

class UserNotifier extends StateNotifier<UserState> {
  final AuthService _authService;

  UserNotifier(this._authService) : super(UserState());

  Future<void> login(String username, String password) async {
    try {
      final data = await _authService.login(username, password);
      state = state.copyWith(
        isAuthenticated: true,
        token: data['token'],
        role: data['role'],
        fullName: data['fullName'],
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = UserState(isAuthenticated: false);
  }
}
