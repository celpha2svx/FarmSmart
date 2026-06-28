import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/api_client.dart';

class AppUser {
  final String phone;
  final String? name;
  final String? token;
  const AppUser({required this.phone, this.name, this.token});
}

class AuthState {
  final bool isLoading;
  final AppUser? user;
  final String? error;
  final bool isLoggedIn;
  final String? devOtpCode;

  const AuthState({
    this.isLoading = false,
    this.user,
    this.error,
    this.isLoggedIn = false,
    this.devOtpCode,
  });

  AuthState copyWith({
    bool? isLoading,
    AppUser? user,
    String? error,
    bool? isLoggedIn,
    String? devOtpCode,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      devOtpCode: devOtpCode,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FlutterSecureStorage _storage;
  final FarmSmartApiClient _api;

  AuthNotifier(this._storage, this._api) : super(const AuthState());

  Future<bool> checkSession() async {
    final phone = await _storage.read(key: 'phone');
    final token = await _storage.read(key: 'auth_token');
    final name = await _storage.read(key: 'user_name');
    if (phone != null && token != null) {
      state = AuthState(
        isLoggedIn: true,
        user: AppUser(phone: phone, name: name, token: token),
      );
      return true;
    }
    return false;
  }

  Future<bool> sendOtp({required String phone, String? name}) async {
    state = const AuthState(isLoading: true);
    try {
      final res = await _api.post(
        '/api/auth/send-otp',
        data: {'phone': phone},
      );
      if (name != null) {
        await _storage.write(key: 'pending_name', value: name);
      }
      await _storage.write(key: 'pending_phone', value: phone);

      final devCode = res['code'] as String?;
      state = AuthState(isLoading: false, devOtpCode: devCode);
      return true;
    } on DioException catch (e) {
      final msg = _extractError(e, fallback: 'Failed to send OTP. Check your network.');
      state = AuthState(error: msg);
      return false;
    } catch (_) {
      state = const AuthState(error: 'Unexpected error. Please try again.');
      return false;
    }
  }

  Future<bool> verifyOtp({required String phone, required String otp}) async {
    state = const AuthState(isLoading: true);
    try {
      final res = await _api.post(
        '/api/auth/verify-otp',
        data: {'phone': phone, 'code': otp},
      );

      final token = res['token'] as String?;
      if (token == null || token.isEmpty) {
        state = const AuthState(error: 'Verification failed. Please try again.');
        return false;
      }

      await _storage.write(key: 'auth_token', value: token);
      await _storage.write(key: 'phone', value: phone);

      final name = await _storage.read(key: 'pending_name');
      if (name != null) {
        await _storage.write(key: 'user_name', value: name);
        await _storage.delete(key: 'pending_name');
      }
      await _storage.delete(key: 'pending_phone');

      state = AuthState(
        isLoggedIn: true,
        user: AppUser(phone: phone, name: name, token: token),
      );
      return true;
    } on DioException catch (e) {
      final msg = _extractError(e, fallback: 'Wrong code. Please try again.');
      state = AuthState(error: msg);
      return false;
    } catch (_) {
      state = const AuthState(error: 'Verification failed. Please try again.');
      return false;
    }
  }

  Future<bool> hasCompletedOnboarding() async {
    final val = await _storage.read(key: 'onboarding_complete');
    return val == 'true';
  }

  Future<void> completeOnboarding({String? crop, String? location}) async {
    if (crop != null) await _storage.write(key: 'user_crop', value: crop);
    if (location != null) await _storage.write(key: 'user_location', value: location);
    await _storage.write(key: 'onboarding_complete', value: 'true');
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    state = const AuthState();
  }

  String _extractError(DioException e, {required String fallback}) {
    final data = e.response?.data;
    if (data is Map) {
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Check your internet.';
    }
    if (e.response?.statusCode == 401) return 'Invalid or expired code.';
    if (e.response?.statusCode == 429) return 'Too many attempts. Try again later.';
    return fallback;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(const FlutterSecureStorage(), FarmSmartApiClient());
});
