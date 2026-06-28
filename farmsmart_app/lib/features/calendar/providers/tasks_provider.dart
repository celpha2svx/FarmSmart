import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/api_client.dart';

class FarmTask {
  final String id;
  final String title;
  final String type;
  final String? description;
  final int? daysAfterPlanting;
  final String region;
  final String season;
  final bool isCustom;

  const FarmTask({
    required this.id,
    required this.title,
    required this.type,
    this.description,
    this.daysAfterPlanting,
    this.region = 'all',
    this.season = 'all',
    this.isCustom = false,
  });
}

final tasksProvider = FutureProvider<List<FarmTask>>((ref) async {
  const storage = FlutterSecureStorage();
  final crop = await storage.read(key: 'farm_crops') ?? 'Maize';
  final lga = await storage.read(key: 'farm_lga') ?? '';

  final api = FarmSmartApiClient();
  final res = await api.get('/api/tasks', params: {
    'crop': crop.split(',').first.trim().toLowerCase(),
    'region': _inferRegion(lga),
    'season': _currentSeason(),
  });

  final tasksList = res['tasks'] as List<dynamic>? ?? [];
  return tasksList.map((t) {
    final m = t as Map<String, dynamic>;
    return FarmTask(
      id: m['id']?.toString() ?? '',
      title: m['title'] as String? ?? '',
      type: m['task_type'] as String? ?? 'general',
      description: m['description'] as String?,
      daysAfterPlanting: m['days_after_planting'] as int?,
      region: m['region'] as String? ?? 'all',
      season: m['season'] as String? ?? 'all',
    );
  }).where((t) => t.title.isNotEmpty).toList();
});

String _inferRegion(String lga) {
  final l = lga.toLowerCase();
  const north = ['kano', 'kaduna', 'zaria', 'katsina', 'sokoto', 'maiduguri', 'jos', 'bauchi'];
  const south = ['lagos', 'ibadan', 'benin', 'port harcourt', 'aba', 'onitsha', 'enugu', 'calabar'];
  if (north.any((n) => l.contains(n))) return 'north';
  if (south.any((s) => l.contains(s))) return 'south';
  return 'all';
}

String _currentSeason() {
  final month = DateTime.now().month;
  return (month >= 4 && month <= 10) ? 'wet' : 'dry';
}

class TaskCompletionNotifier extends StateNotifier<Set<String>> {
  final FarmSmartApiClient _api;
  final FlutterSecureStorage _storage;

  TaskCompletionNotifier(this._api, this._storage) : super({});

  Future<void> toggle(String taskId) async {
    final wasComplete = state.contains(taskId);
    if (wasComplete) {
      state = {...state}..remove(taskId);
    } else {
      state = {...state, taskId};
    }

    try {
      final phone = await _storage.read(key: 'phone') ?? '';
      final token = await _storage.read(key: 'auth_token') ?? '';
      if (phone.isEmpty || token.isEmpty) return;
      await _api.post('/api/tasks/sync', data: {
        'phone': phone,
        'token': token,
        'task_id': taskId,
        'done': !wasComplete,
      });
    } catch (_) {}
  }

  bool isComplete(String taskId) => state.contains(taskId);
}

final taskCompletionProvider = StateNotifierProvider<TaskCompletionNotifier, Set<String>>((ref) {
  return TaskCompletionNotifier(FarmSmartApiClient(), const FlutterSecureStorage());
});

class CustomTask {
  final String id;
  final String title;
  final String type;
  const CustomTask({required this.id, required this.title, required this.type});
}

class CustomTasksNotifier extends StateNotifier<List<CustomTask>> {
  CustomTasksNotifier() : super([]);

  void add(String title, String type) {
    final task = CustomTask(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      type: type,
    );
    state = [...state, task];
  }

  void remove(String id) {
    state = state.where((t) => t.id != id).toList();
  }
}

final customTasksProvider = StateNotifierProvider<CustomTasksNotifier, List<CustomTask>>((ref) {
  return CustomTasksNotifier();
});
