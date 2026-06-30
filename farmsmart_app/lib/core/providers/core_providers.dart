import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../network/api_client.dart';
import '../../features/auth/providers/auth_provider.dart' show apiClientProvider;

final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map((results) {
    return results.any((r) => r != ConnectivityResult.none);
  });
});

/// The farmer's last-saved farm snapshot from secure storage.
/// Server is the source of truth; this is a cached view for the home screen
/// to render immediately on app open without waiting for a network call.
final farmCacheProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final storage = FlutterSecureStorage();
  final phone = await storage.read(key: 'phone') ?? '';
  final cropsRaw = await storage.read(key: 'farm_crops') ?? 'maize';
  final crops = cropsRaw.split(',').map((s) => s.trim().toLowerCase()).where((s) => s.isNotEmpty).toList();
  final lga = await storage.read(key: 'farm_lga') ?? '';
  final lat = double.tryParse(await storage.read(key: 'farm_lat') ?? '');
  final lon = double.tryParse(await storage.read(key: 'farm_lon') ?? '');
  final farmSize = await storage.read(key: 'farm_size') ?? '';
  return {
    'phone': phone,
    'crops': crops,
    'primary_crop': crops.isNotEmpty ? crops.first : 'maize',
    'lga': lga,
    'lat': lat,
    'lon': lon,
    'size': farmSize,
  };
});
