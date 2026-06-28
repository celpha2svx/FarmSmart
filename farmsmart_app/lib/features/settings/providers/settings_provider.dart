import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/sync/sync_service.dart';

class SettingsState {
  final String locale;
  final bool dailyAdvisory;
  final bool pestAlerts;
  final bool marketAlerts;
  final bool weatherAlerts;
  final bool autoSync;
  final double cacheSizeMb;
  final String appVersion;
  const SettingsState({
    this.locale = 'en',
    this.dailyAdvisory = true,
    this.pestAlerts = true,
    this.marketAlerts = false,
    this.weatherAlerts = true,
    this.autoSync = true,
    this.cacheSizeMb = 0,
    this.appVersion = '',
  });
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SyncService _syncService;
  SettingsNotifier(this._syncService) : super(const SettingsState());

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final info = await PackageInfo.fromPlatform();
    final version = '${info.version}+${info.buildNumber}';
    final prefsKeys = prefs.getKeys();
    double size = 0;
    for (final key in prefsKeys) {
      final val = prefs.get(key);
      if (val is String) size += val.length;
      if (val is int || val is double) size += 8;
      if (val is bool) size += 1;
    }
    state = SettingsState(
      locale: prefs.getString('locale') ?? 'en',
      dailyAdvisory: prefs.getBool('daily_advisory') ?? true,
      pestAlerts: prefs.getBool('pest_alerts') ?? true,
      marketAlerts: prefs.getBool('market_alerts') ?? false,
      weatherAlerts: prefs.getBool('weather_alerts') ?? true,
      autoSync: prefs.getBool('auto_sync') ?? true,
      cacheSizeMb: size / (1024 * 1024),
      appVersion: version,
    );
  }

  SettingsState _merged({String? locale, bool? dailyAdvisory, bool? pestAlerts, bool? marketAlerts, bool? weatherAlerts, bool? autoSync, double? cacheSizeMb}) {
    return SettingsState(
      locale: locale ?? state.locale,
      dailyAdvisory: dailyAdvisory ?? state.dailyAdvisory,
      pestAlerts: pestAlerts ?? state.pestAlerts,
      marketAlerts: marketAlerts ?? state.marketAlerts,
      weatherAlerts: weatherAlerts ?? state.weatherAlerts,
      autoSync: autoSync ?? state.autoSync,
      cacheSizeMb: cacheSizeMb ?? state.cacheSizeMb,
      appVersion: state.appVersion,
    );
  }

  Future<void> setLocale(String locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale);
    state = _merged(locale: locale);
  }

  Future<void> setDailyAdvisory(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_advisory', v);
    state = _merged(dailyAdvisory: v);
  }

  Future<void> setPestAlerts(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pest_alerts', v);
    state = _merged(pestAlerts: v);
  }

  Future<void> setMarketAlerts(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('market_alerts', v);
    state = _merged(marketAlerts: v);
  }

  Future<void> setWeatherAlerts(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('weather_alerts', v);
    state = _merged(weatherAlerts: v);
  }

  Future<void> setAutoSync(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_sync', v);
    state = _merged(autoSync: v);
  }

  Future<void> syncNow() async {
    state = _merged();
    await _syncService.syncAll();
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final locale = prefs.getString('locale');
    final token = prefs.getString('auth_token');
    final phone = prefs.getString('phone');
    final userName = prefs.getString('user_name');
    final onboarding = prefs.getString('onboarding_complete');
    final farmCrops = prefs.getString('farm_crops');
    final farmLga = prefs.getString('farm_lga');
    final farmSize = prefs.getString('farm_size');
    await prefs.clear();
    if (locale != null) await prefs.setString('locale', locale);
    if (token != null) await prefs.setString('auth_token', token);
    if (phone != null) await prefs.setString('phone', phone);
    if (userName != null) await prefs.setString('user_name', userName);
    if (onboarding != null) await prefs.setString('onboarding_complete', onboarding);
    if (farmCrops != null) await prefs.setString('farm_crops', farmCrops);
    if (farmLga != null) await prefs.setString('farm_lga', farmLga);
    if (farmSize != null) await prefs.setString('farm_size', farmSize);
    state = _merged(cacheSizeMb: 0);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return SettingsNotifier(syncService);
});
