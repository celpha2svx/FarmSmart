import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/api_client.dart';

class OnboardingState {
  final bool isLoading;
  final bool isComplete;
  final String? error;
  const OnboardingState({this.isLoading = false, this.isComplete = false, this.error});
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final FlutterSecureStorage _storage;
  final FarmSmartApiClient _api;
  OnboardingNotifier(this._storage, this._api) : super(const OnboardingState());

  Future<void> complete({
    required List<String> crops,
    required String lga,
    required String farmSize,
  }) async {
    state = const OnboardingState(isLoading: true);
    try {
      final phone = await _storage.read(key: 'phone') ?? '';
      await _api.post('/register_farm', data: {
        'phone': phone,
        'crops': crops.join(','),
        'location': lga,
        'farm_size': farmSize,
      });
      await _storage.write(key: 'onboarding_complete', value: 'true');
      await _storage.write(key: 'farm_crops', value: crops.join(','));
      await _storage.write(key: 'farm_lga', value: lga);
      await _storage.write(key: 'farm_size', value: farmSize);
      state = const OnboardingState(isComplete: true);
    } catch (e) {
      state = OnboardingState(error: 'Failed to save farm. Check your network.');
    }
  }

  Future<bool> hasCompleted() async {
    return await _storage.read(key: 'onboarding_complete') == 'true';
  }
}

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier(FlutterSecureStorage(), FarmSmartApiClient());
});
