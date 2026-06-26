import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map(
    (result) => !result.contains(ConnectivityResult.none),
  );
});

final isOfflineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).valueOrNull ?? false;
});
