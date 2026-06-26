import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmsmart_app/data/datasources/remote/farmsmart_api_datasource.dart';
import 'package:farmsmart_app/domain/entities/farm.dart';
import 'package:farmsmart_app/presentation/providers/core_providers.dart';

// ── Farm State ──
class FarmState {
  final Farm? farm;
  final bool isLoading;
  final String? error;

  const FarmState({this.farm, this.isLoading = false, this.error});

  FarmState copyWith({Farm? farm, bool? isLoading, String? error}) {
    return FarmState(
      farm: farm ?? this.farm,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class FarmNotifier extends StateNotifier<FarmState> {
  FarmNotifier() : super(const FarmState());

  void setFarm(Farm farm) {
    state = FarmState(farm: farm);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String error) {
    state = state.copyWith(error: error, isLoading: false);
  }

  void clear() {
    state = const FarmState();
  }
}

final farmProvider = StateNotifierProvider<FarmNotifier, FarmState>((ref) {
  return FarmNotifier();
});

// ── Advisory State ──
class AdvisoryState {
  final String? soilMessage;
  final String? weatherMessage;
  final String? pestMessage;
  final bool isLoading;
  final String? error;

  const AdvisoryState({
    this.soilMessage,
    this.weatherMessage,
    this.pestMessage,
    this.isLoading = false,
    this.error,
  });

  AdvisoryState copyWith({
    String? soilMessage,
    String? weatherMessage,
    String? pestMessage,
    bool? isLoading,
    String? error,
  }) {
    return AdvisoryState(
      soilMessage: soilMessage ?? this.soilMessage,
      weatherMessage: weatherMessage ?? this.weatherMessage,
      pestMessage: pestMessage ?? this.pestMessage,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AdvisoryNotifier extends StateNotifier<AdvisoryState> {
  final FarmSmartApiDatasource _api;

  AdvisoryNotifier(this._api) : super(const AdvisoryState());

  Future<void> fetchAdvisories(Farm farm) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final soil = await _api.getSoilAdvisory(
        crop: farm.crop, lat: farm.lat, lon: farm.lon,
      );
      final weather = await _api.getWeatherAdvisory(
        crop: farm.crop, lat: farm.lat, lon: farm.lon,
      );
      final pest = await _api.getPestAdvisory(
        crop: farm.crop, lat: farm.lat, lon: farm.lon,
      );

      state = AdvisoryState(
        soilMessage: soil,
        weatherMessage: weather,
        pestMessage: pest,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to load advisories', isLoading: false);
    }
  }
}

final advisoryProvider = StateNotifierProvider<AdvisoryNotifier, AdvisoryState>((ref) {
  final api = ref.watch(farmsmartApiDatasourceProvider);
  return AdvisoryNotifier(api);
});
