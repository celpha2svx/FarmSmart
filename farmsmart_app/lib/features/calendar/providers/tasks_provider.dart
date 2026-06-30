import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/core_providers.dart';

class FarmTask {
  final String id;
  final String templateId;
  final String title;
  final String type;
  final String? note;
  final String date;
  final bool completed;
  final bool custom;
  const FarmTask({
    required this.id,
    required this.templateId,
    required this.title,
    required this.type,
    this.note,
    required this.date,
    required this.completed,
    required this.custom,
  });

  FarmTask copyWith({bool? completed}) => FarmTask(
        id: id, templateId: templateId, title: title, type: type,
        note: note, date: date, completed: completed ?? this.completed, custom: custom,
      );

  factory FarmTask.fromJson(Map<String, dynamic> j) => FarmTask(
        id: (j['id'] as String?) ?? '',
        templateId: (j['template_id'] as String?) ?? '',
        title: (j['title'] as String?) ?? '',
        type: (j['type'] as String?) ?? 'other',
        note: j['note'] as String?,
        date: (j['due_date'] as String?) ?? '',
        completed: j['completed'] == true,
        custom: j['custom'] == true,
      );
}

class TasksForDay {
  final String date;
  final String crop;
  final List<FarmTask> tasks;
  const TasksForDay({required this.date, required this.crop, required this.tasks});
}

/// Per-day task list. Family-keyed by (date, crop) so the calendar can
/// cache one list per day per crop.
final tasksProvider = FutureProvider.family<TasksForDay, ({String date, String crop})>((ref, key) async {
  final storage = FlutterSecureStorage();
  final phone = await storage.read(key: 'phone') ?? '';
  final lat = double.tryParse(await storage.read(key: 'farm_lat') ?? '');
  final lon = double.tryParse(await storage.read(key: 'farm_lon') ?? '');
  final plantingDate = await storage.read(key: 'farm_planting_date');

  final api = ref.read(apiClientProvider);
  final params = <String, dynamic>{
    'phone': phone,
    'crop': key.crop.toLowerCase(),
    'date': key.date,
    if (lat != null) 'lat': lat,
    if (lon != null) 'lon': lon,
    if (plantingDate != null) 'planting_date': plantingDate,
  };
  final data = await api.get('/api/tasks', params: params) as Map;
  final list = (data['tasks'] as List<dynamic>?)
          ?.map((t) => FarmTask.fromJson(Map<String, dynamic>.from(t)))
          .toList() ??
      const [];
  return TasksForDay(date: key.date, crop: key.crop, tasks: list);
});

/// Mark a task complete / incomplete. Optimistically updates the cached
/// task list, then calls the backend. If the backend call fails we
/// re-throw and the caller can roll back.
class TasksSyncNotifier extends StateNotifier<bool> {
  final FarmSmartApiClient _api;
  TasksSyncNotifier(this._api) : super(false);

  Future<void> sync({
    required String phone,
    required String taskId,
    required bool completed,
    String? crop,
    String? dueDate,
  }) async {
    state = true;
    try {
      await _api.post('/api/tasks/sync', data: {
        'phone': phone,
        'task_id': taskId,
        'completed': completed,
        if (crop != null) 'crop': crop,
        if (dueDate != null) 'due_date': dueDate,
      });
    } finally {
      state = false;
    }
  }
}

final tasksSyncProvider = StateNotifierProvider<TasksSyncNotifier, bool>((ref) {
  return TasksSyncNotifier(ref.read(apiClientProvider));
});
