import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmsmart_app/core/network/api_client.dart';
import 'package:farmsmart_app/data/datasources/remote/farmsmart_api_datasource.dart';
import 'package:farmsmart_app/data/datasources/remote/fao_api_datasource.dart';
import 'package:farmsmart_app/data/datasources/local/local_datasource.dart';

// ── Core Providers ──
final farmsmartApiClientProvider = Provider<FarmSmartApiClient>((ref) {
  return FarmSmartApiClient();
});

final faoApiClientProvider = Provider<FaoApiClient>((ref) {
  return FaoApiClient();
});

final farmsmartApiDatasourceProvider = Provider<FarmSmartApiDatasource>((ref) {
  return FarmSmartApiDatasource(ref.watch(farmsmartApiClientProvider));
});

final faoApiDatasourceProvider = Provider<FaoApiDatasource>((ref) {
  return FaoApiDatasource(ref.watch(faoApiClientProvider));
});

// ── Database ──
// Note: Drift database needs to be initialized async
final databaseProvider = FutureProvider<FarmSmartDatabase>((ref) async {
  return FarmSmartDatabase();
});

final localDatasourceProvider = FutureProvider<LocalDatasource>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return LocalDatasource(db);
});

// ── Onboarding state ──
class OnboardingNotifier extends StateNotifier<bool> {
  OnboardingNotifier() : super(false);

  void complete() => state = true;
}

final onboardingCompleteProvider = StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  return OnboardingNotifier();
});
