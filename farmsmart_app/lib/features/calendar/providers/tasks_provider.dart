import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/api_client.dart';

class FarmTask {
  final String id;
  final String name;
  final String type;
  final String? note;
  final String date;
  final bool completed;
  const FarmTask({
    required this.id, required this.name, required this.type,
    this.note, required this.date, required this.completed,
  });
}

final tasksProvider = FutureProvider.family<List<FarmTask>, String>((ref, date) async {
  final storage = FlutterSecureStorage();
  final phone = await storage.read(key: 'phone') ?? '';
  final api = FarmSmartApiClient();
  final res = await api.post('/tasks', data: {'phone': phone, 'date': date});
  final tasksList = (res['tasks'] as List<dynamic>?) ?? [];
  return tasksList.map((t) {
    final tm = t as Map<String, dynamic>;
    return FarmTask(
      id: tm['id']?.toString() ?? '',
      name: tm['name'] as String? ?? '',
      type: tm['type'] as String? ?? '',
      note: tm['note'] as String?,
      date: tm['date'] as String? ?? date,
      completed: tm['completed'] == true,
    );
  }).toList();
});
