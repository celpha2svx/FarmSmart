import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class Announcement {
  final String id;
  final String title;
  final String body;
  final String level;
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.level,
  });
}

final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  final api = FarmSmartApiClient();
  final res = await api.get('/api/announcements');
  final list = res['announcements'] as List<dynamic>? ?? [];
  return list.map((a) {
    final m = a as Map<String, dynamic>;
    return Announcement(
      id: m['id']?.toString() ?? '',
      title: m['title'] as String? ?? '',
      body: m['body'] as String? ?? '',
      level: m['level'] as String? ?? 'info',
    );
  }).where((a) => a.title.isNotEmpty).toList();
});
