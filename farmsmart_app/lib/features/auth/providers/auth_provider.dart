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
  const AuthState({
    this.isLoading = false,
    this.user,
    this.error,
    this.isLoggedIn = false,
  });
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FlutterSecureStorage _storage;
  final FarmSmartApiClient _api;
  AuthNotifier(this._storage, this._api) : super(const AuthState());

  Future<bool> checkSession() async {
    final phone = await _storage.read(key: 'phone');
    final token = await _storage.read(key: 'auth_token');
    final name = await _storage.read(key: 'user_name');
    final crop = await _storage.read(key: 'user_crop');
    final location = await _storage.read(key: 'user_location');
    if (phone != null && token != null) {
      state = AuthState(isLoggedIn: true, user: AppUser(phone: phone, name: name, token: token));
      return true;
    }
    return false;
  }

  Future<void> sendOtp({required String phone, required String name}) async {
    state = AuthState(isLoading: true);
    try {
      await _api.post('/send_otp', data: {'phone': phone, 'name': name});
      await _storage.write(key: 'pending_phone', value: phone);
      await _storage.write(key: 'pending_name', value: name);
      state = AuthState(isLoading: false);
    } catch (e) {
      state = AuthState(error: 'Failed to send OTP. Check your network.');
    }
  }

  Future<bool> verifyOtp({required String phone, required String otp}) async {
    state = AuthState(isLoading: true);
    try {
      final res = await _api.post('/verify_otp', data: {'phone': phone, 'otp': otp});
      final token = res['token'] as String? ?? 'token_${DateTime.now().millisecondsSinceEpoch}';
      await _storage.write(key: 'auth_token', value: token);
      await _storage.write(key: 'phone', value: phone);
      final name = await _storage.read(key: 'pending_name');
      if (name != null) await _storage.write(key: 'user_name', value: name);
      state = AuthState(
        isLoggedIn: true,
        user: AppUser(phone: phone, name: name, token: token),
      );
      return true;
    } catch (e) {
      state = AuthState(error: 'Wrong code. Please try again.');
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
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(FlutterSecureStorage(), FarmSmartApiClient());
});
