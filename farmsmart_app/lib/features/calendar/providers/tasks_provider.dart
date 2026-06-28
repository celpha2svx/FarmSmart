import 'package:flutter_riverpod/flutter_riverpod.dart';

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

// Family provider keyed on date string (YYYY-MM-DD)
final tasksProvider = FutureProvider.family<List<FarmTask>, String>((ref, date) async {
  // In production: call GET /api/tasks
  return [
    FarmTask(id: '1', name: 'Irrigate maize field', type: 'water', note: '6:00 AM - 8:00 AM', date: date, completed: false),
    FarmTask(id: '2', name: 'Check for fall armyworm', type: 'pest', note: 'Scout whorl leaves', date: date, completed: true),
    FarmTask(id: '3', name: 'Apply NPK 15:15:15', type: 'fertilizer', note: '200kg/ha', date: date, completed: false),
  ];
});
