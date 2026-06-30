import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/core_providers.dart';

class WeatherSnapshot {
  final double? tempMaxC;
  final double? tempMinC;
  final double? humidityPct;
  final double? rainfallMm24h;
  final String? condition;
  const WeatherSnapshot({
    this.tempMaxC, this.tempMinC, this.humidityPct, this.rainfallMm24h, this.condition,
  });
  static const empty = WeatherSnapshot();

  factory WeatherSnapshot.fromJson(Map<String, dynamic> j) => WeatherSnapshot(
        tempMaxC: (j['temp_max_c'] as num?)?.toDouble(),
        tempMinC: (j['temp_min_c'] as num?)?.toDouble(),
        humidityPct: (j['humidity_pct'] as num?)?.toDouble(),
        rainfallMm24h: (j['rainfall_mm_24h'] as num?)?.toDouble(),
        condition: j['condition'] as String?,
      );
}

class SoilSnapshot {
  final double? moisturePct;
  final double? temperatureC;
  const SoilSnapshot({this.moisturePct, this.temperatureC});
  static const empty = SoilSnapshot();
  factory SoilSnapshot.fromJson(Map<String, dynamic> j) => SoilSnapshot(
        moisturePct: (j['moisture_pct'] as num?)?.toDouble(),
        temperatureC: (j['temperature_c'] as num?)?.toDouble(),
      );
}

class AdvisoryData {
  final String id;
  final String crop;
  final String cropName;
  final String emoji;
  final String title;
  final String message;
  final String riskLevel;
  final List<String> actions;
  final List<String> warnings;
  final WeatherSnapshot weather;
  final SoilSnapshot soil;
  final double? ndvi;
  final String growthStageLabel;
  final int daysSincePlanting;
  final String generatedAt;
  const AdvisoryData({
    required this.id, required this.crop, required this.cropName, required this.emoji,
    required this.title, required this.message, required this.riskLevel,
    required this.actions, required this.warnings,
    required this.weather, required this.soil,
    required this.ndvi, required this.growthStageLabel, required this.daysSincePlanting,
    required this.generatedAt,
  });

  factory AdvisoryData.fromJson(Map<String, dynamic> j) {
    final gs = j['growth_stage'];
    String stageLabel = 'Vegetative';
    int days = 0;
    if (gs is Map) {
      stageLabel = (gs['stage_label'] as String?) ?? stageLabel;
      days = (gs['days_remaining'] as int?) ?? 0;
    }
    return AdvisoryData(
      id: (j['id'] as String?) ?? '',
      crop: (j['crop'] as String?) ?? '',
      cropName: (j['crop_name'] as String?) ?? '',
      emoji: (j['emoji'] as String?) ?? '🌱',
      title: (j['title'] as String?) ?? 'Farm Advisory',
      message: (j['message'] as String?) ?? 'No advisory available.',
      riskLevel: (j['risk_level'] as String?) ?? 'low',
      actions: (j['actions'] as List<dynamic>?)?.cast<String>() ?? const [],
      warnings: (j['warnings'] as List<dynamic>?)?.cast<String>() ?? const [],
      weather: j['weather'] is Map ? WeatherSnapshot.fromJson(j['weather']) : WeatherSnapshot.empty,
      soil: j['soil'] is Map ? SoilSnapshot.fromJson(j['soil']) : SoilSnapshot.empty,
      ndvi: (j['ndvi'] as num?)?.toDouble(),
      growthStageLabel: stageLabel,
      daysSincePlanting: days,
      generatedAt: (j['generated_at'] as String?) ?? '',
    );
  }
}

final advisoryProvider = FutureProvider<AdvisoryData>((ref) async {
  final storage = FlutterSecureStorage();
  final phone = await storage.read(key: 'phone') ?? '';
  final crop = await storage.read(key: 'farm_crops') ?? 'maize';
  final lat = double.tryParse(await storage.read(key: 'farm_lat') ?? '') ?? 9.0820;     // default: Nigeria centroid
  final lon = double.tryParse(await storage.read(key: 'farm_lon') ?? '') ?? 8.6753;
  final plantingDate = await storage.read(key: 'farm_planting_date');

  final api = ref.read(apiClientProvider);
  final data = await api.post('/api/advisory/generate', data: {
    'phone': phone,
    'crop': crop.split(',').first.trim().toLowerCase(),
    'lat': lat,
    'lon': lon,
    if (plantingDate != null) 'planting_date': plantingDate,
  }) as Map;

  final advisory = data['advisory'] as Map?;
  if (advisory == null) {
    throw const ApiException('not_found', 'No advisory returned');
  }
  return AdvisoryData.fromJson(Map<String, dynamic>.from(advisory));
});
