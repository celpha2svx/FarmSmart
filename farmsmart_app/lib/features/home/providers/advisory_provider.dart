import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/api_client.dart';

class AdvisoryData {
  final String title;
  final String message;
  final String riskLevel;
  final List<String> tips;
  final List<String> warnings;
  final List<Map<String, String>> actionItems;

  const AdvisoryData({
    required this.title,
    required this.message,
    required this.riskLevel,
    required this.tips,
    required this.warnings,
    required this.actionItems,
  });

  factory AdvisoryData.fallback() => const AdvisoryData(
        title: 'Advisory Unavailable',
        message: 'Could not load advisory. Check your connection and try again.',
        riskLevel: 'low',
        tips: [],
        warnings: [],
        actionItems: [],
      );
}

final advisoryProvider = FutureProvider<AdvisoryData>((ref) async {
  const storage = FlutterSecureStorage();
  final phone = await storage.read(key: 'phone') ?? '';
  final token = await storage.read(key: 'auth_token') ?? '';
  final crop = await storage.read(key: 'farm_crops') ?? 'Maize';
  final latStr = await storage.read(key: 'farm_lat');
  final lonStr = await storage.read(key: 'farm_lon');

  final lat = double.tryParse(latStr ?? '') ?? 9.0579;
  final lon = double.tryParse(lonStr ?? '') ?? 7.4951;

  if (phone.isEmpty || token.isEmpty) return AdvisoryData.fallback();

  final api = FarmSmartApiClient();
  final res = await api.post('/api/advisory/generate', data: {
    'phone': phone,
    'token': token,
    'crop': crop.split(',').first.trim().toLowerCase(),
    'days_since_planting': 30,
    'lat': lat,
    'lon': lon,
  });

  final advisory = res['advisory'] as Map<String, dynamic>? ?? {};

  final actionItems = (advisory['action_items'] as List<dynamic>? ?? [])
      .map((a) {
        if (a is Map<String, dynamic>) {
          return {'text': a['text']?.toString() ?? '', 'priority': a['priority']?.toString() ?? 'medium'};
        }
        return {'text': a.toString(), 'priority': 'medium'};
      })
      .where((a) => a['text']!.isNotEmpty)
      .toList();

  final tips = (advisory['tips'] as List<dynamic>? ?? [])
      .map((t) => t.toString())
      .where((t) => t.isNotEmpty)
      .toList();

  final warnings = (advisory['warnings'] as List<dynamic>? ?? [])
      .map((w) => w.toString())
      .where((w) => w.isNotEmpty)
      .toList();

  return AdvisoryData(
    title: advisory['title'] as String? ?? 'Today\'s Advisory',
    message: advisory['message'] as String? ?? '',
    riskLevel: warnings.isNotEmpty ? 'high' : (tips.length > 3 ? 'medium' : 'low'),
    tips: tips,
    warnings: warnings,
    actionItems: actionItems,
  );
});
