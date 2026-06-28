import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../network/api_client.dart';

final apiClientProvider = Provider<FarmSmartApiClient>((ref) {
  return FarmSmartApiClient();
});

final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map((results) {
    return results.any((r) => r != ConnectivityResult.none);
  });
});

final farmProvider = Provider<Map<String, dynamic>>((ref) {
  // In production: fetch from backend or local DB
  return {
    'id': 'farm_001',
    'crop': 'maize',
    'lat': 11.078,
    'lon': 7.702,
    'lga': 'Zaria, Kaduna',
    'size': 'medium',
    'plantingDate': '2026-05-15',
  };
});
