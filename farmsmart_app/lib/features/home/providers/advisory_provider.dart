import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/api_client.dart';

class AdvisoryData {
  final String title;
  final String message;
  final String riskLevel;
  final List<String> actions;
  const AdvisoryData({
    required this.title, required this.message,
    required this.riskLevel, required this.actions,
  });
}

final advisoryProvider = FutureProvider<AdvisoryData>((ref) async {
  final storage = FlutterSecureStorage();
  final phone = await storage.read(key: 'phone') ?? '';
  final crop = await storage.read(key: 'farm_crops') ?? 'Maize';
  final lga = await storage.read(key: 'farm_lga') ?? '';
  final api = FarmSmartApiClient();
  final res = await api.post('/advisory', data: {
    'phone': phone,
    'crop': crop.split(',').first,
    'location': lga,
  });
  return AdvisoryData(
    title: res['title'] as String? ?? 'Farm Advisory',
    message: res['message'] as String? ?? 'No advisory available.',
    riskLevel: res['risk_level'] as String? ?? 'Low',
    actions: (res['actions'] as List<dynamic>?)?.cast<String>() ?? [],
  );
});
