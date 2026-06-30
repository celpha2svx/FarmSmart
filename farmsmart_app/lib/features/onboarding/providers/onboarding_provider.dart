import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/core_providers.dart';

class OnboardingState {
  final bool isLoading;
  final bool isComplete;
  final String? error;
  const OnboardingState({this.isLoading = false, this.isComplete = false, this.error});
}

class PlantingSelection {
  final String crop;
  final String plantingDate;     // ISO 'YYYY-MM-DD'
  const PlantingSelection({required this.crop, required this.plantingDate});
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final FlutterSecureStorage _storage;
  final FarmSmartApiClient _api;
  OnboardingNotifier(this._storage, this._api) : super(const OnboardingState());

  /// Persist a completed onboarding to the backend and to local secure
  /// storage. The backend stores the canonical record; the storage caches
  /// it for the home screen to render on cold start.
  Future<void> complete({
    required List<PlantingSelection> plantings,
    required String lga,
    required String lgaDisplayName,
    required double lat,
    required double lon,
    required String farmSize,
  }) async {
    state = const OnboardingState(isLoading: true);
    try {
      final phone = await _storage.read(key: 'phone') ?? '';
      final crops = plantings.map((p) => p.crop.toLowerCase()).toList();
      await _api.post('/api/farm/register', data: {
        'phone': phone,
        'crops': crops,
        'primary_crop': crops.first,
        'location_raw': lgaDisplayName,
        'lat': lat,
        'lon': lon,
        'farm_size': farmSize,
        'planting_date': plantings.first.plantingDate,
      });
      // Persist to secure storage for offline / fast cache
      await _storage.write(key: 'onboarding_complete', value: 'true');
      await _storage.write(key: 'farm_crops', value: crops.join(','));
      await _storage.write(key: 'farm_lga', value: lga);
      await _storage.write(key: 'farm_lga_display', value: lgaDisplayName);
      await _storage.write(key: 'farm_lat', value: lat.toString());
      await _storage.write(key: 'farm_lon', value: lon.toString());
      await _storage.write(key: 'farm_size', value: farmSize);
      // Per-crop planting dates: stored as JSON {crop: date}
      final plantingMap = {for (final p in plantings) p.crop: p.plantingDate};
      await _storage.write(key: 'farm_planting_dates', value: _encodeMap(plantingMap));
      await _storage.write(key: 'farm_planting_date', value: plantings.first.plantingDate);
      state = const OnboardingState(isComplete: true);
    } on ApiException catch (e) {
      state = OnboardingState(error: e.message);
    } catch (e) {
      state = OnboardingState(error: 'Failed to save farm. Check your network.');
    }
  }

  Future<bool> hasCompleted() async {
    return await _storage.read(key: 'onboarding_complete') == 'true';
  }
}

String _encodeMap(Map<String, String> m) =>
    m.entries.map((e) => '${e.key}=${e.value}').join(';');

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier(FlutterSecureStorage(), ref.read(apiClientProvider));
});
