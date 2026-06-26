import 'package:farmsmart_app/core/constants/api_constants.dart';
import 'package:farmsmart_app/core/network/api_client.dart';
import 'package:farmsmart_app/domain/entities/farm.dart';

/// Communicates with the FarmSmart FastAPI backend.
class FarmSmartApiDatasource {
  final FarmSmartApiClient _client;

  FarmSmartApiDatasource(this._client);

  // ── Soil ──
  Future<String> getSoilAdvisory({
    required String crop,
    required double lat,
    required double lon,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.soilEndpoint,
        queryParams: {
          'crop': crop,
          'lat': lat.toString(),
          'lon': lon.toString(),
        },
      );
      return response.data?.toString() ?? 'Soil data unavailable';
    } catch (e) {
      return _fallbackSoilAdvisory(crop);
    }
  }

  // ── Weather ──
  Future<String> getWeatherAdvisory({
    required String crop,
    required double lat,
    required double lon,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.weatherEndpoint,
        queryParams: {
          'crop': crop,
          'lat': lat.toString(),
          'lon': lon.toString(),
        },
      );
      return response.data?.toString() ?? 'Weather data unavailable';
    } catch (e) {
      return _fallbackWeatherAdvisory();
    }
  }

  // ── Pest ──
  Future<String> getPestAdvisory({
    required String crop,
    required double lat,
    required double lon,
  }) async {
    try {
      final response = await _client.get(
        ApiConstants.pestEndpoint,
        queryParams: {
          'crop': crop,
          'lat': lat.toString(),
          'lon': lon.toString(),
        },
      );
      return response.data?.toString() ?? 'Pest data unavailable';
    } catch (e) {
      return 'Pest advisory currently unavailable. Scout your fields regularly.';
    }
  }

  // ── Register Farmer ──
  Future<Map<String, dynamic>> registerFarmer(Map<String, dynamic> data) async {
    final response = await _client.post('/sms_webhook', data: data);
    return response.data is Map ? response.data as Map<String, dynamic> : {};
  }

  // ── Fallbacks (offline) ──
  String _fallbackSoilAdvisory(String crop) {
    return 'Soil data unavailable offline. For $crop, check soil moisture manually — if dry 5cm deep, irrigate.';
  }

  String _fallbackWeatherAdvisory() {
    return 'Weather forecast unavailable offline. Observe sky conditions for local prediction.';
  }
}
