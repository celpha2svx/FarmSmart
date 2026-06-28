import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/api_client.dart';

class WeatherData {
  final double? temperature;
  final double? humidity;
  final double? precipitation;
  final double? soilMoisture;
  final double? windSpeed;

  const WeatherData({
    this.temperature,
    this.humidity,
    this.precipitation,
    this.soilMoisture,
    this.windSpeed,
  });

  factory WeatherData.empty() => const WeatherData();
}

final weatherProvider = FutureProvider<WeatherData>((ref) async {
  const storage = FlutterSecureStorage();
  final latStr = await storage.read(key: 'farm_lat');
  final lonStr = await storage.read(key: 'farm_lon');

  final lat = double.tryParse(latStr ?? '') ?? 9.0579;
  final lon = double.tryParse(lonStr ?? '') ?? 7.4951;

  try {
    final api = FarmSmartApiClient();
    final res = await api.get('/api/weather', params: {
      'lat': lat.toString(),
      'lon': lon.toString(),
    });

    if (res['status'] == 'error') return WeatherData.empty();

    return WeatherData(
      temperature: (res['temperature'] as num?)?.toDouble(),
      humidity: (res['humidity'] as num?)?.toDouble(),
      precipitation: (res['precipitation'] as num?)?.toDouble(),
      windSpeed: (res['wind_speed'] as num?)?.toDouble(),
    );
  } catch (_) {
    return WeatherData.empty();
  }
});

final satelliteProvider = FutureProvider<Map<String, double?>>((ref) async {
  const storage = FlutterSecureStorage();
  final latStr = await storage.read(key: 'farm_lat');
  final lonStr = await storage.read(key: 'farm_lon');

  final lat = double.tryParse(latStr ?? '') ?? 9.0579;
  final lon = double.tryParse(lonStr ?? '') ?? 7.4951;

  try {
    final api = FarmSmartApiClient();
    final res = await api.get('/api/satellite', params: {
      'lat': lat.toString(),
      'lon': lon.toString(),
    });
    final data = res['data'] as Map<String, dynamic>? ?? {};
    return {
      'ndvi': (data['ndvi'] as num?)?.toDouble(),
      'soil_moisture': (data['soil_moisture'] as num?)?.toDouble(),
      'drought_index': (data['drought_index'] as num?)?.toDouble(),
    };
  } catch (_) {
    return {'ndvi': null, 'soil_moisture': null, 'drought_index': null};
  }
});
