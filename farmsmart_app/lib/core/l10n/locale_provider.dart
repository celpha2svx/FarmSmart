import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'translations.dart';
import '../../features/settings/providers/settings_provider.dart';

final translationsProvider = Provider<Translations>((ref) {
  final settings = ref.watch(settingsProvider);
  return Translations(settings.locale);
});
