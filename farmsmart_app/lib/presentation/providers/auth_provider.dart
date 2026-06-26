import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:farmsmart_app/core/network/api_client.dart';
import 'package:farmsmart_app/core/constants/api_constants.dart';

const _storage = FlutterSecureStorage();
const _tokenKey = 'auth_token';
const _phoneKey = 'auth_phone';

class AuthState {
  final bool isLoggedIn;
  final String? phone;
  final String? token;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.isLoggedIn = false,
    this.phone,
    this.token,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    String? phone,
    String? token,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      phone: phone ?? this.phone,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FarmSmartApiClient _client;

  AuthNotifier(this._client) : super(const AuthState()) {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final token = await _storage.read(key: _tokenKey);
    final phone = await _storage.read(key: _phoneKey);
    if (token != null && phone != null) {
      state = AuthState(isLoggedIn: true, phone: phone, token: token);
    }
  }

  Future<String> sendOtp(String phone) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final resp = await _client.post('/api/auth/send-otp', data: {
        'phone': phone,
      });
      final data = resp.data as Map;
      state = state.copyWith(isLoading: false);
      // In dev mode, the code is returned directly
      return data['code']?.toString() ?? '';
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to send OTP');
      rethrow;
    }
  }

  Future<bool> verifyOtp(String phone, String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final resp = await _client.post('/api/auth/verify-otp', data: {
        'phone': phone,
        'code': code,
      });
      final data = resp.data as Map;
      if (data['status'] == 'ok') {
        final token = data['token'] as String;
        await _storage.write(key: _tokenKey, value: token);
        await _storage.write(key: _phoneKey, value: phone);
        state = AuthState(isLoggedIn: true, phone: phone, token: token);
        return true;
      }
      state = state.copyWith(isLoading: false, error: 'Invalid code');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Verification failed');
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _phoneKey);
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(FarmSmartApiClient());
});
