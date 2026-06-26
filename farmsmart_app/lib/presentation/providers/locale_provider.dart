import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:farmsmart_app/core/constants/api_constants.dart';

final _secureStorage = const FlutterSecureStorage();

final localeProvider = StateNotifierProvider<LocaleNotifier, String>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<String> {
  LocaleNotifier() : super('en') {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final saved = await _secureStorage.read(key: StorageConstants.localeKey);
    if (saved != null && ['en', 'ha', 'yo', 'ig'].contains(saved)) {
      state = saved;
    }
  }

  Future<void> setLocale(String code) async {
    state = code;
    await _secureStorage.write(key: StorageConstants.localeKey, value: code);
  }
}


