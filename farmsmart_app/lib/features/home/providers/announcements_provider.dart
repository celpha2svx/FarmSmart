import 'package:flutter_riverpod/flutter_riverpod.dart';

class Announcement {
  final String id;
  final String title;
  final String body;
  final String level;
  const Announcement({required this.id, required this.title, required this.body, required this.level});
}

final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  return [];
});
