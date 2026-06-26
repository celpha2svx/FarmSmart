import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmsmart_app/core/network/api_client.dart';
import 'package:farmsmart_app/core/constants/api_constants.dart';

class Announcement {
  final String id;
  final String title;
  final String body;
  final String level; // 'info' | 'warning' | 'update'
  final String createdAt;

  Announcement({
    required this.id,
    required this.title,
    required this.body,
    this.level = 'info',
    required this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      level: json['level'] ?? 'info',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class AnnouncementsNotifier extends StateNotifier<List<Announcement>> {
  final FarmSmartApiClient _client;

  AnnouncementsNotifier(this._client) : super([]) {
    fetch();
  }

  Future<void> fetch() async {
    try {
      final resp = await _client.get('/api/announcements');
      final data = resp.data as Map;
      if (data['status'] == 'ok' && data['announcements'] != null) {
        final list = (data['announcements'] as List)
            .map((e) => Announcement.fromJson(e as Map<String, dynamic>))
            .toList();
        state = list;
      }
    } catch (_) {}
  }
}

final announcementsProvider = StateNotifierProvider<AnnouncementsNotifier, List<Announcement>>((ref) {
  return AnnouncementsNotifier(FarmSmartApiClient());
});
