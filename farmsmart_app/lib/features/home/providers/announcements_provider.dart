import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/providers/core_providers.dart';

class Announcement {
  final String id;
  final String title;
  final String body;
  final String level;
  final String createdAt;
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.level,
    required this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> j) => Announcement(
        id: (j['id'] as String?) ?? '',
        title: (j['title'] as String?) ?? '',
        body: (j['body'] as String?) ?? '',
        level: (j['level'] as String?) ?? 'info',
        createdAt: (j['created_at'] as String?) ?? '',
      );
}

final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  final storage = FlutterSecureStorage();
  final phone = await storage.read(key: 'phone') ?? '';
  final token = await storage.read(key: 'auth_token');
  final api = ref.read(apiClientProvider);
  try {
    final data = await api.get('/api/announcements', params: {
      if (phone.isNotEmpty) 'phone': phone,
      if (token != null) 'token': token,
    }) as Map;
    final list = (data['announcements'] as List<dynamic>?) ?? [];
    return list
        .map((a) => Announcement.fromJson(Map<String, dynamic>.from(a)))
        .toList();
  } catch (_) {
    return const [];
  }
});
