import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../network/api_client.dart';

final apiClientProvider = Provider<FarmSmartApiClient>((ref) {
  return FarmSmartApiClient();
});

final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map((results) {
    return results.any((r) => r != ConnectivityResult.none);
  });
});

final farmProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final storage = FlutterSecureStorage();
  final phone = await storage.read(key: 'phone') ?? '';
  final crop = await storage.read(key: 'farm_crops') ?? 'Maize';
  final lga = await storage.read(key: 'farm_lga') ?? '';
  final farmSize = await storage.read(key: 'farm_size') ?? '';
  return {
    'id': phone,
    'crop': crop.split(',').first,
    'lga': lga,
    'size': farmSize,
  };
});
