import 'package:flutter_riverpod/flutter_riverpod.dart';

class Announcement {
  final String id;
  final String title;
  final String body;
  final String level;
  const Announcement({required this.id, required this.title, required this.body, required this.level});
}

final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  // In production: call GET /api/announcements
  return [
    Announcement(id: '1', title: '🌧 Rain forecast', body: 'Heavy rain expected in Kaduna region. Ensure drainage.', level: 'warning'),
  ];
});
