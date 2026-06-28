import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../network/api_client.dart';

enum SyncActionType { updateTask, saveScan, updateSettings }

class SyncAction {
  final SyncActionType type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  SyncAction({required this.type, required this.payload, DateTime? createdAt})
      : createdAt = createdAt ?? DateTime.now();
}

class SyncService {
  final Ref _ref;
  final List<SyncAction> _queue = [];
  final _api = FarmSmartApiClient();
  final _storage = const FlutterSecureStorage();

  SyncService(this._ref) {
    Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none) && _queue.isNotEmpty) {
        _processQueue();
      }
    });
  }

  void enqueue(SyncAction action) {
    _queue.add(action);
    Connectivity().checkConnectivity().then((results) {
      if (results.any((r) => r != ConnectivityResult.none)) _processQueue();
    });
  }

  Future<void> _processQueue() async {
    final toProcess = List<SyncAction>.from(_queue);
    final phone = await _storage.read(key: 'phone') ?? '';
    final token = await _storage.read(key: 'auth_token') ?? '';
    if (phone.isEmpty || token.isEmpty) return;

    for (final action in toProcess) {
      try {
        switch (action.type) {
          case SyncActionType.updateTask:
            await _api.post('/api/tasks/sync', data: {
              'phone': phone,
              'token': token,
              ...action.payload,
            });
          case SyncActionType.saveScan:
            await _api.post('/api/analytics/event', data: {
              'phone': phone,
              'token': token,
              'event_type': 'pest_scan_offline',
              'event_data': action.payload,
            });
          case SyncActionType.updateSettings:
            await _api.post('/api/analytics/event', data: {
              'phone': phone,
              'token': token,
              'event_type': 'settings_update',
              'event_data': action.payload,
            });
        }
        _queue.remove(action);
      } catch (_) {
        break;
      }
    }
  }

  Future<void> syncAll() => _processQueue();
  int get pendingCount => _queue.length;
}

final syncServiceProvider = Provider<SyncService>((ref) => SyncService(ref));
