import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    for (final action in toProcess) {
      try {
        switch (action.type) {
          case SyncActionType.updateTask:
          case SyncActionType.saveScan:
          case SyncActionType.updateSettings:
            break;
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
