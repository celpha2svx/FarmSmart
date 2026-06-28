import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class OnboardingState {
  final bool isLoading;
  final bool isComplete;
  final String? error;
  const OnboardingState({
    this.isLoading = false,
    this.isComplete = false,
    this.error,
  });
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
      final token = await _storage.read(key: 'auth_token') ?? '';
      final name = await _storage.read(key: 'user_name') ?? '';

      if (phone.isEmpty || token.isEmpty) {
        state = const OnboardingState(error: 'Session expired. Please sign in again.');
        return;
      }

      final coords = _cityCoords(lga);
      final lat = coords[0];
      final lon = coords[1];
      final primaryCrop = crops.first.trim().toLowerCase();

      await _api.post('/api/farm/register', data: {
        'phone': phone,
        'token': token,
        'crop': primaryCrop,
        'location_raw': lga,
        'lat': lat,
        'lon': lon,
        'farm_size': farmSize,
        'name': name,
      });

      await _storage.write(key: 'onboarding_complete', value: 'true');
      await _storage.write(key: 'farm_crops', value: crops.join(','));
      await _storage.write(key: 'farm_lga', value: lga);
      await _storage.write(key: 'farm_size', value: farmSize);
      await _storage.write(key: 'farm_lat', value: lat.toString());
      await _storage.write(key: 'farm_lon', value: lon.toString());

      state = const OnboardingState(isComplete: true);
    } on DioException catch (e) {
      final detail = (e.response?.data as Map?)?['detail'] as String?;
      state = OnboardingState(error: detail ?? 'Failed to save farm. Check your network.');
    } catch (_) {
      state = const OnboardingState(error: 'Failed to save farm. Please try again.');
    }
  }

  Future<bool> hasCompleted() async {
    return await _storage.read(key: 'onboarding_complete') == 'true';
  }

  List<double> _cityCoords(String cityName) {
    final key = cityName.toLowerCase().trim();
    for (final entry in _ngCities.entries) {
      if (key.contains(entry.key) || entry.key.contains(key)) {
        return entry.value;
      }
    }
    return [9.0579, 7.4951];
  }

  static const Map<String, List<double>> _ngCities = {
    'abuja': [9.0579, 7.4951],
    'fct': [9.0579, 7.4951],
    'lagos': [6.5244, 3.3792],
    'ikeja': [6.6018, 3.3515],
    'kano': [12.0022, 8.5920],
    'ibadan': [7.3775, 3.9470],
    'kaduna': [10.5105, 7.4165],
    'zaria': [11.0780, 7.7020],
    'jos': [9.8965, 8.8583],
    'enugu': [6.4483, 7.5137],
    'port harcourt': [4.8156, 7.0498],
    'ph': [4.8156, 7.0498],
    'benin': [6.3350, 5.6037],
    'onitsha': [6.1667, 6.7833],
    'maiduguri': [11.8333, 13.1500],
    'aba': [5.1066, 7.3667],
    'sokoto': [13.0059, 5.2476],
    'oyo': [7.8500, 3.9333],
    'abeokuta': [7.1475, 3.3619],
    'ilorin': [8.4966, 4.5426],
    'makurdi': [7.7309, 8.5227],
    'yola': [9.2035, 12.4954],
    'jalingo': [8.8906, 11.3735],
    'gombe': [10.2791, 11.1671],
    'bauchi': [10.3158, 9.8442],
    'katsina': [12.9889, 7.6006],
    'dutse': [11.7656, 9.3416],
    'birnin kebbi': [12.4539, 4.1975],
    'gusau': [12.1703, 6.6639],
    'zamfara': [12.1703, 6.6639],
    'minna': [9.6139, 6.5569],
    'awka': [6.2099, 7.0699],
    'asaba': [6.1956, 6.7322],
    'owerri': [5.4836, 7.0333],
    'umuahia': [5.5320, 7.4860],
    'calabar': [4.9517, 8.3220],
    'uyo': [5.0377, 7.9128],
    'akure': [7.2526, 5.1939],
    'ado ekiti': [7.6244, 5.2216],
    'ado-ekiti': [7.6244, 5.2216],
    'osogbo': [7.7719, 4.5624],
    'ile ife': [7.4667, 4.5667],
  };
}

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier(const FlutterSecureStorage(), FarmSmartApiClient());
});
