import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stub sync service for Phase 1.
///
/// Phase 5 will replace this with a real offline write-ahead queue
/// backed by the Drift database. For now `syncAll()` is a no-op that
/// exists only to keep the settings screen's "Sync Now" button alive
/// without showing a misleading "synced" state.
///
/// connectivityProvider is defined in core/providers/core_providers.dart
/// — use that to detect online/offline transitions.
class SyncService {
  const SyncService();
  Future<void> syncAll() async {}
  int get pendingCount => 0;
}

final syncServiceProvider = Provider<SyncService>((ref) => const SyncService());
