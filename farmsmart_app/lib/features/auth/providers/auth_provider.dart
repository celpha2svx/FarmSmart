import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  AuthNotifier(this._storage) : super(const AuthState());

  Future<bool> checkSession() async {
    final phone = await _storage.read(key: 'phone');
    final token = await _storage.read(key: 'auth_token');
    if (phone != null && token != null) {
      state = AuthState(isLoggedIn: true, user: AppUser(phone: phone, token: token));
      return true;
    }
    return false;
  }

  Future<void> sendOtp({required String phone, required String name}) async {
    state = AuthState(isLoading: true);
    try {
      // In real app, this calls API
      await _storage.write(key: 'pending_phone', value: phone);
      await _storage.write(key: 'pending_name', value: name);
      state = AuthState(isLoading: false);
    } catch (e) {
      state = AuthState(error: e.toString());
    }
  }

  Future<bool> verifyOtp({required String phone, required String otp}) async {
    state = AuthState(isLoading: true);
    try {
      // In real app, this calls verify API
      final token = 'demo_token_${DateTime.now().millisecondsSinceEpoch}';
      await _storage.write(key: 'auth_token', value: token);
      await _storage.write(key: 'phone', value: phone);
      final name = await _storage.read(key: 'pending_name');
      state = AuthState(
        isLoggedIn: true,
        user: AppUser(phone: phone, name: name, token: token),
      );
      return true;
    } catch (e) {
      state = AuthState(error: e.toString());
      return false;
    }
  }

  Future<bool> hasCompletedOnboarding() async {
    final val = await _storage.read(key: 'onboarding_complete');
    return val == 'true';
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(FlutterSecureStorage());
});
