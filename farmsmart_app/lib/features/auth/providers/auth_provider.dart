import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/api_client.dart';

class AppUser {
  final String phone;
  final String? name;
  final String? token;
  final bool hasPin;
  const AppUser({required this.phone, this.name, this.token, this.hasPin = false});
}

class AuthState {
  final bool isLoading;
  final AppUser? user;
  final String? error;
  final bool isLoggedIn;
  final String? devOtpCode;        // dev-only: shown in OTP screen so the developer doesn't have to read the SMS

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
    bool clearError = false,
    bool clearDevOtp = false,
  }) =>
      AuthState(
        isLoading: isLoading ?? this.isLoading,
        user: user ?? this.user,
        error: clearError ? null : (error ?? this.error),
        isLoggedIn: isLoggedIn ?? this.isLoggedIn,
        devOtpCode: clearDevOtp ? null : (devOtpCode ?? this.devOtpCode),
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FlutterSecureStorage _storage;
  final FarmSmartApiClient _api;
  AuthNotifier(this._storage, this._api) : super(const AuthState());

  Future<bool> checkSession() async {
    final phone = await _storage.read(key: 'phone');
    final token = await _storage.read(key: 'auth_token');
    if (phone != null && token != null) {
      state = AuthState(isLoggedIn: true, user: AppUser(phone: phone, token: token, hasPin: true));
      return true;
    }
    return false;
  }

  Future<void> sendOtp({required String phone, required String name}) async {
    state = state.copyWith(isLoading: true, clearError: true, clearDevOtp: true);
    try {
      final data = await _api.post('/api/auth/send-otp', data: {'phone': phone});
      await _storage.write(key: 'pending_phone', value: phone);
      await _storage.write(key: 'pending_name', value: name);
      state = state.copyWith(
        isLoading: false,
        devOtpCode: data is Map ? data['dev_code'] as String? : null,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to send OTP. Check your network.');
    }
  }

  Future<bool> verifyOtp({required String phone, required String otp}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final data = await _api.post('/api/auth/verify-otp', data: {'phone': phone, 'otp': otp}) as Map;
      final token = data['token'] as String;
      final hasPin = data['has_pin'] == true;
      final isNew = data['is_new_user'] == true;
      await _storage.write(key: 'auth_token', value: token);
      await _storage.write(key: 'phone', value: phone);
      final name = await _storage.read(key: 'pending_name');
      if (name != null) await _storage.write(key: 'user_name', value: name);
      state = state.copyWith(
        isLoading: false,
        isLoggedIn: true,
        user: AppUser(phone: phone, name: name, token: token, hasPin: hasPin),
      );
      return isNew || !hasPin;  // true = needs PIN setup next
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Wrong code. Please try again.');
      return false;
    }
  }

  /// Set (or change) the 4-digit PIN. Requires the user to be signed in.
  Future<bool> setPin(String pin) async {
    final phone = await _storage.read(key: 'phone');
    if (phone == null) return false;
    try {
      await _api.post('/api/auth/set-pin', data: {'phone': phone, 'pin': pin});
      final current = state.user;
      if (current != null) {
        state = state.copyWith(user: AppUser(phone: current.phone, name: current.name, token: current.token, hasPin: true));
      }
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    }
  }

  /// Sign in with phone + PIN. Stores the returned token.
  Future<bool> loginWithPin({required String phone, required String pin}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final data = await _api.post('/api/auth/login-pin', data: {'phone': phone, 'pin': pin}) as Map;
      final token = data['token'] as String;
      await _storage.write(key: 'auth_token', value: token);
      await _storage.write(key: 'phone', value: phone);
      state = state.copyWith(
        isLoading: false,
        isLoggedIn: true,
        user: AppUser(phone: phone, token: token, hasPin: true),
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Wrong PIN. Please try again.');
      return false;
    }
  }

  Future<bool> hasCompletedOnboarding() async {
    return await _storage.read(key: 'onboarding_complete') == 'true';
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(FlutterSecureStorage(), ref.read(apiClientProvider));
});

final apiClientProvider = Provider<FarmSmartApiClient>((ref) {
  return FarmSmartApiClient();
});
